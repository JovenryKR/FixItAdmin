import 'package:flutter/cupertino.dart';

class Screen {
  static double width(BuildContext context){
    return MediaQuery.of(context).size.width;
  }
  static double height(BuildContext context){
    return MediaQuery.of(context).size.height;
  }
  static EdgeInsets viewInsets(BuildContext context){
    return MediaQuery.of(context).viewInsets;
  }
}