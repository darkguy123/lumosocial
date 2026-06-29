import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_native_video_trimmer/flutter_native_video_trimmer.dart';
import 'package:lumosocial/utilities/const.dart';
import 'package:lumosocial/common/extensions/font_extension.dart';

class VideoCropperScreen extends StatefulWidget {
  final String videoPath;
  final double maxDurationSeconds;

  const VideoCropperScreen({
    Key? key,
    required this.videoPath,
    required this.maxDurationSeconds,
  }) : super(key: key);

  @override
  State<VideoCropperScreen> createState() => _VideoCropperScreenState();
}

class _VideoCropperScreenState extends State<VideoCropperScreen> {
  late VideoPlayerController _videoController;
  bool _isInitialized = false;
  bool _isCropping = false;

  double _totalDuration = 0.0;
  double _startValue = 0.0;
  double _endValue = 0.0;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    _videoController = VideoPlayerController.file(File(widget.videoPath));
    try {
      await _videoController.initialize();
      _totalDuration = _videoController.value.duration.inMilliseconds / 1000.0;
      
      // Default crop: starting from 0 up to maxDuration
      _startValue = 0.0;
      _endValue = _totalDuration > widget.maxDurationSeconds
          ? widget.maxDurationSeconds
          : _totalDuration;

      setState(() {
        _isInitialized = true;
      });
      _videoController.play();
      _videoController.setLooping(true);
    } catch (e) {
      debugPrint("Error initializing video player: $e");
      Get.back();
      Get.snackbar("Error", "Could not load video player", backgroundColor: Colors.red);
    }
  }

  @override
  void dispose() {
    _videoController.dispose();
    super.dispose();
  }

  String _formatDuration(double seconds) {
    final int minutes = (seconds / 60).floor();
    final int remainingSeconds = (seconds % 60).floor();
    return "$minutes:${remainingSeconds.toString().padLeft(2, '0')}";
  }

  Future<void> _cropVideo() async {
    if (_isCropping) return;
    setState(() {
      _isCropping = true;
    });

    _videoController.pause();

    Get.dialog(
      const Center(
        child: Card(
          color: Color(0xFF1E1E1E),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 30, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: Color(0xFF00FF87)),
                SizedBox(height: 15),
                Text(
                  "Cropping video... Please wait",
                  style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: false,
    );

    try {
      final trimmer = VideoTrimmer();
      await trimmer.loadVideo(widget.videoPath);
      final startTimeMs = (_startValue * 1000).toInt();
      final endTimeMs = (_endValue * 1000).toInt();

      final trimmedPath = await trimmer.trimVideo(
        startTimeMs: startTimeMs,
        endTimeMs: endTimeMs,
        includeAudio: true,
      );

      Get.back(); // close progress dialog

      if (trimmedPath != null && trimmedPath.isNotEmpty) {
        Get.back(result: trimmedPath);
      } else {
        setState(() {
          _isCropping = false;
        });
        Get.snackbar("Error", "Failed to crop video", backgroundColor: Colors.red);
      }
    } catch (e) {
      Get.back(); // close progress dialog
      setState(() {
        _isCropping = false;
      });
      debugPrint("Cropper error: $e");
      Get.snackbar("Error", "An error occurred during video cropping", backgroundColor: Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          "Trim Video (Max ${widget.maxDurationSeconds.toInt()}s)",
          style: MyTextStyle.gilroyBold(color: Colors.white, size: 16),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        actions: [
          if (_isInitialized)
            TextButton(
              onPressed: _cropVideo,
              child: Text(
                "Trim",
                style: MyTextStyle.gilroyBold(color: const Color(0xFF00FF87), size: 16),
              ),
            ),
        ],
      ),
      body: !_isInitialized
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF00FF87)))
          : SafeArea(
              child: Column(
                children: [
                  // Video Player Preview
                  Expanded(
                    child: Center(
                      child: AspectRatio(
                        aspectRatio: _videoController.value.aspectRatio,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            VideoPlayer(_videoController),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _videoController.value.isPlaying
                                      ? _videoController.pause()
                                      : _videoController.play();
                                });
                              },
                              child: Container(
                                color: Colors.transparent,
                                child: Center(
                                  child: AnimatedOpacity(
                                    opacity: _videoController.value.isPlaying ? 0.0 : 1.0,
                                    duration: const Duration(milliseconds: 200),
                                    child: const CircleAvatar(
                                      radius: 30,
                                      backgroundColor: Colors.black45,
                                      child: Icon(Icons.play_arrow_rounded, color: Colors.white, size: 40),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  // Timeline / Cropping Control Panel
                  Container(
                    color: const Color(0xFF151515),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Start: ${_formatDuration(_startValue)}",
                              style: MyTextStyle.gilroyRegular(color: Colors.white70, size: 12),
                            ),
                            Text(
                              "Selected Duration: ${_formatDuration(_endValue - _startValue)}",
                              style: MyTextStyle.gilroyBold(color: const Color(0xFF00FF87), size: 13),
                            ),
                            Text(
                              "End: ${_formatDuration(_endValue)}",
                              style: MyTextStyle.gilroyRegular(color: Colors.white70, size: 12),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        RangeSlider(
                          values: RangeValues(_startValue, _endValue),
                          min: 0.0,
                          max: _totalDuration,
                          activeColor: const Color(0xFF00FF87),
                          inactiveColor: Colors.white12,
                          onChanged: (RangeValues values) {
                            // Enforce the maximum selected duration
                            double newStart = values.start;
                            double newEnd = values.end;
                            
                            if (newEnd - newStart > widget.maxDurationSeconds) {
                              if (newStart != _startValue) {
                                // Start thumb moved
                                newEnd = newStart + widget.maxDurationSeconds;
                              } else {
                                // End thumb moved
                                newStart = newEnd - widget.maxDurationSeconds;
                              }
                            }

                            setState(() {
                              _startValue = newStart;
                              _endValue = newEnd;
                            });

                            // Seek video player preview to the new start value on change
                            _videoController.seekTo(Duration(milliseconds: (newStart * 1000).toInt()));
                          },
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          "Drag handles to select a portion of the video to upload.",
                          style: TextStyle(color: Colors.white30, fontSize: 11),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
