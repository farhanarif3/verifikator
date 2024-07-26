import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class datareservasi extends StatefulWidget {
  const datareservasi({Key? key}) : super(key: key);

  @override
  _datareservasiState createState() => _datareservasiState();
}

class _datareservasiState extends State<datareservasi> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  Map<DateTime, List<dynamic>> _acceptedBookings = {};
  String? selectedRoom;
  List<String> roomNames = [];
  List<String> sessions = [];

  @override
  void initState() {
    super.initState();
    fetchRooms();
    fetchSessions();
  }

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

  Future<void> fetchSessions() async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('sessions')
          .where('code', isNotEqualTo: 'FULL')
          .get();

      List<String> sessionList = [];
      for (var doc in querySnapshot.docs) {
        sessionList.add(doc['code']);
      }

      setState(() {
        sessions = sessionList;
      });
    } catch (e) {
      print('Error fetching sessions: $e');
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

  Color getColorForDate(DateTime date) {
    DateTime dateOnly = DateTime(date.year, date.month, date.day);
    List<dynamic>? bookings = _acceptedBookings[dateOnly];

    if (bookings != null && bookings.isNotEmpty) {
      bool sesiAccepted = false;
      bool fullDayAccepted = false;
      int acceptedSessionsCount = 0;

      for (var booking in bookings) {
        String? status = booking['status'] as String?;
        String? session = booking['session'] as String?;

        if (status != null && status == 'Accepted') {
          if (session == 'FULL') {
            fullDayAccepted = true;
          } else {
            sesiAccepted = true;
            acceptedSessionsCount++;
          }
        }
      }

      if (fullDayAccepted) {
        return Colors.red;
      } else if (sesiAccepted && acceptedSessionsCount >= sessions.length) {
        return Colors.red;
      } else if (sesiAccepted) {
        return Colors.yellow;
      }
    }

    return Colors.green; // Default color
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // Menghilangkan tombol kembali
        title: Text('Booking Calendar'),
      ),
      body: Column(
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
                  if (selectedRoom != null) {
                    _fetchReservationsStream(selectedRoom!).listen((event) {
                      setState(() {
                        _acceptedBookings = event;
                      });
                    });
                  }
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<Map<DateTime, List<dynamic>>>(
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
                  child: Column(
                    children: [ TableCalendar(
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
                        List<dynamic>? bookings = acceptedBookings[DateTime(date.year, date.month, date.day)];
                        Color dateColor = bookings != null && bookings.isNotEmpty 
                          ? getColorForDate(date) 
                          : Colors.green;
                        return GestureDetector(
                          onTap: () {
                            DateTime dateOnly = DateTime(date.year, date.month, date.day);
                            List<dynamic>? bookings = acceptedBookings[dateOnly];
                            if (bookings != null && bookings.isNotEmpty) {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: Text('Detail Pesanan'),
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: bookings.map((booking) {
                                        return ListTile(
                                          title: Text('Bidang: ${booking['bidang']}'),
                                          subtitle: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text('Sesi: ${booking['session']}'),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                        child: Text('Tutup'),
                                      ),
                                    ],
                                  );
                                },
                              );
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
                        List<dynamic>? bookings = acceptedBookings[DateTime(date.year, date.month, date.day)];
                        Color dateColor = bookings != null && bookings.isNotEmpty 
                          ? getColorForDate(date) 
                          : Colors.green;
                        return GestureDetector(
                          onTap: () {
                            DateTime dateOnly = DateTime(date.year, date.month, date.day);
                            List<dynamic>? bookings = acceptedBookings[dateOnly];
                            if (bookings != null && bookings.isNotEmpty) {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: Text('Detail Pesanan'),
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: bookings.map((booking) {
                                        return ListTile(
                                          title: Text('Bidang: ${booking['bidang']}'),
                                          subtitle: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text('Sesi: ${booking['session']}'),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                        child: Text('Tutup'),
                                      ),
                                    ],
                                  );
                                },
                              );
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
                  SizedBox(height: 10),
                      _buildLegendItem(Colors.green, 'Belum dipesan'),
                      SizedBox(height: 6),
                      _buildLegendItem(Colors.yellow, 'Masih bisa memesan'),
                      SizedBox(height: 6),
                      _buildLegendItem(Colors.red, 'Tidak dapat dipesan'),
                      SizedBox(height: 6),
                      _buildLegendItem(Colors.purple, 'Sedang maintenance'),
                  ],
                  )
                );
                
              },
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildLegendItem(Color color, String text) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        ),
        SizedBox(width: 6),
        Text(text),
      ],
    );
  }
}
