import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AccountManagementPage extends StatefulWidget {
  @override
  _AccountManagementPageState createState() => _AccountManagementPageState();
}

class _AccountManagementPageState extends State<AccountManagementPage> {
  List<DocumentSnapshot> users = [];

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  void _fetchUsers() async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('users').get();
    setState(() {
      users = snapshot.docs;
    });
  }

  void _deleteUser(String userId) async {
    await FirebaseFirestore.instance.collection('users').doc(userId).delete();
    _fetchUsers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Account Management'),
      ),
      body: ListView.builder(
        itemCount: users.length,
        itemBuilder: (context, index) {
          var user = users[index];
          return ListTile(
            title: Text(user['username']),
            subtitle: Text('Role: ${user['role']} - Bidang: ${user['bidang']}'),
            trailing: IconButton(
              icon: Icon(Icons.delete),
              onPressed: () => _deleteUser(user.id),
            ),
          );
        },
      ),
    );
  }
}
