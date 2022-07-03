import 'package:another_flushbar/flushbar.dart';
import 'package:email_validator/email_validator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fixit/utils/colors.dart';
import 'package:fixit/utils/margin.dart';
import 'package:fixit/utils/router.dart';
import 'package:fixit/utils/screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_database/firebase_database.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final FirebaseDatabase db = FirebaseDatabase.instance;
  String email = "";
  String password = "";

  @override
  void initState() {
    super.initState();
    readposts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: AnnotatedRegion<SystemUiOverlayStyle>(
          value: const SystemUiOverlayStyle(
              statusBarColor: Colors.transparent
          ),
          child: Container(
              padding: EdgeInsets.all(20),
              width: Screen.width(context),
              height: Screen.height(context),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    "FixIT",
                    style: GoogleFonts.poppins(
                        fontSize: 90, fontWeight: FontWeight.w700),
                  ),
                  Text(
                    "Administrator",
                    style: GoogleFonts.poppins(fontSize: 18, color: orange),
                  ),
                  Margin.v(size: 120),
                  TextField(
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(fontSize: 22, color: Colors.white),
                    decoration: InputDecoration(
                        contentPadding: EdgeInsets.all(10),
                        fillColor: blue,
                        filled: true,
                        border: InputBorder.none,
                        prefixIcon: const Icon(Icons.email_outlined,
                            color: Colors.white, size: 30),
                        hintText: "Email",
                        hintStyle: GoogleFonts.poppins(color: Colors.white)),
                        onChanged: (String value) {
                          setState(() {
                            email = value;
                          });
                        },
                  ),
                  Margin.v(size: 25),
                  TextField(
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(fontSize: 22, color: Colors.white),
                    obscureText: true,
                    decoration: InputDecoration(
                        contentPadding: EdgeInsets.all(10),
                        fillColor: Color.fromARGB(255, 250, 232, 69),
                        filled: true,
                        border: InputBorder.none,
                        prefixIcon: const Icon(Icons.lock_outline,
                            color: Colors.white, size: 30),
                        hintText: "Password",
                        hintStyle: GoogleFonts.poppins(color: Colors.white)),
                        onChanged: (String value) {
                          setState(() {
                            password = value;
                          });
                        },
                  ),
                  Margin.v(size: 60),
                  TextButton(
                    onPressed: () {
                      login();
                    },
                    style: TextButton.styleFrom(
                        backgroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.zero),
                        padding: EdgeInsets.all(5)),
                    child: Text(
                      "sign in",
                      style: GoogleFonts.poppins(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          color: Colors.white),
                    ),
                  )
                ],
              )),
        ));
  }

  readposts() async {
    // final DatabaseReference postref = db.ref("Posts");
    // postref.onValue.listen((DatabaseEvent event) {
    //   final data = event.snapshot.value;
    //   print(data);
    // });
    
    FirebaseAuth.instance.authStateChanges().listen((User? event) {
      print(event);
    });
  }

  login() async {
    // flushbarError("test");

    if(!EmailValidator.validate(email)){
      flushbarError("The email address is badly formatted.");
      return;
    }

    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);
      print(credential);
      await FlutterSecureStorage().write(key: "uid", value: credential.user!.uid);
      cleanPushRoute(context, url: "/navigator");
    } on FirebaseAuthException catch (e) {
      flushbarError("There is no user record corresponding to this identifier. The user may have been deleted.");
    }
  }

  flushbarError(String message){
    Flushbar(
      titleText: Text("Error", style: GoogleFonts.poppins(
        fontWeight: FontWeight.w700,
        color: Colors.white,
        fontSize: 16
      ),),
      messageText: Text(message, style: GoogleFonts.poppins(
        color: Colors.white,
        fontSize: 14
      ),),
      animationDuration: Duration(milliseconds: 400),
      duration: Duration(seconds: 5),
      flushbarPosition: FlushbarPosition.TOP,
      backgroundColor: blue,
      flushbarStyle: FlushbarStyle.GROUNDED,
      padding: EdgeInsets.only(left: 60, top: 30, bottom: 20, right: 20),
    ).show(context);
  }
}
