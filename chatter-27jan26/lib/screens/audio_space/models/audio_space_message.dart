import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:untitled/screens/audio_space/models/audio_space_user.dart';

class AudioSpaceMessage {
  String? id;
  int? userId;
  String? content;
  DateTime? time;
  AudioSpaceUser? user;

  AudioSpaceMessage({this.id, this.userId, this.content, this.time});

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = id;
    map['userId'] = userId;
    map['content'] = content;
    map['time'] = time;
    return map;
  }

  factory AudioSpaceMessage.fromFireStore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data();
    return AudioSpaceMessage(
      id: data?['id'],
      userId: data?['userId'],
      content: data?['content'],
      time: (data?['time'] as Timestamp?)?.toDate(),
    );
  }

  AudioSpaceMessage.fromJson(Map<String, dynamic> json) {
    id = json["id"];
    userId = json["userId"];
    content = json["content"];
    time = (json["time"] as Timestamp).toDate();
  }

  String getChatTime() {
    return DateFormat('h:mm a').format(
      DateTime.fromMillisecondsSinceEpoch((int.parse(id ?? '0') / 1000).round()),
    );
  }
}
