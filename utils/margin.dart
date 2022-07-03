import 'package:flutter/cupertino.dart';

class Margin {
  static Widget v({double? size}){
    return SizedBox(height: size ?? 10);
  }
  static Widget h({double? size}){
    return SizedBox(width: size ?? 10);
  }
}