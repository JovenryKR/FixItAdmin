import 'package:firebase_database/firebase_database.dart';
import 'package:fixit/utils/colors.dart';
import 'package:fixit/utils/margin.dart';
import 'package:fixit/utils/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/foundation/key.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:google_fonts/google_fonts.dart';

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({Key? key}) : super(key: key);

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  final FirebaseDatabase db = FirebaseDatabase.instance;
  Iterable categories = const [];
  String newcat = "";

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getCategories();
  }

  getCategories() {
    final DatabaseReference catref = db.ref("Categories");
    catref.onValue.listen((DatabaseEvent event) {
      final data = event.snapshot.children;
      print(data);
      Iterable categories = data;
      setState(() {
        this.categories = categories;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Categories"),
        elevation: 0,
        backgroundColor: green,
        actions: [
          IconButton(
              onPressed: () {
                addDialog();
              },
              icon: Icon(Icons.add))
        ],
        leading: IconButton(
            onPressed: () async {
              popRoute(context);
            },
            icon: Icon(Icons.arrow_back)),
      ),
      body: Container(
        child: ListView(
          padding: EdgeInsets.all(20),
          children: [
            ...categories.map((e) => Container(
                    // margin: EdgeInsets.only(bottom: 5),
                    child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      e.value.toString(),
                      style: GoogleFonts.poppins(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    TextButton(onPressed: () {
                      DatabaseReference ref =
                        FirebaseDatabase.instance.ref("Categories");
                        ref.child(e.key).remove();
                    }, child: Text("Remove"))
                  ],
                )))
          ],
        ),
      ),
    );
  }

  addDialog() {
    showDialog(
        context: context,
        builder: (_) {
          return AlertDialog(
            content: TextField(
              onChanged: (e) {
                setState(() {
                  newcat = e;
                });
              },
            ),
            actions: [
              TextButton(
                  onPressed: () async {
                    if (newcat == "") return;

                    var id = DateTime.now().millisecondsSinceEpoch;

                    DatabaseReference ref =
                        FirebaseDatabase.instance.ref("Categories/$id");

                    await ref.set(newcat);

                    setState(() {
                      newcat = "";
                    });
                    popRoute(context);
                  },
                  child: Text("Add")),
              TextButton(
                  onPressed: () {
                    setState(() {
                      newcat = "";
                    });
                    popRoute(context);
                  },
                  child: Text("Cancel"))
            ],
          );
        });
  }
}
