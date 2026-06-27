import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:untitled/common/managers/session_manager.dart';
import 'package:untitled/models/setting_model.dart';
import 'package:untitled/screens/audio_space/create_audio_space_screen/create_audio_space_controller.dart';
import 'package:untitled/screens/audio_space/models/audio_space_user.dart';

class AudioSpace {
  String? id;
  String? title;
  String? description;
  String? topics;
  AudioSpaceType? type;
  String? token;
  DateTime? createdAt;

  List<AudioSpaceUser>? users;
  List<AudioSpaceUser>? leavedUsers;

  AudioSpace({this.id, this.title, this.description, this.topics, this.type, this.users, this.createdAt, this.leavedUsers, this.token});

  factory AudioSpace.fromFireStore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data();
    return AudioSpace(
      id: data?["id"],
      title: data?["title"],
      token: data?["token"],
      description: data?["description"],
      topics: data?["topics"],
      type: AudioSpaceType.values.firstWhere((element) => element.value == (data?["type"] ?? '')),
      createdAt: (data?["created_at"] as Timestamp).toDate(),
      users: (data?["users"] as List<dynamic>?)?.map((userJson) => AudioSpaceUser.fromJson(userJson as Map<String, dynamic>)).toList(),
      leavedUsers: (data?["leaved_users"] as List<dynamic>?)?.map((userJson) => AudioSpaceUser.fromJson(userJson as Map<String, dynamic>)).toList(),
    );
  }

  Map<String, dynamic> toFireStore() {
    return {
      "id": id,
      "title": title,
      "description": description,
      "topics": topics,
      "token": token,
      "type": type?.value,
      "created_at": createdAt,
      "users": users?.map((user) => user.toJson()).toList(),
      "leaved_users": leavedUsers?.map((user) => user.toJson()).toList(),
    };
  }

  List<Interest> get interests {
    if (topics == null || topics == "") return [];
    var ids = (topics ?? '').split(',').where((s) => s.isNotEmpty).map((s) => int.parse(s)).toList();
    var interests = SessionManager.shared.getSettings()?.interests?.where((interest) {
          return ids.contains(interest.id?.toInt());
        }).toList() ??
        [];
    return interests;
  }

  bool isUserInAudioSpace(AudioSpaceUser myUser) {
    return users?.where((element) => element.type != AudioSpaceUserType.added).any((element) => element.id == myUser.id) ?? false;
  }

  bool isUserInLeavedUsers(AudioSpaceUser myUser) {
    return leavedUsers?.any((element) => element.id == myUser.id) ?? false;
  }

  List<AudioSpaceUser> get hosts {
    return _filterUser(AudioSpaceUserType.host);
  }

  List<AudioSpaceUser> get requests {
    return _filterUser(AudioSpaceUserType.requested);
  }

  List<AudioSpaceUser> get requestsAndListener {
    var users = requests + listener;
    sortUsersByFullName(users);
    return users;
  }

  List<AudioSpaceUser> get admins {
    return _filterUser(AudioSpaceUserType.admin);
  }

  List<AudioSpaceUser> get addedUsers {
    return _filterUser(AudioSpaceUserType.added);
  }

  List<AudioSpaceUser> get hostsWithAdmin {
    var users = admins + hosts;
    sortUsersByFullName(users);
    return users;
  }

  List<AudioSpaceUser> get listener {
    return _filterUser(AudioSpaceUserType.listener);
  }

  List<AudioSpaceUser> _filterUser(AudioSpaceUserType type) {
    sortUsersByFullName(users ?? []);
    return users?.where((element) => element.type == type).toList() ?? [];
  }

  void sortUsersByFullName(List<AudioSpaceUser> users) {
    users.sort((a, b) {
      final nameA = a.fullName?.toLowerCase() ?? '';
      final nameB = b.fullName?.toLowerCase() ?? '';
      return nameA.compareTo(nameB);
    });
  }
}
