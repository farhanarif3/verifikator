import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'DailyOccupancyDetailPage.dart';

class DashAdmin extends StatefulWidget {
  @override
  _DashAdminState createState() => _DashAdminState();
}

class _DashAdminState extends State<DashAdmin> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  String? selectedRoomId;
  List<QueryDocumentSnapshot> rooms = [];
  int sessionCount = 0;
  DateTime selectedMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    _fetchRooms();
    _fetchSessionCount();
  }

  Future<void> _fetchRooms() async {
    QuerySnapshot roomSnapshot = await firestore.collection('rooms').get();
    setState(() {
      rooms = roomSnapshot.docs;
      if (rooms.isNotEmpty) {
        selectedRoomId = rooms.first.id;
      }
    });
  }

  Future<void> _fetchSessionCount() async {
    QuerySnapshot sessionSnapshot = await firestore.collection('sessions').get();
    setState(() {
      sessionCount = sessionSnapshot.docs.length;
    });
  }

  Future<double> _fetchMonthlyOccupancy(String roomId, DateTime month) async {
    int totalDays = DateTime(month.year, month.month + 1, 0).day;
    int totalSessions = totalDays * sessionCount;
    int bookedSessions = 0;

    QuerySnapshot bookingSnapshot = await firestore
        .collection('bookings')
        .where('room', isEqualTo: roomId)
        .where('status', isEqualTo: 'Accepted')
        .get();

    for (var doc in bookingSnapshot.docs) {
      var bookingDate = (doc['booking_date'] as Timestamp).toDate();
      if (bookingDate.year == month.year && bookingDate.month == month.month) {
        bookedSessions++;
      }
    }

    return (bookedSessions / totalSessions) * 100;
  }

  void _changeMonth(int delta) {
    setState(() {
      selectedMonth = DateTime(selectedMonth.year, selectedMonth.month + delta, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Data Okupansi Booking'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: DropdownButtonFormField<String>(
              decoration: InputDecoration(labelText: 'Pilih Ruangan'),
              value: selectedRoomId,
              items: rooms.map((room) {
                return DropdownMenuItem<String>(
                  child: Text(room['room_name']),
                  value: room.id,
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedRoomId = value;
                });
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_left),
                  onPressed: () => _changeMonth(-1),
                ),
                Text(
                  DateFormat('MMMM yyyy').format(selectedMonth),
                  style: TextStyle(fontSize: 16),
                ),
                IconButton(
                  icon: Icon(Icons.arrow_right),
                  onPressed: () => _changeMonth(1),
                ),
              ],
            ),
          ),
          Expanded(
            child: selectedRoomId == null
                ? Center(child: Text('Pilih ruangan untuk melihat data okupansi'))
                : FutureBuilder<double>(
                    future: _fetchMonthlyOccupancy(selectedRoomId!, selectedMonth),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return Center(child: CircularProgressIndicator());
                      }

                      var occupancy = snapshot.data!;
                      return ListTile(
                        title: Text('${DateFormat('MMMM yyyy').format(selectedMonth)}'),
                        trailing: Text('${occupancy.toStringAsFixed(2)}%'),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DailyOccupancyDetailPage(
                                roomId: selectedRoomId!,
                                month: selectedMonth,
                                sessionCount: sessionCount,
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
}
