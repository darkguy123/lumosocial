class AgoraUsersModel {
  AgoraUsersModel({
    bool? success,
    AgoraUser? data,
  }) {
    _success = success;
    _data = data;
  }

  AgoraUsersModel.fromJson(dynamic json) {
    _success = json['success'];
    _data = json['data'] != null ? AgoraUser.fromJson(json['data']) : null;
  }

  bool? _success;
  AgoraUser? _data;

  bool? get success => _success;

  AgoraUser? get data => _data;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['success'] = _success;
    if (_data != null) {
      map['data'] = _data?.toJson();
    }
    return map;
  }
}

class AgoraUser {
  AgoraUser({
    bool? channelExist,
    int? mode,
    List<int>? broadcasters,
    List<int>? audience,
    int? audienceTotal,
  }) {
    _channelExist = channelExist;
    _mode = mode;
    _broadcasters = broadcasters;
    _audience = audience;
    _audienceTotal = audienceTotal;
  }

  AgoraUser.fromJson(dynamic json) {
    _channelExist = json['channel_exist'];
    _mode = json['mode'];
    _broadcasters = json['broadcasters'] != null ? json['broadcasters'].cast<int>() : [];
    _audience = json['audience'] != null ? json['audience'].cast<int>() : [];
    _audienceTotal = json['audience_total'];
  }

  bool? _channelExist;
  int? _mode;
  List<int>? _broadcasters;
  List<int>? _audience;
  int? _audienceTotal;

  bool? get channelExist => _channelExist;

  int? get mode => _mode;

  List<int>? get broadcasters => _broadcasters;

  List<int>? get audience => _audience;

  int? get audienceTotal => _audienceTotal;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['channel_exist'] = _channelExist;
    map['mode'] = _mode;
    map['broadcasters'] = _broadcasters;
    map['audience'] = _audience;
    map['audience_total'] = _audienceTotal;
    return map;
  }
}
