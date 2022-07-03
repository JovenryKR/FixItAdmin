import 'package:firebase_database/firebase_database.dart';
import 'package:fixit/utils/colors.dart';
import 'package:fixit/utils/router.dart';
import 'package:fixit/utils/screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/foundation/key.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';

enum Menu { Delete}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedMenu = '';
  final FirebaseDatabase db = FirebaseDatabase.instance;
  var post;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    readposts();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        actions: [],
        backgroundColor: Colors.black,
        elevation: 0,
        title: Text("FIXIT ADMIN", style: GoogleFonts.anonymousPro(
          fontSize: 28, color:Colors.white, fontWeight: FontWeight.w700
        ),),
        // title: txtText('FixIT', 28, txtColors: Colors.white, txtBold: true),
      ),
      body: Container(
        width: Screen.width(context),
        height: Screen.height(context),
        child: SingleChildScrollView(
            child: Column(
          children: [
            if (post != null)
              ...post.map((e) => txtPost(
                  e.child("text").value.toString(),
                  e.child('name').value.toString(),
                  e.child('type').value.toString(),
                  e.key.toString(),
                  e.child('id').value.toString(),
                  txtStatus: e.child('status').value.toString(),
                  imageLink: e.child('meme').value.toString(),
                  imageProfile: e.child('dp').value.toString())),
          ],
        )),
      ),
    ));
  }

  readposts() async {
    final DatabaseReference postref = db.ref("Posts");
    postref.onValue.listen((DatabaseEvent event) {
      final data = event.snapshot.children.toList();
      data.sort((b,a)=> int.parse(a.child("pTime").value.toString()).compareTo(int.parse(b.child("pTime").value.toString())));
      setState(() {
        if (data != null) {
          post = data;
          print(data.first.child('meme').value.toString());
        }
      });
    });
  }

  deletePost(String postId, String userId){
   
    final DatabaseReference postref = db.ref("Posts");
    showDialog(context: context, 
      builder: (_){
        return AlertDialog(
          title: Text('Confirmation'),
          content: Text('Do you want to delete this post?'),
          actions: [
            TextButton(
              onPressed: (){
                popRoute(context);
                setState(() {
                  _selectedMenu = '';
                });
              }, 
              child: Text('Cancel')
            ),
            TextButton(
              onPressed: (){
                postref.child(postId).remove();
                addNotification(notification: "Your post was deleted by and admin. Reason: Invalid Post.", postId: postId, userId: userId);
                popRoute(context);
              }, 
              child: txtText('Delete', 15, txtColors: Colors.red[800])
            ),
          ],
        );
      }

    );
  }

  Widget txtPost(
      String txtCaption, 
      String txtName, 
      String txtCategory, 
      String postId,
      String userId,
      {String? txtStatus,
      dynamic imageLink, 
      String? imageProfile}) 
  {
    if (imageLink == null) {
      print("null image link");
    }

    if (txtStatus == 'null') {
      txtStatus = '';
    }

    return Container(
      padding: EdgeInsets.only(bottom: 5),
      color: Color.fromARGB(201, 187, 186, 186),
      child: Container(
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                if (imageProfile != null)
                  Container(
                    padding: EdgeInsets.all(10),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(25),
                      child: Image.network(
                        imageProfile,
                        height: 50,
                        width: 50,
                        errorBuilder: (context, error, stackTrace) {
                          return Image.network(
                            'https://firebasestorage.googleapis.com/v0/b/memespace-34a96.appspot.com/o/avatar.jpg?alt=media&token=8b875027-3fa4-4da4-a4d5-8b661d999472',
                            width: 50,
                          );
                        },
                      ),
                    ),
                  ),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // full name
                      txtText(txtName, 14, txtBold: true),
                      // post category
                      txtText(txtCategory, 14, txtColors: orange)
                    ],
                  ),
                ),
                // post status
                txtText(txtStatus!, 14,
                    txtColors: orange, txtBold: true, txtUCase: true),
                IconButton(
                  onPressed: () {},
                  icon: PopupMenuButton<Menu>(
                      // Callback that sets the selected popup menu item.
                      onSelected: (Menu item) {
                        setState(() {
                          _selectedMenu = item.name;
                          if(_selectedMenu != ''){
                            deletePost(postId, userId);
                          }
                        });
                      },
                      itemBuilder: (BuildContext context) =>
                          <PopupMenuEntry<Menu>>[
                            PopupMenuItem<Menu>(
                              value: Menu.Delete,
                              child: Text('Delete'),
                            ),
                          ]),
                ),
              ],
            ),
            Container(
                padding: EdgeInsets.all(10), child: txtText(txtCaption, 14)),
            if (imageLink != null)
              Image.network(imageLink, width: Screen.width(context),
                  errorBuilder: (context, error, stackTrace) {
                return Container(
                  child: Text(""),
                );
              },),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [

                if (txtStatus == 'Pending') 
                  ...[
                    txtStatButton('On Going',postId, userId),
                    txtStatButton('Done', postId, userId)
                  ],

                if (txtStatus == 'On Going') 
                  txtStatButton('Done', postId, userId),

                if (txtStatus == 'Done') 
                  SizedBox(height: 25,),

                if (txtStatus == 'null' || txtStatus == '') 
                ...[
                  txtStatButton('Pending', postId, userId),
                  txtStatButton('On Going', postId, userId),
                  txtStatButton('Done', postId, userId),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget txtStatButton(String txt, String postId, String userId) {
    final DatabaseReference postref = db.ref("Posts");
    return Container(
      child: TextButton(
        onPressed: () {
            postref.child(postId).child("status").set(txt);

            switch (txt) {
              case "Pending":
                addNotification(notification: "Your post is now pending.", postId: postId, userId: userId);
                break;
              case "On Going":
                addNotification(notification: "Your post is now On-going.", postId: postId, userId: userId);
                break;
              case "Done":
                addNotification(notification: "Your post is now Done", postId: postId, userId: userId);                
                break;
              default:
                break;
            }

        },
        child: txtText(txt, 14, txtBold: true),
      ),
    );
  }

  Widget txtText(String txt, double txtSize,
    {Color? txtColors, bool txtBold = false, bool txtUCase = false}) {
    return Container(
      child: Text(
        txtUCase ? txt.toUpperCase() : txt,
        style: TextStyle(
            fontSize: txtSize,
            fontWeight: txtBold ? FontWeight.bold : FontWeight.normal,
            color: txtColors ?? Colors.black),
      ),
    );
  }

  addNotification({required String notification, required postId, required userId}) async {
    final String uid = (await FlutterSecureStorage().read(key: "uid"))!;
    
    final int timestamp = DateTime.now().millisecondsSinceEpoch;
    final DatabaseReference notifRef = db.ref("Users").child(userId).child("Notifications").child(timestamp.toString());
    notifRef.set({
      "pId": postId,
      "timestamp": timestamp,
      "pUid": userId,
      "notification": notification,
      "sUid": uid
    });
  }

}
