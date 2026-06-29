import 'package:flutter/material.dart';
import 'package:lumosocial/common/extensions/image_extension.dart';

class LogoTag extends StatelessWidget {
  final bool? isWhite;
  final double? width;

  const LogoTag({Key? key, this.isWhite, this.width = 100}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    bool useWhite = isWhite ?? (Theme.of(context).brightness == Brightness.dark);
    return Image.asset(
      useWhite ? MyImages.logoWhite : MyImages.logoBlack,
      width: width,
      fit: BoxFit.contain,
    );
  }
}
