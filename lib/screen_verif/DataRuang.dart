import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:image_picker/image_picker.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:ta/screen_verif/EditDataRuang.dart';
import 'package:ta/screen_verif/TambahDataRuang.dart';

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: DataRuang(),
  ));
}

class DataRuang extends StatefulWidget {
  @override
  _DataRuangState createState() => _DataRuangState();
}

class _DataRuangState extends State<DataRuang> {
  final TextEditingController room_nameController = TextEditingController();
  final TextEditingController capacityController = TextEditingController();
  final TextEditingController areaController = TextEditingController();

  List<File> _imageFiles = [];
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  List<Facility> _facilities = [];
  DocumentSnapshot? _selectedRoom;
  String _searchQuery = '';
  String? userBidang;

  @override
  void initState() {
    super.initState();
    _getCurrentUserBidang();
  }

  Future<void> _getCurrentUserBidang() async {
    try {
      final User? user = _auth.currentUser;
      if (user != null) {
        final DocumentSnapshot userDoc =
            await firestore.collection('users').doc(user.uid).get();
        setState(() {
          userBidang = userDoc['bidang'];
        });
      }
    } catch (e) {
      print('Error fetching user bidang: $e');
    }
  }

  void _addRoom() async {
    try {
      List<String> imageUrls = [];

      // Upload all selected images to Firebase Storage
      for (var file in _imageFiles) {
        firebase_storage.Reference ref = firebase_storage.FirebaseStorage.instance
            .ref()
            .child('room_images')
            .child('${DateTime.now().millisecondsSinceEpoch}');
        await ref.putFile(file);
        String imageUrl = await ref.getDownloadURL();
        imageUrls.add(imageUrl);
      }

      await firestore.collection('rooms').add({
        'room_name': room_nameController.text,
        'facilities': _facilities.map((facility) => {
          'name': facility.name,
          'quantity': facility.quantity,
        }).toList(),
        'capacity': int.parse(capacityController.text),
        'area': int.parse(areaController.text),
        'images': imageUrls,
      });

      _clearControllers();
      setState(() {
        _imageFiles.clear();
        _facilities.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Ruangan berhasil ditambahkan'),
        duration: Duration(seconds: 2),
      ));
    } catch (e) {
      print('Error adding room: $e');
      String errorMessage = 'Gagal menambahkan ruangan';
      if (e is firebase_storage.FirebaseException) {
        errorMessage = 'Gagal mengunggah gambar: ${e.message}';
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(errorMessage),
        duration: Duration(seconds: 2),
      ));
    }
  }

  void _clearControllers() {
    room_nameController.clear();
    capacityController.clear();
    areaController.clear();
    // Do not clear _facilities here to maintain data when adding/editing room
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile>? pickedFiles = await ImagePicker().pickMultiImage();

      if (pickedFiles != null) {
        setState(() {
          _imageFiles = pickedFiles.map((file) => File(file.path)).toList();
        });
      }
    } on Exception catch (e) {
      print(e.toString());
    }
  }

  void _addFacility(TextEditingController facilityNameController, TextEditingController facilityQuantityController) {
    setState(() {
      _facilities.add(Facility(
        name: facilityNameController.text,
        quantity: int.parse(facilityQuantityController.text),
      ));
      // Clear text controllers after adding facility
      facilityNameController.clear();
      facilityQuantityController.clear();
    });
  }

  void _removeFacility(Facility facility) {
    setState(() {
      _facilities.remove(facility);
    });
  }

  void _editRoom(DocumentSnapshot room) {
    setState(() {
      _selectedRoom = room;
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditDataRuang(roomId: room.id),
      ),
    );
  }

  void _updateRoom() async {
    try {
      List<String> imageUrls = [];

      // Upload new images to Firebase Storage if any
      for (var file in _imageFiles) {
        if (file is File) {
          firebase_storage.Reference ref = firebase_storage.FirebaseStorage.instance
              .ref()
              .child('room_images')
              .child('${DateTime.now().millisecondsSinceEpoch}');
          await ref.putFile(file);
          String imageUrl = await ref.getDownloadURL();
          imageUrls.add(imageUrl);
        }
      }

      // Update room data in Firestore
      await _selectedRoom!.reference.update({
        'room_name': room_nameController.text,
        'facilities': _facilities.map((facility) => {
          'name': facility.name,
          'quantity': facility.quantity,
        }).toList(),
        'capacity': int.parse(capacityController.text),
        'area': int.parse(areaController.text),
        'images': imageUrls.isNotEmpty ? imageUrls : _selectedRoom!['images'],
      });

      _clearControllers();
      setState(() {
        _imageFiles.clear();
        _facilities.clear();
        _selectedRoom = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Ruangan berhasil diperbarui'),
        duration: Duration(seconds: 2),
      ));
    } catch (e) {
      print('Error updating room: $e');
      String errorMessage = 'Gagal memperbarui ruangan';
      if (e is firebase_storage.FirebaseException) {
        errorMessage = 'Gagal mengunggah gambar: ${e.message}';
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(errorMessage),
        duration: Duration(seconds: 2),
      ));
    }
  }

  void _deleteRoom(String roomId) async {
    try {
      await firestore.collection('rooms').doc(roomId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ruangan berhasil dihapus'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menghapus ruangan'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _confirmDeleteRoom(String roomId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Konfirmasi Hapus'),
          content: Text('Apakah Anda yakin ingin menghapus ruangan ini?'),
          actions: <Widget>[
            TextButton(
              child: Text('Batal'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Hapus'),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteRoom(roomId);
              },
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
        title: Text('Data Ruangan'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(Icons.add_circle),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => TambahDataRuang()),
              );
            },
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Cari ruangan...',
                  border: InputBorder.none,
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
              ),
            ),
          ),
          
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: firestore.collection('rooms')
        .where('bidang', isEqualTo: userBidang)
        .orderBy('room_name')
        .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          var rooms = snapshot.data!.docs.where((room) =>
            room['room_name'].toString().toLowerCase().contains(_searchQuery)
          ).toList();

          return ListView.builder(
            itemCount: rooms.length,
            itemBuilder: (context, index) {
              var room = rooms[index];

              List<dynamic> images = (room.data() as Map<String, dynamic>?)?['images'] ?? [];
              List<dynamic> facilities = (room.data() as Map<String, dynamic>?)?['facilities'] ?? [];

              PageController pageController = PageController();

              return Card(
                elevation: 3,
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (images.isNotEmpty)
                        Column(
                          children: [
                            Container(
                              height: 200,
                              child: PageView.builder(
                                controller: pageController,
                                itemCount: images.length,
                                itemBuilder: (context, imgIndex) {
                                  return Padding(
                                    padding: EdgeInsets.only(right: 8.0),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8.0),
                                      child: Image.network(
                                        images[imgIndex],
                                        width: double.infinity,
                                        height: 200,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            SizedBox(height: 8),
                            SmoothPageIndicator(
                              controller: pageController,
                              count: images.length,
                              effect: WormEffect(
                                dotHeight: 8,
                                dotWidth: 8,
                                activeDotColor: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                      SizedBox(height: 16),
                      Text(
                        room['room_name'],
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                    Text('Lokasi: ${room['location']}'),
                    Text('Detail Lokasi: ${room['location_detail']}'),
                    Text('Bidang: ${room['bidang']}'),
                      SizedBox(height: 8),
                      Text('Kapasitas: ${room['capacity']} orang'),
                      Text('Luas: ${room['area']} m²'),
                      SizedBox(height: 8),
                      Text(
                        'Fasilitas:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      for (var facility in facilities)
                        Text('${facility['name']} (${facility['quantity']})'),
                      SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit),
                            onPressed: () {
                              _editRoom(room);
                            },
                          ),
                          IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: () {
                              _confirmDeleteRoom(room.id);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class Facility {
  String name;
  int quantity;

  Facility({required this.name, required this.quantity});
}
