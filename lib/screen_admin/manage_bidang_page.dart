import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ManageBidangPage extends StatefulWidget {
  @override
  _ManageBidangPageState createState() => _ManageBidangPageState();
}

class _ManageBidangPageState extends State<ManageBidangPage> {
  List<Map<String, String>> bidangOptions = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchBidangOptions();
  }

  Future<void> _fetchBidangOptions() async {
    try {
      var snapshot = await FirebaseFirestore.instance.collection('bidang').get();
      var bidangList = snapshot.docs.map((doc) => {
        'id': doc.id,
        'name': doc['name'] as String
      }).toList();
      setState(() {
        bidangOptions = bidangList;
        isLoading = false;
      });
    } catch (e) {
      print(e.toString());
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _deleteBidang(String id) async {
    try {
      await FirebaseFirestore.instance.collection('bidang').doc(id).delete();
      setState(() {
        bidangOptions.removeWhere((element) => element['id'] == id);
      });
    } catch (e) {
      print(e.toString());
    }
  }

  Future<void> _editBidang(String id, String newBidang) async {
    try {
      await FirebaseFirestore.instance.collection('bidang').doc(id).update({
        'name': newBidang,
      });
      setState(() {
        int index = bidangOptions.indexWhere((element) => element['id'] == id);
        if (index != -1) {
          bidangOptions[index]['name'] = newBidang;
        }
      });
    } catch (e) {
      print(e.toString());
    }
  }

  void _showAddBidangDialog() {
    showDialog(
      context: context,
      builder: (context) {
        TextEditingController newBidangController = TextEditingController();
        return AlertDialog(
          title: Text("Tambah Bidang"),
          content: TextField(
            controller: newBidangController,
            decoration: InputDecoration(hintText: "Nama Bidang"),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                String newBidang = newBidangController.text;
                if (newBidang.isNotEmpty) {
                  try {
                    DocumentReference docRef = await FirebaseFirestore.instance.collection('bidang').add({
                      'name': newBidang,
                    });
                    setState(() {
                      bidangOptions.add({'id': docRef.id, 'name': newBidang});
                    });
                    Navigator.pop(context);
                  } catch (e) {
                    print(e.toString());
                  }
                }
              },
              child: Text("Simpan"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Batal"),
            ),
          ],
        );
      },
    );
  }

  void _showEditBidangDialog(String id, String oldBidang) {
    showDialog(
      context: context,
      builder: (context) {
        TextEditingController editBidangController = TextEditingController();
        editBidangController.text = oldBidang;
        return AlertDialog(
          title: Text("Edit Bidang"),
          content: TextField(
            controller: editBidangController,
            decoration: InputDecoration(hintText: "Nama Bidang"),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                String newBidang = editBidangController.text;
                if (newBidang.isNotEmpty && newBidang != oldBidang) {
                  await _editBidang(id, newBidang);
                  Navigator.pop(context);
                }
              },
              child: Text("Simpan"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Batal"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Kelola Bidang"),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: bidangOptions.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(bidangOptions[index]['name']!),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _showEditBidangDialog(bidangOptions[index]['id']!, bidangOptions[index]['name']!),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteBidang(bidangOptions[index]['id']!),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _showAddBidangDialog,
                  child: Text("Tambah Bidang"),
                ),
              ],
            ),
    );
  }
}
