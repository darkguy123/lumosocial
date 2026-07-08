import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

class ArCameraScreen extends StatefulWidget {
  final Function(String filePath) onMediaCaptured;
  const ArCameraScreen({Key? key, required this.onMediaCaptured}) : super(key: key);

  @override
  State<ArCameraScreen> createState() => _ArCameraScreenState();
}

class _ArCameraScreenState extends State<ArCameraScreen> {
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showSourcePicker();
    });
  }

  void _showSourcePicker() {
    bool didPick = false;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF151515),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 50,
                    height: 5,
                    decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 25),
                const Text(
                  "Choose Camera Mode",
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 25),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.white10,
                    child: Icon(Icons.camera_alt_rounded, color: Color(0xFF00FF87)),
                  ),
                  title: const Text("Take Photo", style: TextStyle(color: Colors.white)),
                  onTap: () async {
                    didPick = true;
                    Navigator.pop(context);
                    final file = await _picker.pickImage(source: ImageSource.camera);
                    if (file != null) {
                      widget.onMediaCaptured(file.path);
                    } else {
                      Get.back();
                    }
                  },
                ),
                const Divider(color: Colors.white10),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.white10,
                    child: Icon(Icons.videocam_rounded, color: Color(0xFF00FF87)),
                  ),
                  title: const Text("Record Video", style: TextStyle(color: Colors.white)),
                  onTap: () async {
                    didPick = true;
                    Navigator.pop(context);
                    final file = await _picker.pickVideo(source: ImageSource.camera);
                    if (file != null) {
                      widget.onMediaCaptured(file.path);
                    } else {
                      Get.back();
                    }
                  },
                ),
                const SizedBox(height: 15),
              ],
            ),
          ),
        );
      },
    ).then((value) {
      if (!didPick && mounted) {
        Get.back();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: CircularProgressIndicator(color: Color(0xFF00FF87)),
      ),
    );
  }
}
