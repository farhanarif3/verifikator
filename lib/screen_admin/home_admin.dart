import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ta/screen_admin/Booking.dart';
import 'package:ta/screen_admin/DashAdmin.dart';
import 'package:ta/screen_admin/DataRuang.dart';
import 'package:ta/screen_admin/Kalender.dart';
import 'package:ta/screen_admin/Register.dart';
import 'package:ta/screen_guest/home_guest.dart';


class HomeAdmin extends StatefulWidget {
  @override
  _HomeAdminState createState() => _HomeAdminState();
}

class _HomeAdminState extends State<HomeAdmin> {
  int _selectedIndex = 0;

  static final List<Widget> _widgetOptions = <Widget>[
    DashAdmin(),
    Kalender(),
    Booking(),
    DataRuang(),
    Register(),
  ];

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _logout() async {
    await _auth.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => HomeGuest()), // Arahkan ke HomeGuest
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Konfirmasi Logout'),
          content: Text('Apakah Anda yakin ingin logout?'),
          actions: <Widget>[
            TextButton(
              child: Text('Batal'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Logout'),
              onPressed: () async {
                Navigator.of(context).pop();
                await _logout();
              },
            ),
          ],
        );
      },
    );
  }

  void _showProfileDialog() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot userData =
          await _firestore.collection('users').doc(user.uid).get();

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: Text('Detail Akun'),
                content: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text('Nama: ${userData['username']}'),
                      Text('Email: ${userData['email']}'),
                      Text('Telepon: ${userData['phone']}'),
                      Text('Bidang: ${userData['bidang']}'),
                      SizedBox(height: 16),
                      Text('Ganti Password:',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      TextFormField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          labelText: 'Password Baru',
                          suffixIcon: IconButton(
                            icon: Icon(Icons.visibility),
                            onPressed: () {
                              setState(() {
                                _passwordController.clear();
                              });
                            },
                          ),
                        ),
                        obscureText: true,
                      ),
                      TextFormField(
                        controller: _confirmPasswordController,
                        decoration: InputDecoration(
                          labelText: 'Konfirmasi Password',
                          suffixIcon: IconButton(
                            icon: Icon(Icons.visibility),
                            onPressed: () {
                              setState(() {
                                _confirmPasswordController.clear();
                              });
                            },
                          ),
                        ),
                        obscureText: true,
                      ),
                    ],
                  ),
                ),
                actions: <Widget>[
                  TextButton(
                    child: Text('Tutup'),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                  TextButton(
                    child: Text('Simpan'),
                    onPressed: () {
                      _changePassword();
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              );
            },
          );
        },
      );
    } else {
      // Handle the case where user is not logged in
      print('User not logged in');
    }
  }

  Future<void> _changePassword() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        if (_passwordController.text == _confirmPasswordController.text) {
          await user.updatePassword(_passwordController.text);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Password changed successfully')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Passwords do not match')),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to change password: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Image.asset(
              'lib/assets/logosplash.png',
              fit: BoxFit.contain,
              height: 32,
            ),
            Container(
              padding: const EdgeInsets.only(left: 8.0),
              child: Text('LAYANAN RESERVASI'),
            ),
          ],
        ),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.account_circle),
            onPressed: _showProfileDialog,
          ),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _showLogoutDialog,
          ),
        ],
      ),
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      backgroundColor: Colors.grey[200],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.black,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Dashboard',
            backgroundColor: Colors.white,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month),
            label: 'Kalender',
            backgroundColor: Colors.white,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book),
            label: 'Booking',
            backgroundColor: Colors.white,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_home_work),
            label: 'Manajemen Ruang',
            backgroundColor: Colors.white,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_add),
            label: 'Register',
            backgroundColor: Colors.white,
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ),
    );
  }
}
