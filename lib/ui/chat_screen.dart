import 'dart:io';

import 'package:chat/chat_message.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../widgets/text_composer.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GoogleSignIn googleSignIn = GoogleSignIn();

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  User? _currentUser;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    FirebaseAuth.instance.authStateChanges().listen((user) {
      setState(() {
        _currentUser = user;
      });
    });
  }

  Future<User?> _getUser() async {
    if (_currentUser != null) return _currentUser;

    try {
      final GoogleSignInAccount? googleSignInAccount =
          await googleSignIn.signIn();
      final GoogleSignInAuthentication googleSignInAuthentication =
          await googleSignInAccount!.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleSignInAuthentication.idToken,
        accessToken: googleSignInAuthentication.accessToken,
      );

      final UserCredential authResult =
          await FirebaseAuth.instance.signInWithCredential(credential);

      final User? user = authResult.user;

      return user;
    } catch (error) {
      return null;
    }
  }

  void _sendMensage({String? text, XFile? photoFile}) async {
    final User? user = await _getUser();

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Nao foi possivel fazer o login, tente novamente!"),
          backgroundColor: Colors.red,
        ),
      );
    }

    Map<String, dynamic> data = {
      "uid": user?.uid,
      "sender_name": user?.displayName,
      "sender_photo_url": user?.photoURL,
      "time": Timestamp.now(),
    };

    if (photoFile != null) {
      File file = File(photoFile.path);
      UploadTask task = FirebaseStorage.instance
          .ref()
          .child(user!.uid + DateTime.now().millisecondsSinceEpoch.toString())
          .putFile(file);

      setState(() {
        _isLoading = true;
      });

      TaskSnapshot taskSnapshot = await task;
      String url = await taskSnapshot.ref.getDownloadURL();

      data["imageUrl"] = url;

      setState(() {
        _isLoading = false;
      });
    }
    if (text != null) data["text"] = text;

    FirebaseFirestore.instance.collection("messages").add(data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(
          _currentUser != null
              ? "Olá,${_currentUser?.displayName}"
              : "Chat App",
          style: const TextStyle(fontStyle: FontStyle.italic),
        ),
        elevation: 0,
        centerTitle: true,
        actions: [
          _currentUser != null
              ? IconButton(
                  onPressed: () {
                    FirebaseAuth.instance.signOut();
                    googleSignIn.signOut();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Você saiu com sucesso!"),
                      ),
                    );
                  },
                  icon: const Icon(Icons.exit_to_app),
                )
              : Container(),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection("messages")
                  .orderBy("time")
                  .snapshots(),
              builder: (context, snapshot) {
                switch (snapshot.connectionState) {
                  case ConnectionState.none:
                  case ConnectionState.waiting:
                    return const Center(
                      child: CircularProgressIndicator(),
                    );

                  default:
                    List<DocumentSnapshot> documents =
                        snapshot.data!.docs.reversed.toList();
                    return ListView.builder(
                        itemCount: documents.length,
                        reverse: true,
                        itemBuilder: (context, index) {
                          return ChatMessage(
                            data:
                                documents[index].data() as Map<String, dynamic>,
                            mine: _currentUser?.uid != null,
                          );
                        });
                }
              },
            ),
          ),
          _isLoading ? const LinearProgressIndicator() : Container(),
          TextComposer(sendMessage: _sendMensage, photoFile: () {}),
        ],
      ),
    );
  }
}
