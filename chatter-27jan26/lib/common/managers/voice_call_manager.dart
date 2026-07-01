import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lumosocial/common/managers/session_manager.dart';
import 'package:lumosocial/screens/chats_screen/calling/voice_call_screen.dart';

class VoiceCallManager {
  static final VoiceCallManager shared = VoiceCallManager._();
  VoiceCallManager._();

  StreamSubscription? _incomingCallSubscription;

  void init() {
    final myId = SessionManager.shared.getUserID();
    if (myId == 0) return;

    _incomingCallSubscription?.cancel();
    _incomingCallSubscription = FirebaseFirestore.instance
        .collection('calls')
        .where('receiverId', isEqualTo: myId)
        .where('status', isEqualTo: 'dialing')
        .snapshots()
        .listen((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        final data = doc.data();
        
        // Show incoming call overlay / route screen
        if (Get.currentRoute != '/VoiceCallScreen') {
          Get.to(() => VoiceCallScreen(
                callId: doc.id,
                channelId: data['channelId'] ?? '',
                callerId: (data['callerId'] ?? 0).toInt(),
                callerName: data['callerName'] ?? 'Chatter User',
                callerImage: data['callerImage'] ?? '',
                isIncoming: true,
              ));
        }
      }
    });
  }

  void stop() {
    _incomingCallSubscription?.cancel();
  }
}
