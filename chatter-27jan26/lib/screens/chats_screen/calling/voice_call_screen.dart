import 'dart:async';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lumosocial/common/api_service/common_service.dart';
import 'package:lumosocial/common/extensions/font_extension.dart';
import 'package:lumosocial/common/managers/session_manager.dart';
import 'package:lumosocial/common/widgets/my_cached_image.dart';
import 'package:lumosocial/utilities/const.dart';
import 'package:permission_handler/permission_handler.dart';

class VoiceCallScreen extends StatefulWidget {
  final String callId;
  final String channelId;
  final int callerId;
  final String callerName;
  final String callerImage;
  final bool isIncoming;

  const VoiceCallScreen({
    Key? key,
    required this.callId,
    required this.channelId,
    required this.callerId,
    required this.callerName,
    required this.callerImage,
    required this.isIncoming,
  }) : super(key: key);

  @override
  State<VoiceCallScreen> createState() => _VoiceCallScreenState();
}

class _VoiceCallScreenState extends State<VoiceCallScreen> {
  RtcEngine? _engine;
  bool _isJoined = false;
  bool _isMuted = false;
  bool _isSpeakerOn = false;
  String _callStatus = "Dialing...";
  StreamSubscription? _callDocSubscription;
  Timer? _durationTimer;
  int _callDurationSeconds = 0;

  @override
  void initState() {
    super.initState();
    _callStatus = widget.isIncoming ? "Incoming Call..." : "Dialing...";
    _listenToCallStatus();
    if (!widget.isIncoming) {
      _initAgoraAndJoin();
    }
  }

  void _listenToCallStatus() {
    _callDocSubscription = FirebaseFirestore.instance
        .collection('calls')
        .doc(widget.callId)
        .snapshots()
        .listen((snapshot) {
      if (!snapshot.exists) {
        _endCallLocally();
        return;
      }
      final data = snapshot.data();
      final status = data?['status'] ?? 'dialing';
      if (status == 'ended') {
        _endCallLocally();
      } else if (status == 'active') {
        setState(() {
          _callStatus = "Connected";
        });
        _startDurationTimer();
        if (widget.isIncoming && !_isJoined) {
          _initAgoraAndJoin();
        }
      }
    });
  }

  void _startDurationTimer() {
    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _callDurationSeconds++;
      });
    });
  }

  Future<void> _initAgoraAndJoin() async {
    // Request microphone permission
    await Permission.microphone.request();

    // Create Agora Engine
    _engine = createAgoraRtcEngine();
    await _engine!.initialize(const RtcEngineContext(
      appId: agoraAppId,
      channelProfile: ChannelProfileType.channelProfileCommunication,
    ));

    // Register Event Handler
    _engine!.registerEventHandler(RtcEngineEventHandler(
      onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
        debugPrint("Agora Joined Channel Success: ${connection.channelId}");
        setState(() {
          _isJoined = true;
        });
      },
      onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
        debugPrint("Remote user joined: $remoteUid");
        if (!widget.isIncoming) {
          FirebaseFirestore.instance
              .collection('calls')
              .doc(widget.callId)
              .update({'status': 'active'});
        }
      },
      onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
        _hangUp();
      },
      onLeaveChannel: (RtcConnection connection, RtcStats stats) {
        setState(() {
          _isJoined = false;
        });
      },
    ));

    await _engine!.enableAudio();
    await _engine!.setEnableSpeakerphone(_isSpeakerOn);

    // Fetch Token
    CommonService.shared.generateAgoraToken(
      channelName: widget.channelId,
      completion: (token) async {
        final myId = SessionManager.shared.getUserID();
        await _engine!.joinChannel(
          token: token,
          channelId: widget.channelId,
          uid: myId.toInt(),
          options: const ChannelMediaOptions(
            clientRoleType: ClientRoleType.clientRoleBroadcaster,
            publishMicrophoneTrack: true,
            autoSubscribeAudio: true,
          ),
        );
      },
    );
  }

  void _acceptCall() {
    FirebaseFirestore.instance
        .collection('calls')
        .doc(widget.callId)
        .update({'status': 'active'});
  }

  void _hangUp() {
    FirebaseFirestore.instance
        .collection('calls')
        .doc(widget.callId)
        .update({'status': 'ended'});
    _endCallLocally();
  }

  void _endCallLocally() {
    _durationTimer?.cancel();
    _callDocSubscription?.cancel();
    if (_engine != null) {
      _engine!.leaveChannel();
      _engine!.release();
    }
    if (Navigator.canPop(context)) {
      Get.back();
    }
  }

  void _toggleMute() {
    if (_engine == null) return;
    setState(() {
      _isMuted = !_isMuted;
    });
    _engine!.muteLocalAudioStream(_isMuted);
  }

  void _toggleSpeaker() {
    if (_engine == null) return;
    setState(() {
      _isSpeakerOn = !_isSpeakerOn;
    });
    _engine!.setEnableSpeakerphone(_isSpeakerOn);
  }

  String _formatDuration(int seconds) {
    final int minutes = seconds ~/ 60;
    final int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _durationTimer?.cancel();
    _callDocSubscription?.cancel();
    if (_engine != null) {
      _engine!.leaveChannel();
      _engine!.release();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDialing = _callStatus == "Dialing..." || _callStatus == "Incoming Call...";
    
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            // Avatar
            CircleAvatar(
              radius: 65,
              backgroundColor: Colors.white10,
              child: MyCachedProfileImage(
                fullName: widget.callerName,
                imageUrl: widget.callerImage,
                width: 120,
                height: 120,
                cornerRadius: 100,
              ),
            ),
            const SizedBox(height: 20),
            // Caller Name
            Text(
              widget.callerName,
              style: MyTextStyle.gilroyBold(color: Colors.white, size: 24),
            ),
            const SizedBox(height: 10),
            // Call Status / Duration
            Text(
              _callStatus == "Connected" ? _formatDuration(_callDurationSeconds) : _callStatus,
              style: MyTextStyle.gilroyMedium(
                color: _callStatus == "Connected" ? const Color(0xFF00FF87) : Colors.white60,
                size: 16,
              ),
            ),
            const Spacer(),
            // Call control buttons
            Container(
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Mute Button
                      IconButton(
                        icon: Icon(
                          _isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                          color: _isMuted ? Colors.redAccent : Colors.white,
                          size: 32,
                        ),
                        onPressed: _toggleMute,
                      ),
                      // End Call Button
                      GestureDetector(
                        onTap: _hangUp,
                        child: const CircleAvatar(
                          radius: 35,
                          backgroundColor: Colors.redAccent,
                          child: Icon(Icons.call_end_rounded, color: Colors.white, size: 36),
                        ),
                      ),
                      // Speaker Button
                      IconButton(
                        icon: Icon(
                          _isSpeakerOn ? Icons.volume_up_rounded : Icons.volume_down_rounded,
                          color: _isSpeakerOn ? const Color(0xFF00FF87) : Colors.white,
                          size: 32,
                        ),
                        onPressed: _toggleSpeaker,
                      ),
                    ],
                  ),
                  if (widget.isIncoming && isDialing) ...[
                    const SizedBox(height: 25),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00FF87),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                      icon: const Icon(Icons.call),
                      label: Text("Answer Call", style: MyTextStyle.gilroyBold(size: 16)),
                      onPressed: _acceptCall,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
