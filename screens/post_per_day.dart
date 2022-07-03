import 'package:firebase_database/firebase_database.dart';
import 'package:fixit/utils/margin.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/foundation/key.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class PostPerDayCard extends StatefulWidget {
  const PostPerDayCard({Key? key}) : super(key: key);

  @override
  State<PostPerDayCard> createState() => _PostPerDayCardState();
}

class _PostPerDayCardState extends State<PostPerDayCard> {

  final FirebaseDatabase db = FirebaseDatabase.instance;
  List<DataSnapshot> todayPosts = [];
  List<DataSnapshot> yesterdayPosts = [];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    readPosts();
  }

  readPosts(){
    final DatabaseReference postref = db.ref("Posts");
    postref.onValue.listen((event) {
      List<DataSnapshot> posts = event.snapshot.children.toList();
      var date = DateTime.now();
      var today = DateFormat("MMMM d, y").format(date);
      print(today);
      var yesterday = DateFormat("MMMM d, y").format(date.subtract(Duration(days: 1)));
      // List<DataSnapshot> todayPosts = [];
      setState(() {
        todayPosts = posts.where((element) {
          var ptime = DateFormat("MMMM d, y").format(DateTime.fromMillisecondsSinceEpoch(int.parse(element.child("pTime").value.toString())));
          return ptime == today;
        }).toList();
        yesterdayPosts = posts.where((element) {
          var ptime = DateFormat("MMMM d, y").format(DateTime.fromMillisecondsSinceEpoch(int.parse(element.child("pTime").value.toString())));
          return ptime == yesterday;
        }).toList();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 30),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              blurRadius: 30,
              color: Colors.black.withOpacity(.20),
              offset: Offset(0,30),
              spreadRadius: -16
            )
          ],
          gradient: LinearGradient(
              colors: [Colors.lightBlue, Colors.lightBlue.shade300])),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                    color: Colors.black.withOpacity(.16),
                    borderRadius: BorderRadius.circular(50)),
                child: SvgPicture.asset(
                  "assets/icons/post.svg",
                  width: 30,
                  color: Colors.white,
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    todayPosts.length.toString(),
                    style: GoogleFonts.poppins(
                        fontSize: 25,
                        color: Colors.white,
                        fontWeight: FontWeight.w700),
                  ),
                  Text(
                    "Users Post",
                    style: GoogleFonts.poppins(color: Colors.white),
                  )
                ],
              ),
            ],
          ),
          Margin.v(size: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "YESTERDAY'S POSTS",
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.white, fontSize: 16),
              ),
              Text(
                yesterdayPosts.length.toString(),
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.white, fontSize: 16),
              ),

            ],
          )
        ],
      ),
    );
  }
}
