import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';



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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Data Ruangan'),
      ),
      body: Center(
        child: Text('Data Ruangan Screen'),
      ),
    );
  }
}

class EditDataRuang extends StatefulWidget {
  final String roomId;

  const EditDataRuang({Key? key, required this.roomId}) : super(key: key);

  @override
  _EditDataRuangState createState() => _EditDataRuangState();
}

class _EditDataRuangState extends State<EditDataRuang> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController capacityController = TextEditingController();
  final TextEditingController areaController = TextEditingController();
  final TextEditingController locationDetailController = TextEditingController();

  String? _selectedLocation;
  String? _selectedBidang;
  List<String> _locations = [];
  List<String> _bidang = [];
  List<File> _imageFiles = [];
  List<String> _imageUrls = [];
  List<Facility> _facilities = [];


  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _loadRoomData();
    _fetchLocations();
    _fetchBidang();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _getUserBidang() async {
  try {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot userSnapshot =
          await firestore.collection('users').doc(user.uid).get();
      if (userSnapshot.exists) {
        setState(() {
          _selectedBidang = userSnapshot['bidang'];
        });
      } else {
        throw 'Dokumen pengguna tidak ditemukan';
      }
    }
  } catch (e) {
    print('Error fetching user bidang: $e');
  }
}

  void _loadRoomData() async {
    try {
      DocumentSnapshot roomSnapshot =
          await firestore.collection('rooms').doc(widget.roomId).get();

      if (roomSnapshot.exists) {
        setState(() {
          nameController.text = roomSnapshot['room_name'] ?? '';
          capacityController.text = (roomSnapshot['capacity'] ?? 0).toString();
          areaController.text = (roomSnapshot['area'] ?? 0).toString();
          _selectedLocation = roomSnapshot['location'];
          locationDetailController.text = roomSnapshot['location_detail'] ?? '';
          _selectedBidang = roomSnapshot['bidang'];

          _facilities.clear();
          if (roomSnapshot['facilities'] != null) {
            List<dynamic> facilities = roomSnapshot['facilities'];
            for (var facility in facilities) {
              _facilities.add(Facility(
                name: facility['name'],
                quantity: facility['quantity'],
              ));
            }
          }

          _imageFiles.clear();
          _imageUrls.clear();
          if (roomSnapshot['images'] != null) {
            List<dynamic> images = roomSnapshot['images'];
            for (var imageUrl in images) {
              if (imageUrl is String && imageUrl.isNotEmpty) {
                _imageUrls.add(imageUrl);
              }
            }
          }
        });
      } else {
        throw 'Dokumen ruangan tidak ditemukan';
      }
    } catch (e) {
      print('Error loading room data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memuat data ruangan: $e'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _fetchLocations() async {
    try {
      final snapshot = await firestore.collection('locations').get();
      final locations = snapshot.docs.map((doc) => doc['name'] as String).toList();
      setState(() {
        _locations = locations;
      });
    } catch (e) {
      print('Error fetching locations: $e');
    }
  }
  Future<void> _fetchBidang() async {
    try {
      final snapshot = await firestore.collection('bidang').get();
      final bidang = snapshot.docs.map((doc) => doc['name'] as String).toList();
      setState(() {
        _bidang = bidang;
      });
    } catch (e) {
      print('Error fetching locations: $e');
    }
  }

  Future<void> _updateRoom() async {
    try {
      List<String> imageUrls = [];

      for (var file in _imageFiles) {
        if (file.path.isNotEmpty) {
          firebase_storage.Reference ref =
              firebase_storage.FirebaseStorage.instance
                  .ref()
                  .child('room_images')
                  .child('${DateTime.now().millisecondsSinceEpoch}');
          await ref.putFile(file);
          String imageUrl = await ref.getDownloadURL();
          imageUrls.add(imageUrl);
        }
      }

      imageUrls.addAll(_imageUrls);

      await firestore.collection('rooms').doc(widget.roomId).update({
        'room_name': nameController.text,
        'facilities': _facilities
            .map((facility) => {
                  'name': facility.name,
                  'quantity': facility.quantity,
                })
            .toList(),
        'capacity': int.parse(capacityController.text),
        'area': int.parse(areaController.text),
        'images': imageUrls,
        'location': _selectedLocation,
        'location_detail': locationDetailController.text,
        'bidang' : _selectedBidang,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ruangan berhasil diperbarui'),
          duration: Duration(seconds: 2),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      print('Error updating room: $e');
      String errorMessage = 'Gagal memperbarui ruangan';
      if (e is firebase_storage.FirebaseException) {
        errorMessage = 'Gagal mengunggah gambar: ${e.message}';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile>? pickedFiles =
          await ImagePicker().pickMultiImage();

      if (pickedFiles != null) {
        setState(() {
          _imageFiles =
              pickedFiles.map((file) => File(file.path)).toList();
        });
      }
    } catch (e) {
      print(e.toString());
    }
  }

  void _addFacility(String name, int quantity) {
    setState(() {
      _facilities.add(Facility(
        name: name,
        quantity: quantity,
      ));
    });
  }

  void _removeFacility(int index) {
    setState(() {
      _facilities.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Data Ruangan'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Nama Ruangan',
              ),
            ),
            TextFormField(
              controller: capacityController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Kapasitas',
              ),
            ),
            TextFormField(
              controller: areaController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Luas Ruangan (m²)',
              ),
            ),
            SizedBox(height: 16.0),

            // Dropdown untuk Lokasi
            DropdownButtonFormField<String>(
              value: _selectedLocation,
              decoration: InputDecoration(
                labelText: 'Lokasi',
              ),
              items: _locations.map((location) {
                return DropdownMenuItem<String>(
                  value: location,
                  child: Text(location),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  _selectedLocation = newValue;
                });
              },
            ),

            TextFormField(
              controller: locationDetailController,
              decoration: InputDecoration(
                labelText: 'Detail Lokasi',
              ),
            ),
            SizedBox(height: 16.0),

            SizedBox(height: 16.0),

            DropdownButtonFormField<String>(
  value: _selectedBidang,
  decoration: InputDecoration(
    labelText: 'Bidang',
  ),
  items: [_selectedBidang].map((bidang) {
    return DropdownMenuItem<String>(
      value: bidang,
      child: Text(bidang ?? ''),
    );
  }).toList(),
  onChanged: (newValue) {
    setState(() {
      _selectedBidang = newValue;
    });
  },
),


            // Pilih Gambar
            ElevatedButton(
              onPressed: _pickImages,
              child: Text('Pilih Gambar'),
            ),
            SizedBox(height: 16.0),

            // Galeri Gambar dengan Smooth Page Indicator
            Stack(
              children: [
                Container(
                  height: 200,
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _imageUrls.length + _imageFiles.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: EdgeInsets.only(right: 8.0),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8.0),
                              child: index < _imageUrls.length
                                  ? Image.network(
                                      _imageUrls[index],
                                      width: double.infinity,
                                      height: double.infinity,
                                      fit: BoxFit.cover,
                                    )
                                  : Image.file(
                                      _imageFiles[index - _imageUrls.length],
                                      width: double.infinity,
                                      height: double.infinity,
                                      fit: BoxFit.cover,
                                    ),
                            ),
                            Positioned(
                              top: 8.0,
                              right: 8.0,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    if (index < _imageUrls.length) {
                                      _imageUrls.removeAt(index);
                                    } else {
                                      _imageFiles
                                          .removeAt(index - _imageUrls.length);
                                    }
                                    _pageController.jumpToPage(0); // Reset page view to first page
                                  });
                                },
                                child: Container(
                                  padding: EdgeInsets.all(4.0),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.black54,
                                  ),
                                  child: Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 16.0,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // Smooth Page Indicator
                Positioned(
                  bottom: 10.0,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: SmoothPageIndicator(
                      controller: _pageController,
                      count: _imageUrls.length + _imageFiles.length,
                      effect: WormEffect(
                        dotHeight: 8,
                        dotWidth: 8,
                      ), // Efek untuk indikator (dots)
                      onDotClicked: (index) => _pageController.animateToPage(
                        index,
                        duration: Duration(milliseconds: 500),
                        curve: Curves.ease,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 16.0),

            // Fasilitas
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Fasilitas:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8.0),
                ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: _facilities.length,
                  itemBuilder: (context, index) {
                    return Row(
                      children: [
                        Expanded(
                          child: Text(
                            _facilities[index].name,
                            style: TextStyle(
                              fontSize: 16.0,
                            ),
                          ),
                        ),
                        SizedBox(width: 8.0),
                        Expanded(
                          child: TextFormField(
                            initialValue: _facilities[index].quantity.toString(),
                            onChanged: (value) {
                              setState(() {
                                _facilities[index].quantity = int.parse(value);
                              });
                            },
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Jumlah Fasilitas',
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                SizedBox(height: 8.0),
                ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) {
                        TextEditingController facilityNameController = TextEditingController();
                        TextEditingController facilityQuantityController = TextEditingController();

                        return AlertDialog(
                          title: Text('Tambah Fasilitas'),
                          content: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextField(
                                  controller: facilityNameController,
                                  decoration: InputDecoration(
                                    labelText: 'Nama Fasilitas',
                                  ),
                                ),
                                TextField(
                                  controller: facilityQuantityController,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    labelText: 'Jumlah Fasilitas',
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    _addFacility(
                                      facilityNameController.text,
                                      int.parse(facilityQuantityController.text),
                                    );
                                    setState(() {
                                      facilityNameController.clear();
                                      facilityQuantityController.clear();
                                    });
                                    Navigator.pop(context);
                                  },
                                  child: Text('Tambah'),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                  child: Text('Tambah Fasilitas'),
                ),
              ],
            ),

            SizedBox(height: 16.0),

            // Tombol Simpan Perubahan
            ElevatedButton(
              onPressed: _updateRoom,
              child: Text('Simpan Perubahan'),
            ),
          ],
        ),
      ),
    );
  }
}

class Facility {
  String name;
  int quantity;

  Facility({required this.name, required this.quantity});
}
