import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Agenda extends StatefulWidget {
  const Agenda({Key? key}) : super(key: key);

  @override
  _AgendaState createState() => _AgendaState();
}

class _AgendaState extends State<Agenda> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  Map<DateTime, List<dynamic>> _acceptedBookings = {};
  Set<DateTime> _selectedDates = {};
  String? selectedRoom;
  List<String> roomNames = [];

  Future<void> fetchRooms() async {
    try {
      QuerySnapshot querySnapshot =
          await FirebaseFirestore.instance.collection('rooms').get();

      List<String> rooms = [];
      for (var doc in querySnapshot.docs) {
        String roomName = doc['room_name'];
        rooms.add(roomName);
      }

      setState(() {
        roomNames = rooms;
        selectedRoom = roomNames.isNotEmpty ? roomNames.first : null;
        if (selectedRoom != null) {
          _fetchReservationsStream(selectedRoom!).listen((event) {
            setState(() {
              _acceptedBookings = event;
            });
          });
        }
      });
    } catch (e) {
      print('Error fetching rooms: $e');
    }
  }

  Stream<Map<DateTime, List<dynamic>>> _fetchReservationsStream(String room) {
    return FirebaseFirestore.instance
        .collection('bookings')
        .where('room_name', isEqualTo: room)
        .snapshots()
        .map((snapshot) {
      Map<DateTime, List<dynamic>> acceptedBookings = {};
      for (var doc in snapshot.docs) {
        DateTime date = (doc['booking_date'] as Timestamp).toDate();
        DateTime dateOnly = DateTime(date.year, date.month, date.day);
        if (acceptedBookings.containsKey(dateOnly)) {
          acceptedBookings[dateOnly]!.add(doc.data());
        } else {
          acceptedBookings[dateOnly] = [doc.data()];
        }
      }
      return acceptedBookings;
    });
  }

  @override
  void initState() {
    super.initState();
    fetchRooms();
  }

  Color getColorForDate(DateTime date) {
    DateTime dateOnly = DateTime(date.year, date.month, date.day);
    if (_selectedDates.contains(dateOnly)) {
      return Colors.purple;
    }

    List<dynamic>? bookings = _acceptedBookings[dateOnly];

    if (bookings != null && bookings.isNotEmpty) {
      bool sesi1Accepted = false;
      bool sesi2Accepted = false;
      bool sesi3Accepted = false;
      bool isMaintenance = false;

      for (var booking in bookings) {
        String status = booking['status'];
        String session = booking['session'] ?? '';

        if (status == 'Maintenance') {
          isMaintenance = true;
          break;
        }

        if (session == 'Sesi 1 (08.00 - 12.00)') {
          sesi1Accepted = true;
        } else if (session == 'Sesi 2 (12.30 - 16.00)') {
          sesi2Accepted = true;
        } else if (session == 'Full day (08.00 - 16.00)') {
          sesi3Accepted = true;
        }
      }

      if (isMaintenance) {
        return Colors.purple;
      } else if (sesi3Accepted || (sesi1Accepted && sesi2Accepted)) {
        return Colors.red;
      } else if (sesi1Accepted || sesi2Accepted) {
        return Colors.yellow;
      }
    }

    return Colors.green;
  }

  void _submitUnavailableReason() {
    if (selectedRoom != null) {
      for (DateTime date in _selectedDates) {
        FirebaseFirestore.instance.collection('bookings').add({
          'room_name': selectedRoom,
          'booking_date': Timestamp.fromDate(date),
          'status': 'Maintenance',
          'timestamp': FieldValue.serverTimestamp(),
        });
      }

      setState(() {
        _selectedDates.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // Menghilangkan tombol kembali
        title: Text('Maintenance'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: DropdownButtonFormField<String>(
                value: selectedRoom,
                items: roomNames.map((String room) {
                  return DropdownMenuItem<String>(
                    value: room,
                    child: Text(room),
                  );
                }).toList(),
                hint: Text('Pilih ruang'),
                onChanged: (String? value) {
                  setState(() {
                    selectedRoom = value;
                    _acceptedBookings = {};
                    _fetchReservationsStream(selectedRoom!).listen((event) {
                      setState(() {
                        _acceptedBookings = event;
                      });
                    });
                  });
                },
              ),
            ),
            StreamBuilder<Map<DateTime, List<dynamic>>>(
              stream: selectedRoom != null
                  ? _fetchReservationsStream(selectedRoom!)
                  : null,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                Map<DateTime, List<dynamic>> acceptedBookings = snapshot.data ?? {};
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TableCalendar(
                    focusedDay: DateTime.now(),
                    firstDay: DateTime.now().subtract(Duration(days: 365)),
                    lastDay: DateTime.now().add(Duration(days: 365)),
                    calendarFormat: _calendarFormat,
                    onFormatChanged: (format) {
                      setState(() {
                        _calendarFormat = format;
                      });
                    },
                    calendarStyle: CalendarStyle(
                      todayDecoration: BoxDecoration(
                        color: Colors.transparent, // No special decoration for today
                        shape: BoxShape.circle,
                      ),
                    ),
                    daysOfWeekStyle: DaysOfWeekStyle(
                      weekdayStyle: TextStyle(color: Colors.black),
                      weekendStyle: TextStyle(color: Colors.black),
                    ),
                    calendarBuilders: CalendarBuilders(
                      defaultBuilder: (context, date, _) {
                        Color dateColor = getColorForDate(date);
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              DateTime dateOnly = DateTime(date.year, date.month, date.day);
                              if (_selectedDates.contains(dateOnly)) {
                                _selectedDates.remove(dateOnly);
                              } else {
                                _selectedDates.add(dateOnly);
                              }
                            });
                          },
                          onDoubleTap: () {
                            // Handle double tap logic here
                            DateTime dateOnly = DateTime(date.year, date.month, date.day);
                            List<dynamic>? bookings = acceptedBookings[dateOnly];
                            if (bookings != null) {
                              for (var booking in bookings) {
                                if (booking['status'] == 'Maintenance') {
                                  // Remove the maintenance booking
                                  FirebaseFirestore.instance
                                      .collection('bookings')
                                      .where('room_name', isEqualTo: selectedRoom)
                                      .where('booking_date', isEqualTo: Timestamp.fromDate(dateOnly))
                                      .where('status', isEqualTo: 'Maintenance')
                                      .get()
                                      .then((querySnapshot) {
                                    querySnapshot.docs.forEach((doc) {
                                      doc.reference.delete();
                                    });
                                  }).catchError((error) {
                                    print('Error removing maintenance booking: $error');
                                  });
                                }
                              }
                            }
                          },
                          child: Container(
                            margin: const EdgeInsets.all(4.0),
                            decoration: BoxDecoration(
                              color: dateColor,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${date.day}',
                                style: TextStyle().copyWith(color: Colors.white),
                              ),
                            ),
                          ),
                        );
                      },
                      todayBuilder: (context, date, _) {
                        Color dateColor = getColorForDate(date);
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              DateTime dateOnly = DateTime(date.year, date.month, date.day);
                              if (_selectedDates.contains(dateOnly)) {
                                _selectedDates.remove(dateOnly);
                              } else {
                                _selectedDates.add(dateOnly);
                              }
                            });
                          },
                          onDoubleTap: () {
                            // Handle double tap logic here
                            DateTime dateOnly = DateTime(date.year, date.month, date.day);
                            List<dynamic>? bookings = acceptedBookings[dateOnly];
                            if (bookings != null) {
                              for (var booking in bookings) {
                                if (booking['status'] == 'Maintenance') {
                                  // Remove the maintenance booking
                                  FirebaseFirestore.instance
                                      .collection('bookings')
                                      .where('room_name', isEqualTo: selectedRoom)
                                      .where('booking_date', isEqualTo: Timestamp.fromDate(dateOnly))
                                      .where('status', isEqualTo: 'Maintenance')
                                      .get()
                                      .then((querySnapshot) {
                                    querySnapshot.docs.forEach((doc) {
                                      doc.reference.delete();
                                    });
                                  }).catchError((error) {
                                    print('Error removing maintenance booking: $error');
                                  });
                                }
                              }
                            }
                          },
                          child: Container(
                            margin: const EdgeInsets.all(4.0),
                            decoration: BoxDecoration(
                              color: dateColor,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${date.day}',
                                style: TextStyle().copyWith(color: Colors.white),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: _selectedDates.isNotEmpty ? _submitUnavailableReason : null,
                child: Text('Submit'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
