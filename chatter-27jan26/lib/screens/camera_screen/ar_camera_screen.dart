import 'dart:async';
import 'dart:math' as math;
import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:lumosocial/common/extensions/font_extension.dart';
import 'package:lumosocial/utilities/const.dart';

class ArCameraScreen extends StatefulWidget {
  final Function(String filePath) onMediaCaptured;
  const ArCameraScreen({Key? key, required this.onMediaCaptured}) : super(key: key);

  @override
  State<ArCameraScreen> createState() => _ArCameraScreenState();
}

class _ArCameraScreenState extends State<ArCameraScreen> {
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableLandmarks: true,
      enableClassification: false,
      performanceMode: FaceDetectorMode.fast,
    ),
  );

  List<Face> _faces = [];
  bool _isProcessing = false;
  
  // 0: None, 1: Cool Sunglasses, 2: Cute Dog Ears, 3: Funny Mustache, 4: Neon Cyber Mask
  int _selectedFilterIndex = 0;

  final List<Map<String, dynamic>> _filters = [
    {"name": "Original", "icon": Icons.camera_alt_rounded},
    {"name": "Cool Shades", "icon": Icons.dark_mode_rounded},
    {"name": "Dog Ears", "icon": Icons.pets_rounded},
    {"name": "Mustache", "icon": Icons.face_retouching_natural_rounded},
    {"name": "Neon Cyber", "icon": Icons.blur_on_rounded},
  ];

  @override
  void dispose() {
    _faceDetector.close();
    super.dispose();
  }

  Future<void> _processImage(AnalysisImage img) async {
    if (_isProcessing || _selectedFilterIndex == 0) return;
    _isProcessing = true;

    try {
      final inputImage = _convertToInputImage(img);
      if (inputImage != null) {
        final faces = await _faceDetector.processImage(inputImage);
        if (mounted) {
          setState(() {
            _faces = faces;
          });
        }
      }
    } catch (e) {
      debugPrint("Face detection error: $e");
    } finally {
      _isProcessing = false;
    }
  }

  InputImage? _convertToInputImage(AnalysisImage image) {
    return image.when(
      nv21: (nv21Image) {
        return InputImage.fromBytes(
          bytes: nv21Image.bytes,
          metadata: InputImageMetadata(
            size: nv21Image.size,
            rotation: _rotationFromInput(nv21Image.rotation),
            format: InputImageFormat.nv21,
            bytesPerRow: nv21Image.planes.first.bytesPerRow,
          ),
        );
      },
      yuv420: (yuvImage) {
        return InputImage.fromBytes(
          bytes: yuvImage.planes.first.bytes,
          metadata: InputImageMetadata(
            size: yuvImage.size,
            rotation: _rotationFromInput(yuvImage.rotation),
            format: InputImageFormat.yuv420,
            bytesPerRow: yuvImage.planes.first.bytesPerRow,
          ),
        );
      },
      bgra8888: (bgraImage) {
        return InputImage.fromBytes(
          bytes: bgraImage.bytes,
          metadata: InputImageMetadata(
            size: bgraImage.size,
            rotation: _rotationFromInput(bgraImage.rotation),
            format: InputImageFormat.bgra8888,
            bytesPerRow: bgraImage.planes.first.bytesPerRow,
          ),
        );
      },
    );
  }

  InputImageRotation _rotationFromInput(InputAnalysisImageRotation rotation) {
    switch (rotation) {
      case InputAnalysisImageRotation.rotation90deg:
        return InputImageRotation.rotation90deg;
      case InputAnalysisImageRotation.rotation180deg:
        return InputImageRotation.rotation180deg;
      case InputAnalysisImageRotation.rotation270deg:
        return InputImageRotation.rotation270deg;
      default:
        return InputImageRotation.rotation0deg;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // CamerAwesome Builder
          CameraAwesomeBuilder.custom(
            saveConfig: SaveConfig.photoAndVideo(),
            onImageForAnalysis: _processImage,
            builder: (cameraState, preview) {
              return Stack(
                fit: StackFit.expand,
                children: [
                  // Dynamic AR Filter overlays
                  if (_selectedFilterIndex > 0)
                    ..._faces.map((face) {
                      return _buildAdornmentOverlay(face, screenSize);
                    }),

                  // Camera Control Panel Overlay
                  SafeArea(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Header Actions
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                                onPressed: () => Get.back(),
                              ),
                              Text(
                                "AR Snapchat Cam",
                                style: MyTextStyle.gilroyBold(size: 16, color: Colors.white),
                              ),
                              IconButton(
                                icon: const Icon(Icons.flip_camera_android_rounded, color: Colors.white, size: 26),
                                onPressed: () => cameraState.switchCameraSensor(),
                              ),
                            ],
                          ),
                        ),

                        // Shutter controls and filter selector
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Carousel of filters
                            SizedBox(
                              height: 70,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                itemCount: _filters.length,
                                itemBuilder: (context, index) {
                                  final isSelected = _selectedFilterIndex == index;
                                  return GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _selectedFilterIndex = index;
                                        if (index == 0) _faces = [];
                                      });
                                    },
                                    child: Container(
                                      margin: const EdgeInsets.only(right: 12),
                                      width: 60,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        color: isSelected ? cPrimary : Colors.black45,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: isSelected ? Colors.white : Colors.white24,
                                          width: 1.5,
                                        ),
                                      ),
                                      child: Icon(
                                        _filters[index]['icon'],
                                        color: isSelected ? Colors.black : Colors.white,
                                        size: 24,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Record/Capture Trigger Button
                            AwesomeCaptureButton(state: cameraState),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAdornmentOverlay(Face face, Size screenSize) {
    // Coordinate translation relative to screen size (using typical YUV 480x640 frame scaling)
    final double scaleX = screenSize.width / 480;
    final double scaleY = screenSize.height / 640;

    final boundingBox = face.boundingBox;
    final double left = boundingBox.left * scaleX;
    final double top = boundingBox.top * scaleY;
    final double width = boundingBox.width * scaleX;
    final double height = boundingBox.height * scaleY;

    // Retrieve face rotation (roll)
    final double rollAngle = face.headEulerAngleZ ?? 0.0;

    switch (_selectedFilterIndex) {
      case 1: // Cool Shades
        final leftEye = face.landmarks[FaceLandmarkType.leftEye];
        final rightEye = face.landmarks[FaceLandmarkType.rightEye];
        if (leftEye != null && rightEye != null) {
          final double eyeX = ((leftEye.position.x + rightEye.position.x) / 2) * scaleX;
          final double eyeY = ((leftEye.position.y + rightEye.position.y) / 2) * scaleY;
          
          final double glassWidth = width * 0.85;
          final double glassHeight = glassWidth * 0.4;

          return Positioned(
            left: eyeX - (glassWidth / 2),
            top: eyeY - (glassHeight / 2),
            width: glassWidth,
            height: glassHeight,
            child: Transform.rotate(
              angle: rollAngle * (math.pi / 180),
              child: const Icon(Icons.dark_mode, color: Colors.black, size: 70), // Cool shades overlay
            ),
          );
        }
        break;

      case 2: // Dog Ears
        final double crownWidth = width * 1.1;
        final double crownHeight = crownWidth * 0.55;

        return Positioned(
          left: left + (width / 2) - (crownWidth / 2),
          top: top - (crownHeight * 0.8),
          width: crownWidth,
          height: crownHeight,
          child: Transform.rotate(
            angle: rollAngle * (math.pi / 180),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Transform.rotate(angle: -0.3, child: const Icon(Icons.pets, color: Colors.brown, size: 55)),
                Transform.rotate(angle: 0.3, child: const Icon(Icons.pets, color: Colors.brown, size: 55)),
              ],
            ),
          ),
        );

      case 3: // Mustache
        final nose = face.landmarks[FaceLandmarkType.noseBase];
        if (nose != null) {
          final double noseX = nose.position.x * scaleX;
          final double noseY = nose.position.y * scaleY;
          
          final double mustWidth = width * 0.45;
          final double mustHeight = mustWidth * 0.35;

          return Positioned(
            left: noseX - (mustWidth / 2),
            top: noseY + (mustHeight * 0.1),
            width: mustWidth,
            height: mustHeight,
            child: Transform.rotate(
              angle: rollAngle * (math.pi / 180),
              child: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.black87, size: 50),
            ),
          );
        }
        break;

      case 4: // Neon Cyber
        return Positioned(
          left: left - 5,
          top: top - 5,
          width: width + 10,
          height: height + 10,
          child: Transform.rotate(
            angle: rollAngle * (math.pi / 180),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: cPrimary, width: 4.5),
                borderRadius: BorderRadius.circular(width * 0.45),
                boxShadow: [
                  BoxShadow(color: cPrimary.withValues(alpha: 0.5), blurRadius: 16),
                ],
              ),
            ),
          ),
        );
    }
    
    return const SizedBox.shrink();
  }
}
