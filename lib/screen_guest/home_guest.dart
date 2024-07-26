import 'package:flutter/material.dart';
import 'package:ta/screen_guest/daftar_ruang.dart';
import 'package:ta/screen_guest/datareservasi.dart';
import 'package:ta/LoginAll.dart';

class HomeGuest extends StatefulWidget {
  @override
  _HomeGuestState createState() => _HomeGuestState();
}

class _HomeGuestState extends State<HomeGuest> {
  int _selectedIndex = 0;

  static List<Widget> _widgetOptions = <Widget>[
    daftar_ruang(), // Make sure the name and import are correct
    datareservasi(), // Make sure the name and import are correct
    LoginPage(), // Make sure the name and import are correct
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // Remove back button
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
      ),
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      backgroundColor: Colors.grey[200],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Daftar Ruang',
            backgroundColor: Colors.white,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month),
            label: 'Kalender',
            backgroundColor: Colors.white,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.login),
            label: 'Login',
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
