import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class daftar_ruang extends StatefulWidget {
  @override
  _daftar_ruangState createState() => _daftar_ruangState();
}

class _daftar_ruangState extends State<daftar_ruang> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;
  DateTime? selectedDate; // Variable for selected date
  String searchQuery = ''; // Variable for search query
  String? selectedLocation; // Variable for selected location
  List<String> locations = []; // List to store unique locations

  @override
  void initState() {
    super.initState();
    _fetchLocations();
  }

  Future<void> _fetchLocations() async {
    QuerySnapshot snapshot = await firestore.collection('rooms').get();
    Set<String> locationSet = {};

    for (var doc in snapshot.docs) {
      locationSet.add(doc['location']);
    }

    setState(() {
      locations = locationSet.toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Data Ruangan'),
        automaticallyImplyLeading: false, // Remove back button
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Cari Ruangan',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Pilih Lokasi',
                border: OutlineInputBorder(),
              ),
              value: selectedLocation,
              items: locations.map((location) {
                return DropdownMenuItem<String>(
                  value: location,
                  child: Text(location),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedLocation = value;
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: firestore.collection('rooms').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                var rooms = snapshot.data!.docs.where((doc) {
                  var roomName = (doc['room_name'] as String).toLowerCase();
                  var roomLocation = (doc['location'] as String);
                  bool matchesSearchQuery = roomName.contains(searchQuery);
                  bool matchesLocation = selectedLocation == null || selectedLocation == roomLocation;
                  return matchesSearchQuery && matchesLocation;
                }).toList();

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
                                      key: PageStorageKey<String>(room.id), // Ensure unique keys
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
                              room['room_name'] ?? 'Nama Ruangan Tidak Tersedia',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text('Lokasi: ${room['location']}'),
                            Text('Detail Lokasi: ${room['location_detail']}'),
                            Text('Bidang: ${room['bidang']}'),
                            SizedBox(height: 8),
                            Text('Kapasitas: ${room['capacity']}'),
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
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showBookingDialog(BuildContext context, DocumentSnapshot room) async {
    final _formKey = GlobalKey<FormState>();
    String reason = '';
    String session = 'Sesi 1 (08.00 - 12.00)';
    String errorMessage = '';

    User? user = auth.currentUser;
    if (user == null) {
      return;
    }

    DocumentSnapshot userDoc = await firestore.collection('users').doc(user.uid).get();
    String userField = userDoc['bidang'];
    String userPhone = userDoc['phone'];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Pesan Ruangan'),
              content: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: ListBody(
                    children: <Widget>[
                      TextFormField(
                        decoration: InputDecoration(labelText: 'Alasan Meminjam'),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Alasan tidak boleh kosong';
                          }
                          return null;
                        },
                        onChanged: (value) {
                          reason = value;
                        },
                      ),
                      SizedBox(height: 16),
                      Text('Tanggal Pemesanan'),
                      TextFormField(
                        readOnly: true,
                        controller: TextEditingController(
                            text: selectedDate != null ? "${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}" : ""),
                        onTap: () async {
                          DateTime? pickedDate = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime.now(),
                              lastDate: DateTime(DateTime.now().year + 1));
                          if (pickedDate != null) {
                            setState(() {
                              selectedDate = pickedDate;
                            });
                          }
                        },
                      ),
                      SizedBox(height: 16),
                      Text('Pilih Sesi'),
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(labelText: 'Pilih Sesi'),
                        value: session,
                        items: [
                          DropdownMenuItem(
                            child: Text('Sesi 1 (08.00 - 12.00)'),
                            value: 'Sesi 1 (08.00 - 12.00)',
                          ),
                          DropdownMenuItem(
                            child: Text('Sesi 2 (12.30 - 16.00)'),
                            value: 'Sesi 2 (12.30 - 16.00)',
                          ),
                          DropdownMenuItem(
                            child: Text('Full day (08.00 - 16.00)'),
                            value: 'Full day (08.00 - 16.00)',
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            session = value!;
                            errorMessage = '';
                          });
                        },
                      ),
                      if (errorMessage.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            errorMessage,
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text('Batal'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: Text('Pesan'),
                  onPressed: () async {
                    // Check availability of booking for the selected date and session
                    bool isBookingAvailable = await _checkBookingAvailabilityForDateAndSession(room['room_name'], 'Sesi 1 (08.00 - 12.00)', selectedDate!);
                    bool isBookingAvailable2 = await _checkBookingAvailabilityForDateAndSession(room['room_name'], 'Sesi 2 (12.30 - 16.00)', selectedDate!);
                    bool isBookingAvailableFullDay = await _checkBookingAvailabilityForDateAndSession(room['room_name'], 'Full day (08.00 - 16.00)', selectedDate!);

                    if (!isBookingAvailable || !isBookingAvailable2 || !isBookingAvailableFullDay) {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text('Pemesanan Gagal'),
                            content: Text('Ruangan ini sudah dipesan .'),
                            actions: <Widget>[
                              TextButton(
                                child: Text('OK'),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                              ),
                            ],
                          );
                        },
                      );
                      return;
                    }

                    // Validate form
                    if (_formKey.currentState!.validate()) {
                      // Save booking to Firestore with status 'Request'
                      firestore.collection('bookings').add({
                        'room_name': room['room_name'],
                        'name': user.displayName,
                        'field': userField,
                        'phone': userPhone,
                        'session': session,
                        'reason': reason,
                        'booking_date': Timestamp.fromDate(selectedDate!), // Save as Timestamp
                        'status': 'Request', // Add booking status
                        'timestamp': FieldValue.serverTimestamp(),
                      });
                      Navigator.of(context).pop();
                    } else {
                      setState(() {
                        errorMessage = 'Silakan lengkapi semua data';
                      });
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<bool> _checkBookingAvailabilityForDateAndSession(String roomName, String session, DateTime selectedDate) async {
    // Convert date to Timestamp format
    Timestamp selectedTimestamp = Timestamp.fromDate(selectedDate);

    if (session == 'Full day (08.00 - 16.00)') {
      // Check if there is an accepted booking for the Full day session on the selected date
      QuerySnapshot fullDayBookingsSnapshot = await firestore
          .collection('bookings')
          .where('room_name', isEqualTo: roomName)
          .where('session', isEqualTo: 'Full day (08.00 - 16.00)')
          .where('booking_date', isEqualTo: selectedTimestamp)
          .where('status', isEqualTo: 'Accepted')
          .get();

      if (fullDayBookingsSnapshot.docs.isNotEmpty) {
        // If there is an accepted Full day booking, return false (not available for all sessions)
        return false;
      } else {
        // If there is no accepted Full day booking, check availability for other sessions
        QuerySnapshot otherSessionBookingsSnapshot = await firestore
            .collection('bookings')
            .where('room_name', isEqualTo: roomName)
            .where('booking_date', isEqualTo: selectedTimestamp)
            .where('status', isEqualTo: 'Accepted')
            .get();

        return otherSessionBookingsSnapshot.docs.isEmpty; // true if no accepted bookings for the selected session
      }
    } else {
      // If not Full day, check availability for the selected session
      QuerySnapshot bookingsSnapshot = await firestore
          .collection('bookings')
          .where('room_name', isEqualTo: roomName)
          .where('session', isEqualTo: session)
          .where('booking_date', isEqualTo: selectedTimestamp)
          .where('status', isEqualTo: 'Accepted')
          .get();

      return bookingsSnapshot.docs.isEmpty; // true if no accepted bookings for the selected session
    }
  }
}
