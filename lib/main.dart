import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ta/screen_guest/home_guest.dart';
import 'package:ta/screen_user/home_user.dart';
import 'package:ta/screen_verif/home_verif.dart';
import 'package:ta/screen_admin/home_admin.dart';
import 'package:ta/LoginAll.dart';  // Pastikan Anda memiliki file ini

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  initializeDateFormatting('id', null).then((_) {
    runApp(MyApp());
  });
}



class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RESERVASI DISKOMINFO',
      theme: ThemeData(
        primaryColor: const Color.fromARGB(255, 255, 255, 255),
        scaffoldBackgroundColor: Colors.white,
      ),
      home: AuthWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        } else if (snapshot.hasData) {
          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('users')
                .doc(snapshot.data?.uid)
                .get(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return CircularProgressIndicator();
              } else if (snapshot.hasData && snapshot.data!.exists) {
                String userRole = snapshot.data!['role'];
                switch (userRole) {
                  case 'Admin':
                    return HomeAdmin();
                  case 'Verifikator':
                    return VerifPage();
                  case 'User':
                    return HomeUser();
                  default:
                    return HomeGuest();
                }
              } else {
                return HomeGuest();
              }
            },
          );
        } else {
          return HomeGuest();
        }
      },
    );
  }
}
