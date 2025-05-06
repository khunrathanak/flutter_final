import 'dart:ui';
import 'package:image/image.dart' as img;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:typed_data';
import '../utils/skincare_api_util.dart';

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
  XFile? picture;

  void initState() {
    super.initState();
    _requestCameraPermission().then((_) {
      _setUpCameraController();
    });
  }

  Future<void> _requestCameraPermission() async {
    const permission = Permission.camera;
    if (await permission.isDenied) {
      await permission.request();
      if (await permission.isDenied) {
        return;
      }
    }
  }

  Future<void> _setUpCameraController() async {
    List<CameraDescription> availableCamerasList =
        await availableCameras(); // Renamed the variable here
    if (availableCamerasList.isNotEmpty) {
      setState(() {
        cameras =
            availableCamerasList; // Assign the available cameras to the class variable
        cameraController =
            CameraController(cameras.last, ResolutionPreset.high);
      });

      cameraController?.initialize().then((_) {
        setState(() {});
      }).catchError((e) {
        // Handle the error (e.g., log it or show a message)
      });
    }
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        picture = pickedFile;
        isProcessing = true; // Start freeze
      });
      //TODO
      //CONVERT TO Uint8List
      final imageBytes = await pickedFile.readAsBytes();
      img.Image? image = img.decodeImage(Uint8List.fromList(imageBytes));

      if (image != null) {
        Uint8List jpegBytes = Uint8List.fromList(img.encodeJpg(image));
        //CALL API
        analyzeSkin(jpegBytes);
        setState(() {
          isProcessing = false; // End freeze
        });
      }
    } else {
      picture = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Camera"),
          backgroundColor: const Color(0xFFA87E62),
        ),
        body: Stack(children: [
          camera(),
          bottomButtons(),
        ]));
  }

  Positioned camera() {
    return Positioned.fill(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: 100,
          child: Stack(
            children: [
              if (cameraController != null &&
                  cameraController!.value.isInitialized)
                CameraPreview(cameraController!),
              if (isProcessing)
                Container(
                  color: Colors.white,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Positioned bottomButtons() {
    return Positioned(
      bottom: MediaQuery.of(context).size.height * 0.075,
      left: MediaQuery.of(context).size.width * 0.075,
      right: MediaQuery.of(context).size.width * 0.075,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white,
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
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            //Change camera
            IconButton(
              icon: const Icon(
                Icons.cameraswitch,
                color: Colors.black,
                size: 35,
              ),
              onPressed: () {
                //TODO _changeCamera();
              },
            ),
            IconButton(
              icon: const Icon(Icons.camera, color: Colors.black, size: 35),
              onPressed: () async {
                setState(() => isProcessing = true); // Start freeze
                XFile picture = await cameraController!.takePicture();

                await Future.delayed(
                    const Duration(milliseconds: 300)); // Freeze duration
                setState(() {
                  this.picture = picture;
                  isProcessing = false; // End freeze
                });

                // Convert the captured image to Uint8List
                final imageBytes = await picture.readAsBytes();
                img.Image? image =
                    img.decodeImage(Uint8List.fromList(imageBytes));

                if (image != null) {
                  //TODO
                  // Encode the image as JPEG
                  Uint8List jpegBytes =
                      Uint8List.fromList(img.encodeJpg(image));
                  // Call the API with the JPEG bytes
                  analyzeSkin(jpegBytes);
                }
              },
            ),

            //Image Picker
            IconButton(
              icon: const Icon(Icons.image, color: Colors.black, size: 35),
              onPressed: () async {
                await _pickImage();
                if (picture != null) {
                  //TODO
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
