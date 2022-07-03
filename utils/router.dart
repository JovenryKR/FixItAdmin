import 'package:fixit/screens/categories.dart';
import 'package:fixit/screens/login.dart';
import 'package:fixit/screens/navigator.dart';
import 'package:fixit/screens/splash.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class RouterGenerator {
  static Route<dynamic> routeTo(RouteSettings settings){
    final args = settings.arguments;

    switch (settings.name) {
      case '/':
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case '/login':
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case '/navigator':
        return MaterialPageRoute(builder: (_) => const NavigatorScreen());
      case '/categories':
        return MaterialPageRoute(builder: (_) => const CategoriesPage());
      default:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
    }
  }
}

Future pushRoute(BuildContext context, {required String url, Object? arguments}){
  FocusScope.of(context).unfocus();
  return Navigator.of(context).pushNamed(url, arguments: arguments);
}

void cleanPushRoute(BuildContext context, {required String url, Object? arguments}){
  Navigator.of(context).pushNamedAndRemoveUntil(url, (route) => false);
}

void popRoute(BuildContext context){
  Navigator.of(context).pop();
}