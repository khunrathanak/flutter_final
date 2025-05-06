import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image/image.dart' as img; // Renamed to avoid conflict
import 'package:provider/provider.dart'; // Import Provider

import '../utils/skincare_api_util.dart'; // Your API utility
import '../providers/product_provider.dart'; // Your ProductProvider
import '../models/product.dart'; // Your Product model
// Import the RecommendationScreen
import '../screens/recomendation.dart'; // Adjust path if necessary

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  final ImagePicker _picker = ImagePicker();
  bool isProcessing = false;
  List<CameraDescription> cameras = [];
  CameraController? cameraController;
  XFile? picture; // To store the picked or taken picture

  @override
  void initState() {
    super.initState();
    _requestCameraPermission().then((_) {
      _setUpCameraController();
    });
  }

  Future<void> _requestCameraPermission() async {
    final cameraStatus = await Permission.camera.status;
    if (cameraStatus.isDenied || cameraStatus.isPermanentlyDenied) {
      final result = await Permission.camera.request();
      if (!result.isGranted) {
        print("Camera permission not granted.");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Camera permission is required to use the camera.")),
          );
        }
        return;
      }
    }
    final photoStatus = await Permission.photos.status;
     if (photoStatus.isDenied || photoStatus.isPermanentlyDenied) {
        final result = await Permission.photos.request();
        if (!result.isGranted) {
             print("Photo library permission not granted.");
            if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Photo library permission is required to pick images.")),
                );
            }
        }
    }
  }

  Future<void> _setUpCameraController() async {
    try {
      List<CameraDescription> availableCamerasList = await availableCameras();
      if (availableCamerasList.isNotEmpty) {
        setState(() {
          cameras = availableCamerasList;
          CameraDescription selectedCamera = cameras.firstWhere(
            (camera) => camera.lensDirection == CameraLensDirection.back,
            orElse: () => cameras.first,
          );
          cameraController = CameraController(
            selectedCamera,
            ResolutionPreset.high,
            enableAudio: false,
          );
        });

        await cameraController?.initialize();
        if (mounted) {
          setState(() {});
        }
      } else {
        print("No cameras available");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("No cameras available on this device.")),
          );
        }
      }
    } catch (e) {
      print("Error setting up camera controller: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error initializing camera: ${e.toString()}")),
        );
      }
    }
  }

  Future<void> _changeCamera() async {
    if (cameras.isEmpty || cameraController == null || cameras.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No other camera to switch to.")),
      );
      return;
    }

    setState(() { isProcessing = true; }); // Show a brief indicator during switch

    // Find the current camera index
    int currentCameraIndex = cameras.indexOf(cameraController!.description);
    int nextCameraIndex = (currentCameraIndex + 1) % cameras.length;
    CameraDescription newCamera = cameras[nextCameraIndex];

    await cameraController?.dispose(); // Dispose the old controller
    cameraController = CameraController( // Initialize a new one
      newCamera,
      ResolutionPreset.high,
      enableAudio: false,
    );

    try {
      await cameraController!.initialize();
    } catch (e) {
      print("Error switching camera: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error switching camera: ${e.toString()}")),
        );
      }
    } finally {
       if (mounted) {
        setState(() { isProcessing = false; }); // Hide indicator
      }
    }
  }

  Future<void> _processImageAndGetRecommendations(Uint8List imageBytes) async {
    if (!mounted) return;

    final Map<String, dynamic>? apiResultData = await analyzeSkin(imageBytes);

    if (!mounted) return;

    if (apiResultData != null) {
      final productProvider = Provider.of<ProductProvider>(context, listen: false);
      List<Product> recommendations = productProvider.getRecommendedProducts(apiResultData);

      print('--- Recommended Products (${recommendations.length}) ---');
      for (var product in recommendations) {
        print('  ${product.brand} - ${product.name}');
      }

      // Navigate to RecommendationScreen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RecommendationScreen(products: recommendations),
        ),
      );
      // Clear the picture after navigation so the camera preview is shown on pop
      setState(() {
        picture = null;
      });


    } else {
      print('Skin analysis failed or returned no result data.');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Skin analysis failed. Please try again.")),
        );
      }
    }
  }


  Future<void> _takePictureAndAnalyze() async {
    if (cameraController == null || !cameraController!.value.isInitialized) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Camera not ready. Please wait.")),
      );
      return;
    }
    if (!mounted) return;
    setState(() => isProcessing = true);
    XFile? takenPicture;
    try {
      takenPicture = await cameraController!.takePicture();
    } catch (e) {
      print("Error taking picture: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error taking picture: ${e.toString()}")),
        );
      }
       if (mounted) setState(() => isProcessing = false);
      return;
    }

    if (takenPicture == null) {
        if (mounted) setState(() => isProcessing = false);
         return;
    }
    if (mounted) {
      setState(() {
        picture = takenPicture;
      });
    }


    final imageBytes = await takenPicture.readAsBytes();
    img.Image? image = img.decodeImage(imageBytes);

    if (image != null) {
      Uint8List jpegBytes = Uint8List.fromList(img.encodeJpg(image));
      await _processImageAndGetRecommendations(jpegBytes);
    } else {
      print("Could not decode captured image.");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to process captured image.")),
        );
      }
    }
    if (mounted) {
      setState(() => isProcessing = false);
    }
  }

  Future<void> _pickImageFromGalleryAndAnalyze() async {
    if (!mounted) return;
    setState(() => isProcessing = true);
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
       if (mounted) {
        setState(() {
          picture = pickedFile;
        });
      }

      final imageBytes = await pickedFile.readAsBytes();
      img.Image? image = img.decodeImage(imageBytes);

      if (image != null) {
        Uint8List jpegBytes = Uint8List.fromList(img.encodeJpg(image));
        await _processImageAndGetRecommendations(jpegBytes);
      } else {
        print("Could not decode image from gallery.");
         if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Failed to process image from gallery.")),
          );
        }
      }
    } else {
      print("Image picking cancelled.");
    }
    if (mounted) {
      setState(() => isProcessing = false);
    }
  }

  @override
  void dispose() {
    cameraController?.dispose();
    super.dispose();
  }

  Widget _buildImagePreview() {
    if (picture == null) {
      return const Center(child: Text("No image selected."));
    }
    // For XFile, we need to read bytes to display.
    // Using a FutureBuilder to handle the async read operation.
    return FutureBuilder<Uint8List>(
      // Use a key to ensure FutureBuilder rebuilds if picture XFile instance changes
      key: ValueKey(picture!.path),
      future: picture!.readAsBytes(),
      builder: (BuildContext context, AsyncSnapshot<Uint8List> snapshot) {
        if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
          return Image.memory(snapshot.data!, fit: BoxFit.cover);
        } else if (snapshot.error != null) {
          return const Center(child: Text('Error loading image'));
        } else {
          // Still loading bytes or picture is null
          return const Center(child: CircularProgressIndicator());
        }
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    // Determine the aspect ratio of the camera preview
    final cameraAspectRatio = cameraController != null && cameraController!.value.isInitialized
        ? cameraController!.value.aspectRatio
        : 16 / 9; // Default aspect ratio

    return Scaffold(
      appBar: AppBar(
        title: const Text("Skin Analysis"),
        titleTextStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        backgroundColor: const Color(0xFF2196F3),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: (picture != null && !isProcessing) // If a picture is taken/picked and not processing
                ? _buildImagePreview() // Show the taken/picked image
                : (cameraController != null && cameraController!.value.isInitialized)
                    ? AspectRatio( // Use AspectRatio to maintain camera's aspect ratio
                        aspectRatio: cameraAspectRatio,
                        child: CameraPreview(cameraController!),
                      )
                    : Center( // Fallback if camera is not initialized
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const CircularProgressIndicator(),
                            const SizedBox(height: 10),
                            const Text("Initializing Camera..."),
                            if (cameras.isEmpty)
                              const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Text("No cameras detected.", style: TextStyle(color: Colors.red)),
                              )
                          ],
                        ),
                      ),
          ),
          if (isProcessing)
            Container(
              color: Colors.black.withOpacity(0.7),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 20),
                    Text(
                      "Analyzing your skin...",
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ],
                ),
              ),
            ),
          Align(
            alignment: Alignment.topCenter,
            child: Container(
              margin: const EdgeInsets.only(top: 20.0, left: 16, right: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Take a picture of your face or upload one from your gallery for skin analysis.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          bottomButtons(),
        ],
      ),
    );
  }

  Widget bottomButtons() {
    return Positioned(
      bottom: MediaQuery.of(context).size.height * 0.05,
      left: MediaQuery.of(context).size.width * 0.075,
      right: MediaQuery.of(context).size.width * 0.075,
      child: Opacity(
        opacity: isProcessing ? 0.5 : 1.0,
        child: AbsorbPointer(
          absorbing: isProcessing,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(50),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.5),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: const Icon(Icons.cameraswitch, color: Colors.black, size: 30),
                  tooltip: "Switch Camera",
                  onPressed: isProcessing ? null : _changeCamera,
                ),
                IconButton(
                  icon: const Icon(Icons.camera_alt, color: Colors.blue, size: 35),
                  tooltip: "Take Picture",
                  onPressed: isProcessing ? null : _takePictureAndAnalyze,
                ),
                IconButton(
                  icon: const Icon(Icons.photo_library, color: Colors.black, size: 30),
                  tooltip: "Pick from Gallery",
                  onPressed: isProcessing ? null : _pickImageFromGalleryAndAnalyze,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}