import 'dart:io';
import 'dart:async';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:http_parser/http_parser.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image/image.dart' as img;
import 'dart:convert'; // Import for JSON decoding
import 'package:provider/provider.dart';
import '../models/product.dart'; // Assuming your Product model is here
import '../providers/product_provider.dart'; // Import your ProductProvider

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
  int selectedCameraIndex = 0; // To keep track of the selected camera
  XFile? picture;
  String _analysisResult = ''; // To store analysis result and recommendations
  // Removed unused _errorMessage

  // Add this at the class level to store the API response if needed elsewhere
  Map<String, dynamic>? apiResponseData;

  @override
  void initState() {
    super.initState();
    // Request permission first, then setup camera
    _requestCameraPermission().then((granted) {
      if (granted) {
        _setUpCameraController();
      } else {
        // Handle permission denial scenario (e.g., show a message)
         print("Camera permission denied");
         _showErrorDialog("Camera permission is required to use this feature.");
      }
    });
  }

  // Modified to return a boolean indicating if permission was granted
  Future<bool> _requestCameraPermission() async {
    const permission = Permission.camera;
    var status = await permission.status;
    if (status.isDenied || status.isPermanentlyDenied) {
      final result = await permission.request();
      return result.isGranted;
    }
    return status.isGranted;
  }

  Future<void> _setUpCameraController() async {
    try {
      List<CameraDescription> availableCamerasList = await availableCameras();
      if (availableCamerasList.isNotEmpty) {
        cameras = availableCamerasList;
        // Ensure selectedCameraIndex is valid
        selectedCameraIndex = selectedCameraIndex.clamp(0, cameras.length - 1);
        // Initialize with the selected camera
        await _initializeCamera(cameras[selectedCameraIndex]);
      } else {
        print("No cameras available");
        _showErrorDialog("No cameras found on this device.");
      }
    } catch (e) {
      print("Camera setup failed: $e");
      _showErrorDialog("Failed to set up camera: $e");
    }
  }

  // Helper function to initialize or switch camera
  Future<void> _initializeCamera(CameraDescription cameraDescription) async {
    // Dispose previous controller if exists
    await cameraController?.dispose();

    cameraController = CameraController(
      cameraDescription,
      ResolutionPreset.high,
      enableAudio: false, // Typically false for image capture
    );

    try {
      await cameraController?.initialize();
       if (mounted) { // Check if the widget is still in the tree
         setState(() {}); // Update UI after initialization
       }
    } on CameraException catch (e) {
      print("Camera initialization failed: ${e.code} ${e.description}");
      _showErrorDialog("Failed to initialize camera: ${e.description}");
      cameraController = null; // Set controller to null on failure
    } catch (e) {
      print("Camera initialization failed with general error: $e");
       _showErrorDialog("An unknown error occurred during camera initialization.");
       cameraController = null;
    }
  }

  // Function to switch camera
  Future<void> _switchCamera() async {
    if (cameras.length < 2) {
      print("Only one camera available, cannot switch.");
      return; // Not enough cameras to switch
    }
    // Cycle through cameras
    selectedCameraIndex = (selectedCameraIndex + 1) % cameras.length;
    await _initializeCamera(cameras[selectedCameraIndex]);
  }


  // Extracted validation logic
  Future<String?> _validateImage(File file, String filePath) async {
    try {
      final int fileSize = await file.length();
      // Check 1: File size ≤ 2MB
      if (fileSize > 2 * 1024 * 1024) {
        return "File too large (> 2MB)";
      }

      // Check 2: File type = jpg/jpeg
      final ext = filePath.split('.').last.toLowerCase();
      if (ext != 'jpg' && ext != 'jpeg') {
        return "File must be JPG or JPEG";
      }

      // Check 3: Image resolution (between 200x200 and 4096x4096)
      // Use image package for reliable decoding
      final Uint8List bytes = await file.readAsBytes();
      final decodedImage = img.decodeImage(bytes);
      if (decodedImage == null) {
        return "Could not decode image";
      }

      final width = decodedImage.width;
      final height = decodedImage.height;
      if (width < 200 || height < 200 || width > 4096 || height > 4096) {
        return "Image resolution must be between 200x200 and 4096x4096";
      }

      // All checks passed
      return null;
    } catch (e) {
      print("Validation error: $e");
      return "An error occurred during image validation.";
    }
  }


  Future<void> _pickImage() async {
    setState(() {
        isProcessing = true; // Start processing early
        picture = null; // Clear previous picture
        _analysisResult = ''; // Clear previous result
      });

    try {
      final XFile? pickedFile =
          await _picker.pickImage(source: ImageSource.gallery);

      if (pickedFile == null) {
         setState(() => isProcessing = false); // Stop if no file picked
         return;
      }

      final file = File(pickedFile.path);
      if (!await file.exists()) {
        print("❌ Picked file does not exist");
        _showErrorDialog("Selected file could not be found.");
         setState(() => isProcessing = false);
         return;
      }

      // Validate the image
      final validationError = await _validateImage(file, pickedFile.path);
       if (validationError != null) {
         print("❌ Validation failed: $validationError");
         _showErrorDialog(validationError);
         setState(() => isProcessing = false);
         return;
       }

      // If valid, update UI and proceed to upload
      setState(() {
        picture = pickedFile;
        // isProcessing remains true
      });

      // Short delay for UI update before potentially heavy upload
      await Future.delayed(const Duration(milliseconds: 100));

      // Pass context here
      final String responseBody = await uploadImage(file);
      // Pass context here too
      await _processApiResponse(context, responseBody);

    } catch (e) {
      print("Error picking/uploading image: $e");
      _showErrorDialog("Error processing image: $e");
       setState(() {
         picture = null; // Clear picture on error
         isProcessing = false;
       });
    }
    // No need for finally block to set isProcessing = false,
    // as it's handled in _processApiResponse or the catch block.
  }

  // Takes File, returns response body string on success, throws error on failure
  Future<String> uploadImage(File imageFile) async {
    // --- SECURITY WARNING ---
    // Hardcoding API keys is a major security risk.
    // Use environment variables or a secure configuration method in production.
    const apiKey = 'cmab99d2w0008ld046j6llklz'; // Replace with secure retrieval
    // ------------------------

    final uri = Uri.parse(
        'https://prod.api.market/api/v1/ailabtools/skin-analyze/portrait/analysis/skinanalyze');

    final request = http.MultipartRequest('POST', uri)
      ..headers.addAll({
        'accept': 'application/json',
        'x-magicapi-key': apiKey,
      })
      ..files.add(await http.MultipartFile.fromPath('image', imageFile.path,
          contentType: MediaType('image', 'jpeg'))); // Ensure correct content type

    try {
      print("Attempting to upload image...");
      final streamedResponse = await request.send().timeout(const Duration(seconds: 60)); // Add timeout
      final response = await http.Response.fromStream(streamedResponse);

      print("Upload response status: ${response.statusCode}");
      // print("Upload response body: ${response.body}"); // Be careful logging potentially large bodies

      if (response.statusCode >= 200 && response.statusCode < 300) { // Check for 2xx success codes
        print("Upload successful.");
        return response.body;
      } else {
         // Try to parse error message from response if available
        String errorMessage = "Upload failed with status: ${response.statusCode}.";
        try {
           final decoded = json.decode(response.body);
           if (decoded is Map && decoded.containsKey('message')) {
             errorMessage += " Message: ${decoded['message']}";
           } else {
             errorMessage += " Response: ${response.body}";
           }
         } catch (_) {
           // Ignore JSON decoding error, stick to status code
           errorMessage += " Could not parse error response body.";
         }
         print(errorMessage);
         throw Exception(errorMessage); // Throw exception for caller to handle
      }
    } on TimeoutException catch (_) {
       print("Upload failed: Request timed out.");
       throw Exception("Upload failed: The request timed out.");
    } catch (e) {
       print("Upload failed: $e");
       // Rethrow a more generic error or the original one
       throw Exception("Upload failed: $e");
    }
  }

  // Added function definition
 Future<List<Product>> _loadProductData(BuildContext context) async {
   // Use Provider to get the instance. listen: false is correct here.
   final productProvider = Provider.of<ProductProvider>(context, listen: false);

   try {
     // Access the products list directly.
     // The loading is initiated by the provider's constructor.
     // If the list is empty here, it might still be loading, or loading failed.
     // The compareResults function should handle an empty list gracefully.
     if (productProvider.products.isEmpty) {
       print("Product data is currently empty (may be loading or failed).");
       // You could potentially add a short delay and check again,
       // but often it's better to handle the empty list downstream.
       // DO NOT call loadProductsFromJson() here again.
     } else {
       print("Using available product data (${productProvider.products.length} items).");
     }
     // Return the current list (might be empty if loading hasn't finished/failed)
     return productProvider.products;
   } catch (e) {
     // This catch block might not be strictly necessary if you only access the getter,
     // but it's safe to keep.
     print("Error accessing product data from provider: $e");
     // _showErrorDialog is defined in _CameraPageState, so it can be called here.
     _showErrorDialog("Could not retrieve product recommendations data.");
     return []; // Return empty list on error
   }
 }




  // Process API response and update UI
  Future<void> _processApiResponse(BuildContext context, String responseBody) async {
    try {
      print("Processing API response...");
      apiResponseData = json.decode(responseBody); // Store raw data if needed

      if (apiResponseData == null || apiResponseData!['result'] == null || apiResponseData!['status'] != 'OK') {
         // Handle potential API errors indicated in the response body
         String apiMessage = apiResponseData?['message'] ?? 'Invalid API response structure or status not OK.';
         print("API Error: $apiMessage");
         throw Exception('API Error: $apiMessage');
      }

      // Extract results and compare
      Map<String, List<Product>> recommendedProducts =
          await compareResults(context, apiResponseData!); // Pass context

      String resultText = 'Analysis successful!\n\n';

      // Show detected concerns
      Map<String, dynamic> results = apiResponseData!['result'];
      List<String> detectedConcerns = [];
      results.forEach((key, value) {
        // Assuming '1' means detected, adjust if API uses different values (e.g., true, "DETECTED")
        if (value is Map && value['value'] == 1) {
          detectedConcerns.add(_formatConcernName(key));
        }
      });

      if (detectedConcerns.isNotEmpty) {
         resultText += 'Detected Skin Concerns:\n';
         for (var concern in detectedConcerns) {
           resultText += '- $concern\n';
         }
      } else {
         resultText += 'No specific skin concerns detected by the analysis.\n';
      }
      resultText += '\n';


      // Show recommended products
      if (recommendedProducts.isNotEmpty) {
        resultText += 'Recommended Products:\n';
        recommendedProducts.forEach((concern, products) {
          resultText += '\nFor ${_formatConcernName(concern)}:\n';
          if (products.isNotEmpty) {
             for (var product in products) {
              resultText += '  - ${product.name} (${product.brand})\n';
              resultText += '    Type: ${product.type}\n';
              // Format price, handle potential nulls if necessary
              resultText += '    Price: \$${product.price?.toStringAsFixed(2) ?? 'N/A'}\n';
              resultText += '    Benefits: ${_getProductBenefits(product)}\n';
              // Add compatibility check with current routine if needed (complex feature)
            }
          } else {
             resultText += '  - No specific products found for this concern in our database.\n';
          }
        });
      } else if (detectedConcerns.isNotEmpty) {
         // Only show this if concerns were detected but no products match
        resultText += 'No specific product recommendations available in our database for the detected concerns.';
      }

      setState(() {
        _analysisResult = resultText;
        isProcessing = false; // Processing finished
      });

    } catch (e) {
      print("Error processing API response: $e");
      _showErrorDialog("Error processing analysis results. Please try again. Details: $e");
      setState(() {
        isProcessing = false; // Ensure processing stops on error
      });
    }
  }

// --- Helper Functions ---

// Added basic implementation
String _formatConcernName(String apiKey) {
  if (apiKey.isEmpty) return "Unknown Concern";
  // Replace underscores, capitalize words
  return apiKey
      .split('_')
      .map((word) => word[0].toUpperCase() + word.substring(1))
      .join(' ');
}

// Added basic implementation
String _getProductBenefits(Product product) {
  List<String> benefits = [];
  if (product.brightening) benefits.add("Brightening");
  if (product.antiAging) benefits.add("Anti-Aging");
  if (product.acneFighting) benefits.add("Acne Fighting");
  if (product.sensitive) benefits.add("Good for Sensitive Skin");
  if (product.oily) benefits.add("Good for Oily Skin");
  if (product.comedogenic) benefits.add("May be Comedogenic"); // Note phrasing
  if (benefits.isEmpty) return "General Skincare";
  return benefits.join(', ');
}

// --- End Helper Functions ---


// Function to extract active concerns (value = 1)
Map<String, dynamic> _extractActiveConcerns(Map<String, dynamic> apiResponseData) {
  Map<String, dynamic> activeConcerns = {};
  if (apiResponseData['result'] != null && apiResponseData['result'] is Map) {
    (apiResponseData['result'] as Map<String, dynamic>).forEach((key, value) {
      if (value is Map && value['value'] == 1) {
        activeConcerns[key] = value; // Store the whole value map or just '1'
      }
    });
  }
  return activeConcerns;
}


// Update compareResults to use ProductProvider and handle context
Future<Map<String, List<Product>>> compareResults(
  BuildContext context, // Keep context for _loadProductData
  Map<String, dynamic> apiResponseData
) async {
  try {
    print("Comparing API results with product data...");
    // Step 1: Load product data using the provider via helper function
    List<Product> productData = await _loadProductData(context);
    if (productData.isEmpty) {
       print("Product data is empty, cannot compare.");
       return {}; // Return empty if no products loaded
    }

    // Step 2: Extract active concerns from API response
    Map<String, dynamic> activeConcerns = _extractActiveConcerns(apiResponseData);
    print("Active concerns detected: ${activeConcerns.keys.join(', ')}");


    // Step 3: Define how concerns map to product attributes
    // Ensure these attribute names match your Product model fields exactly
    final Map<String, List<String>> concernToProductAttributes = {
      'dark_circle': ['brightening', 'antiAging'],
      'blackhead': ['acneFighting', 'comedogenic'], // Consider refining this logic
      'acne': ['acneFighting', 'sensitive'],       // Consider refining this logic
      'pores_right_cheek': ['oily', 'comedogenic'], // Assuming large pores relate to oily/comedogenic
      'pores_left_cheek': ['oily', 'comedogenic'],  // Add mapping for left cheek too
      'pores_forehead': ['oily', 'comedogenic'],    // Add mapping for forehead too
      'eye_pouch': ['antiAging'],
      'nasolabial_fold': ['antiAging'],
      'forehead_wrinkle': ['antiAging'],
      'skin_spot': ['brightening'],
      // Add mappings for other potential concerns from the API if needed
    };

    // Step 4: Find matching products for each active concern
    Map<String, List<Product>> recommendedProducts = {};

    activeConcerns.forEach((concern, _) {
      List<String>? relevantAttributes = concernToProductAttributes[concern];

      if (relevantAttributes != null) {
        List<Product> matches = productData.where((product) {
          // Check if the product has *at least one* of the relevant attributes set to true
          return relevantAttributes.any((attr) {
            // Use a switch or if/else if chain to check boolean fields
            // Ensure these field names exactly match your Product model
            switch (attr) {
              case 'brightening': return product.brightening;
              case 'antiAging': return product.antiAging;
              case 'acneFighting': return product.acneFighting;
              // Handle comedogenic carefully - is it a benefit or a warning?
              // If it's a warning, you might want different logic (e.g., exclude if comedogenic is true)
              case 'comedogenic': return product.comedogenic; // Adjust logic if needed
              case 'sensitive': return product.sensitive;
              case 'oily': return product.oily;
              // Add cases for other attributes if needed
              default: return false;
            }
          });
        }).toList();

        // Store matches only if any were found
        if (matches.isNotEmpty) {
          recommendedProducts[concern] = matches;
           print("Found ${matches.length} products for concern: $concern");
        } else {
           print("No products found matching attributes for concern: $concern");
           // Optionally add the concern with an empty list if you want to signify 'checked but none found'
           // recommendedProducts[concern] = [];
        }
      } else {
         print("No attribute mapping defined for concern: $concern");
      }
    });

    print("Finished comparison. Recommended products map generated.");
    return recommendedProducts;
  } catch (e) {
    print('Error comparing results: $e');
    // Decide how to handle this - rethrow, return empty, show error?
    // Rethrowing allows the caller (_processApiResponse) to catch and show an error dialog.
    throw Exception('Failed to compare results: $e');
  }
}


  void _showErrorDialog(String message) {
    // Ensure dialog is shown only if context is available and widget is mounted
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } else {
       print("Dialog requested but widget not mounted. Error: $message");
    }
  }

  @override
  void dispose() {
    // Dispose camera controller when widget is removed
    cameraController?.dispose();
    print("CameraPage disposed, controller disposed.");
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Access provider once in build if needed for UI elements directly bound to it
    // final productProvider = Provider.of<ProductProvider>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Skin Analysis Camera"),
        backgroundColor: const Color(0xFFA87E62),
        elevation: 2,
      ),
      body: Stack(
        children: [
          // Camera preview or selected image display
          _buildCameraOrImageView(),

          // Control buttons at the bottom
          _buildControlButtons(),

          // Loading indicator overlay
          if (isProcessing)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.6), // Darker overlay
                child: const Center(
                  child: Column( // Add text for clarity
                     mainAxisSize: MainAxisSize.min,
                     children: [
                       CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                       ),
                       SizedBox(height: 16),
                       Text("Analyzing...", style: TextStyle(color: Colors.white, fontSize: 16)),
                     ],
                   ),
                ),
              ),
            ),

          // Analysis result dialog overlay
          // Use a more robust way to show results, maybe a bottom sheet or separate screen
          // This conditional build approach for a dialog isn't standard
          if (_analysisResult.isNotEmpty && !isProcessing) // Show only when not processing
            _buildResultDisplay(), // Renamed for clarity
        ],
      ),
    );
  }


  // Widget to display camera preview or the taken/selected image
  Widget _buildCameraOrImageView() {
     // If a picture has been taken/selected and we are NOT processing, show it.
    if (picture != null && !isProcessing) {
      // Use FutureBuilder to handle async file check gracefully
      return FutureBuilder<bool>(
        future: File(picture!.path).exists(), // Check if file still exists
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.data == true) {
              // File exists, display it
              return Positioned.fill(
                 child: Image.file(
                   File(picture!.path),
                   fit: BoxFit.contain, // Use contain to avoid distortion
                   errorBuilder: (context, error, stackTrace) {
                      return const Center(child: Text("Error loading image"));
                   },
                 ),
               );
            } else {
              // File doesn't exist (rare case, maybe deleted?)
               return const Center(child: Text("Image file not found"));
            }
          } else {
            // Still checking file existence
            return const Center(child: CircularProgressIndicator());
          }
        },
      );
    }
    // Otherwise, show camera preview if available and initialized
    else if (cameraController != null && cameraController!.value.isInitialized) {
        // Calculate aspect ratio for CameraPreview
        final cameraAspectRatio = cameraController!.value.aspectRatio;
         return Center( // Center the preview
           child: AspectRatio(
             aspectRatio: cameraAspectRatio,
             child: CameraPreview(cameraController!),
           ),
         );
      }
      // If camera isn't ready (still initializing or failed), show loading/error
      else {
         return const Center(
           child: Column(
             mainAxisAlignment: MainAxisAlignment.center,
             children: [
               CircularProgressIndicator(),
               SizedBox(height: 10),
               Text("Initializing Camera..."),
             ],
           )
         );
      }
  }


  // Widget for the control buttons row
  Widget _buildControlButtons() {
    return Positioned(
      bottom: MediaQuery.of(context).padding.bottom + 20, // Adjust for safe area + padding
      left: 20,
      right: 20,
      child: Opacity(
        opacity: isProcessing ? 0.5 : 1.0, // Dim buttons when processing
        child: AbsorbPointer(
          absorbing: isProcessing, // Disable buttons when processing
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9), // Slightly transparent white
              borderRadius: BorderRadius.circular(30), // Rounded corners
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween, // Space out buttons
              children: [
                // Gallery Picker Button
                IconButton(
                  icon: const Icon(Icons.image_outlined, color: Colors.black54, size: 30),
                  tooltip: "Pick from Gallery",
                  onPressed: _pickImage, // Use the refactored method
                ),

                // Camera Shutter Button
                IconButton(
                  icon: const Icon(Icons.camera_alt, color: Color(0xFFA87E62), size: 40),
                  tooltip: "Take Picture",
                  iconSize: 40, // Make shutter larger
                  onPressed: () async {
                    if (cameraController == null || !cameraController!.value.isInitialized) {
                      print("Camera not ready");
                      _showErrorDialog("Camera not ready. Please wait for initialization.");
                      return;
                    }
                    if (isProcessing) return; // Prevent action if already processing

                    setState(() {
                       isProcessing = true;
                       picture = null; // Clear previous picture
                       _analysisResult = ''; // Clear previous result
                    });


                    try {
                       XFile newPicture = await cameraController!.takePicture();
                       final file = File(newPicture.path);

                       // Validate the captured image
                       final validationError = await _validateImage(file, newPicture.path);
                       if (validationError != null) {
                          print("❌ Validation failed: $validationError");
                          _showErrorDialog(validationError);
                          setState(() => isProcessing = false);
                          return;
                       }

                       // Short delay for UI feedback might be good here if needed
                       // await Future.delayed(const Duration(milliseconds: 100));

                       setState(() {
                         picture = newPicture;
                         // isProcessing remains true
                       });
                       print("Picture taken: ${newPicture.path}");

                       // Pass context here
                       final String responseBody = await uploadImage(file);
                       // Pass context here too
                       await _processApiResponse(context, responseBody);

                    } catch (e) {
                       setState(() {
                         isProcessing = false; // Stop processing on error
                         picture = null; // Clear picture on error
                       });
                       print("Error taking/uploading picture: $e");
                       _showErrorDialog("Error taking picture: $e");
                    }
                  },
                ),

                // Camera Switch Button
                IconButton(
                  icon: const Icon(Icons.cameraswitch_outlined, color: Colors.black54, size: 30),
                  tooltip: "Switch Camera",
                  // Enable only if more than one camera exists
                  onPressed: (cameras.length > 1) ? _switchCamera : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


 // Builds the result display area (e.g., a dialog or bottom sheet)
 Widget _buildResultDisplay() {
   // Using an AlertDialog displayed conditionally via Stack isn't ideal.
   // A BottomSheet or a dedicated results area might be better UX.
   // However, fixing the existing AlertDialog approach:
   return Positioned.fill(
     child: Container(
       color: Colors.black.withOpacity(0.5), // Background overlay
       child: Center( // Center the dialog
         child: AlertDialog(
           title: const Text('Analysis Result'),
           content: SingleChildScrollView( // Make content scrollable
             child: Text(
               _analysisResult,
               style: const TextStyle(fontSize: 14), // Slightly smaller font
             ),
           ),
           actions: [
             TextButton(
               onPressed: () {
                 setState(() {
                   _analysisResult = ''; // Clear the result to hide the dialog
                   picture = null;       // Clear the picture as well
                   // Re-enable camera preview if it was showing image before
                 });
                 // DO NOT call Navigator.pop(context) here as it wasn't pushed separately
               },
               child: const Text('Close'),
             ),
           ],
           // Consider adding constraints to prevent dialog from being too large
           // shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
         ),
       ),
     ),
   );
 }

} // End _CameraPageState