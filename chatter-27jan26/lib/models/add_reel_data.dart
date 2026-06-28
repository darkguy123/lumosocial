import 'package:flutter/foundation.dart';
import 'package:lumosocial/models/musics_model.dart';
import 'package:lumosocial/utilities/filters.dart';

class AddReelData {
  String? videoPath;
  SelectedMusic? selectedMusic;
  Filters? filter;
  String? thumbnailPath;
  Uint8List? thumbnailBytes;

  AddReelData({this.videoPath, this.selectedMusic, this.filter});
}
