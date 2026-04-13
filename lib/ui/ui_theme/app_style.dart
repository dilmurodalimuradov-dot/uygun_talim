import 'package:flutter/material.dart';
import 'package:pr/ui/ui_theme/colors.dart';

abstract class AppStyle {
  static TextStyle fontstyle = TextStyle(
    inherit: false,
    fontSize: 30,
    letterSpacing: 1,
    color: Appcolors.blue,
    fontFamily: 'Nexa',
  );
}
