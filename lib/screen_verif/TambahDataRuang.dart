import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class TambahDataRuang extends StatefulWidget {
  @override
  _TambahDataRuangState createState() => _TambahDataRuangState();
}

class _TambahDataRuangState extends State<TambahDataRuang> {
  final TextEditingController room_nameController = TextEditingController();
  final TextEditingController capacityController = TextEditingController();
  final TextEditingController areaController = TextEditingController();
  final TextEditingController locationDetailController = TextEditingController();

  List<File> _imageFiles = [];
  List<Facility> _facilities = [
    Facility(name: 'Kursi', quantity: null),
    Facility(name: 'Meja', quantity: null),
    Facility(name: 'AC', quantity: null),
    Facility(name: 'LCD', quantity: null),
    Facility(name: 'Proyektor', quantity: null),
    Facility(name: 'Sound', quantity: null),
    Facility(name: 'Papan Tulis', quantity: null),
  ];

  List<String> _locations = [];
  String? _selectedLocation;
  List<String> _bidang = [];
  String? _selectedBidang;

  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _fetchLocations();
    _fetchBidang();
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
  Future<void> _fetchLocations() async {
    try {
      final snapshot = await firestore.collection('locations').get();
      final locations = snapshot.docs.map((doc) => doc['name'] as String).toList();
      setState(() {
        _locations = locations;
        if (_locations.isNotEmpty) {
          _selectedLocation = _locations.first;
        }
      });
    } catch (e) {
      print('Error fetching locations: $e');
    }
  }
  Future<void> _fetchBidang() async {
  try {
    // Ambil bidang pengguna saat ini
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot userSnapshot = await firestore.collection('users').doc(user.uid).get();
      if (userSnapshot.exists) {
        String userBidang = userSnapshot['bidang'];

        // Ambil bidang yang sama dengan bidang pengguna
        final snapshot = await firestore.collection('bidang').where('name', isEqualTo: userBidang).get();
        final bidang = snapshot.docs.map((doc) => doc['name'] as String).toList();
        setState(() {
          _bidang = bidang;
          if (_bidang.isNotEmpty) {
            _selectedBidang = _bidang.first;
          }
        });
      } else {
        throw 'Dokumen pengguna tidak ditemukan';
      }
    }
  } catch (e) {
    print('Error fetching bidang: $e');
  }
}

  Future<void> _addRoom() async {
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

    // Add room data to Firestore
    await firestore.collection('rooms').add({
      'room_name': room_nameController.text,
      'facilities': _facilities
          .map((facility) => {
                'name': facility.name,
                'quantity': facility.quantity ?? 0, // Use 0 if quantity is null
              })
          .toList(),
      'capacity': int.parse(capacityController.text),
      'area': int.parse(areaController.text),
      'images': imageUrls,
      'location': _selectedLocation,
      'bidang' : _selectedBidang,
      'location_detail': locationDetailController.text, // Add location detail
    });

    // Clear controllers and facilities list
    _clearControllers();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Ruangan berhasil ditambahkan'),
        duration: Duration(seconds: 2),
      ),
    );

    // Navigate back to previous screen (DataRuang.dart)
    Navigator.pop(context); // Kembali ke halaman sebelumnya
  } catch (e) {
    print('Error adding room: $e');
    String errorMessage = 'Gagal menambahkan ruangan';
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


  void _clearControllers() {
    room_nameController.clear();
    capacityController.clear();
    areaController.clear();
    locationDetailController.clear(); // Clear location detail
    _facilities = [
      Facility(name: 'Kursi', quantity: null),
      Facility(name: 'Meja', quantity: null),
      Facility(name: 'AC', quantity: null),
      Facility(name: 'LCD', quantity: null),
      Facility(name: 'Proyektor', quantity: null),
      Facility(name: 'Sound', quantity: null),
      Facility(name: 'Papan Tulis', quantity: null),
    ];
    _imageFiles.clear();
    _selectedLocation = _locations.isNotEmpty ? _locations.first : null;
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile>? pickedFiles = await ImagePicker().pickMultiImage();

      if (pickedFiles != null) {
        setState(() {
          _imageFiles = pickedFiles.map((file) => File(file.path)).toList();
          _currentIndex = 0; // Reset index to show first image
        });
      }
    } catch (e) {
      print(e.toString());
    }
  }

  void _addFacility(String name, int? quantity) {
    setState(() {
      _facilities.add(Facility(
        name: name,
        quantity: quantity,
      ));
    });
  }

  void _removeFacility(Facility facility) {
    setState(() {
      _facilities.remove(facility);
    });
  }

  void _removeImage(int index) {
    setState(() {
      _imageFiles.removeAt(index);
      if (_currentIndex >= _imageFiles.length && _currentIndex > 0) {
        _currentIndex--;
      }
    });
  }

  void _addLocation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final TextEditingController locationNameController = TextEditingController();
        final TextEditingController locationDetailController = TextEditingController();

        return AlertDialog(
          title: Text('Tambah Lokasi Baru'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: locationNameController,
                decoration: InputDecoration(labelText: 'Nama Lokasi'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newLocation = locationNameController.text.trim();
                if (newLocation.isNotEmpty) {
                  try {
                    await firestore.collection('locations').add({
                      'name': newLocation,
                    });
                    setState(() {
                      _fetchLocations(); // Refresh locations
                      _selectedLocation = newLocation;
                    });
                    Navigator.of(context).pop();
                  } catch (e) {
                    print('Error adding location: $e');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Gagal menambahkan lokasi'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                }
              },
              child: Text('Simpan'),
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
        title: Text('Tambah Data Ruangan'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: room_nameController,
              decoration: InputDecoration(
                labelText: 'Nama Ruangan',
              ),
            ),
            TextFormField(
              controller: capacityController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Kapasitas Orang',
                suffixText: 'orang',
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


            TextButton.icon(
              onPressed: _pickImages,
              icon: Icon(Icons.add_a_photo),
              label: Text('Pilih Gambar'),
            ),
            _imageFiles.isEmpty
                ? Container()
                : Column(
                    children: [
                      Container(
                        height: 200, // Set height of image container
                        child: PageView.builder(
                          itemCount: _imageFiles.length,
                          controller: PageController(
                            initialPage: _currentIndex,
                          ),
                          onPageChanged: (index) {
                            setState(() {
                              _currentIndex = index;
                            });
                          },
                          itemBuilder: (context, index) {
                            return Stack(
                              children: [
                                Padding(
                                  padding: EdgeInsets.only(right: 8.0),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8.0),
                                    child: Image.file(
                                      _imageFiles[index],
                                      width: double.infinity,
                                      fit: BoxFit.cover, // Ensure the image covers the container
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: GestureDetector(
                                    onTap: () {
                                      _removeImage(index);
                                    },
                                    child: Container(
                                      padding: EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.black54,
                                      ),
                                      child: Icon(
                                        Icons.close,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      SizedBox(height: 10),
                      SmoothPageIndicator(
                        controller: PageController(initialPage: _currentIndex),
                        count: _imageFiles.length,
                        effect: WormEffect(
                          dotHeight: 8,
                          dotWidth: 8,
                          activeDotColor: Colors.blue,
                        ),
                      ),
                    ],
                  ),
            SizedBox(height: 16.0),
            Text('Fasilitas:', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8.0),
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: _facilities.length,
              itemBuilder: (context, index) {
                return Row(
                  children: [
                    Expanded(
                      child: Text(_facilities[index].name),
                    ),
                    SizedBox(width: 16.0),
                    Expanded(
                      child: TextFormField(
                        initialValue: _facilities[index].quantity?.toString() ?? '',
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Jumlah',
                          hintText: '0', // Set placeholder here
                        ),
                        onChanged: (value) {
                          setState(() {
                            if (value.isEmpty) {
                              _facilities[index].quantity = null; // Set to null if empty
                            } else {
                              _facilities[index].quantity = int.parse(value);
                            }
                          });
                        },
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
                  builder: (BuildContext context) {
                    final TextEditingController facilityNameController = TextEditingController();
                    final TextEditingController facilityQuantityController = TextEditingController();

                    return AlertDialog(
                      title: Text('Tambah Fasilitas Lain'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextFormField(
                            controller: facilityNameController,
                            decoration: InputDecoration(labelText: 'Nama Fasilitas'),
                          ),
                          TextFormField(
                            controller: facilityQuantityController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Jumlah',
                              hintText: '0', // Set placeholder here
                            ),
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: Text('Batal'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _addFacility(
                                facilityNameController.text,
                                int.tryParse(facilityQuantityController.text),
                              );
                              Navigator.of(context).pop();
                            });
                          },
                          child: Text('Simpan'),
                        ),
                      ],
                    );
                  },
                );
              },
              child: Text('Tambah Fasilitas Lain'),
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: _addLocation,
              child: Text('Tambah Lokasi Baru'),
            ),
            SizedBox(height: 16.0),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: _addRoom,
                child: Text('Tambah Ruangan'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Facility {
  String name;
  int? quantity;

  Facility({required this.name, required this.quantity});
}
