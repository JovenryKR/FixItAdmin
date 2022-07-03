import 'package:firebase_auth/firebase_auth.dart';
import 'package:fixit/utils/router.dart';
import 'package:fixit/utils/screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/foundation/key.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    Future.delayed(Duration(seconds: 1), (){
      checkLogin();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: Screen.width(context),
        height: Screen.height(context),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.asset("assets/img/app logo.png",width: Screen.width(context) * .6,))
          ],
        ),
      ),
    );
  }

  checkLogin() async {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if(user == null){
        cleanPushRoute(context, url: "/login");
      } else {
        cleanPushRoute(context, url: "/navigator");
      }
    });
  }
}