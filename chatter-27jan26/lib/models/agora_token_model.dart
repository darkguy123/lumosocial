class AgoraTokenModel {
  AgoraTokenModel({
      this.status, 
      this.message, 
      this.token,});

  AgoraTokenModel.fromJson(dynamic json) {
    status = json['status'];
    message = json['message'];
    token = json['token'];
  }
  bool? status;
  String? message;
  String? token;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['status'] = status;
    map['message'] = message;
    map['token'] = token;
    return map;
  }

}