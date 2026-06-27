class AudioSpaceUser {
  num? id;
  String? username;
  String? fullName;
  String? image;
  String? deviceToken;
  num? deviceType;
  bool? isVerified;
  AudioSpaceUserType? type;
  AudioSpaceMicStatus? micStatus;

  AudioSpaceUser({
    String? username,
    String? fullName,
    num? deviceType,
    String? deviceToken,
    String? image,
    bool? isVerified,
    num? id,
    AudioSpaceUserType? type,
    AudioSpaceMicStatus? micStatus,
  }) {
    this.username = username;
    this.fullName = fullName;
    this.deviceType = deviceType;
    this.deviceToken = deviceToken;
    this.image = image;
    this.isVerified = isVerified;
    this.id = id;
    this.type = type;
    this.micStatus = micStatus;
  }

  Map<String, dynamic> toJson() {
    return {
      'userName': username,
      "fullName": fullName,
      "deviceType": deviceType,
      "deviceToken": deviceToken,
      "image": image,
      "isVerified": isVerified,
      "id": id,
      "type": type?.value,
      "mic_status": micStatus?.value,
    };
  }

  AudioSpaceUser.fromJson(Map<String, dynamic> json) {
    username = json["userName"];
    fullName = json["fullName"];
    deviceToken = json["deviceToken"];
    deviceType = json["deviceType"];
    image = json["image"];
    isVerified = json["isVerified"];
    id = json["id"];
    type = AudioSpaceUserType.values.firstWhere((element) => element.value == json["type"]);
    micStatus = AudioSpaceMicStatus.values.firstWhere((element) => element.value == json["mic_status"]);
  }
}

enum AudioSpaceUserType {
  listener('LISTENER'),
  host('HOST'),
  admin('ADMIN'),
  requested('REQUESTED'),
  kickedOut('KICKED_OUT'),
  added('ADDED');

  final String value;

  const AudioSpaceUserType(this.value);
}

enum AudioSpaceMicStatus {
  notGranted('NOT_GRANTED'),
  muted('MUTED'),
  on('ON');

  final String value;

  const AudioSpaceMicStatus(this.value);
}
