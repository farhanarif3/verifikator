import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:excel/excel.dart';
import 'package:permission_handler/permission_handler.dart';

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

  Future<void> _requestPermissions() async {
    var status = await Permission.storage.status;
    if (!status.isGranted) {
      await Permission.storage.request();
    }
  }

  Future<void> _generateDailyReport() async {
    if (selectedRoomId != null) {
      await _requestPermissions();

      try {
        var dailyOccupancy = await _fetchDailyOccupancy();

        var excel = Excel.createExcel();
        Sheet sheet = excel['Daily Occupancy Report'];

        // Add header row
        sheet.cell(CellIndex.indexByString('A1')).value = TextCellValue('Date');
        sheet.cell(CellIndex.indexByString('B1')).value = TextCellValue('Occupancy (%)');

        // Add data rows
        int rowIndex = 2; // Start from row 2 to leave row 1 for headers
        dailyOccupancy.forEach((date, occupancy) {
          sheet.cell(CellIndex.indexByString('A$rowIndex')).value = TextCellValue(date);
          sheet.cell(CellIndex.indexByString('B$rowIndex')).value = DoubleCellValue(occupancy);
          rowIndex++;
        });

        // Save the file
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/DailyOccupancyReport_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx');
        await file.writeAsBytes(await excel.encode()!);

        // Notify user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Laporan okupansi harian berhasil diunduh. File disimpan di: ${file.path}')),
        );
      } catch (e) {
        // Handle errors appropriately
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengunduh laporan: $e')),
        );
      }
    }
  }

  Future<Map<String, double>> _fetchDailyOccupancy() async {
    Map<String, double> dailyOccupancy = {};
    QuerySnapshot bookingSnapshot = await firestore
        .collection('bookings')
        .where('room', isEqualTo: selectedRoomId)
        .where('status', isEqualTo: 'Accepted')
        .get();

    for (var doc in bookingSnapshot.docs) {
      var bookingDate = (doc['booking_date'] as Timestamp).toDate();
      if (bookingDate.year == selectedMonth.year && bookingDate.month == selectedMonth.month) {
        var dateKey = DateFormat('yyyy-MM-dd').format(bookingDate);
        dailyOccupancy[dateKey] = 100.0; // Assuming 100% occupancy for each booking
      }
    }

    return dailyOccupancy;
  }

  void _generateMonthlyReport() async {
    if (selectedRoomId != null) {
      double occupancy = await _fetchMonthlyOccupancy(selectedRoomId!, selectedMonth);

      // Generate the report (this is a placeholder implementation)
      final reportData = '''
      Report for ${DateFormat('MMMM yyyy').format(selectedMonth)}
      Room: ${rooms.firstWhere((room) => room.id == selectedRoomId!)['room_name']}
      Occupancy: ${occupancy.toStringAsFixed(2)}%
      ''';

      // For demonstration, we just show the report in a dialog
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Generated Report'),
            content: SingleChildScrollView(
              child: Text(reportData),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('Close'),
              ),
            ],
          );
        },
      );
    }
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
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: _generateMonthlyReport,
              child: Text('Generate Monthly Report'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: _generateDailyReport,
              child: Text('Generate Daily Report'),
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

class DailyOccupancyDetailPage extends StatelessWidget {
  final String roomId;
  final DateTime month;
  final int sessionCount;

  const DailyOccupancyDetailPage({
    Key? key,
    required this.roomId,
    required this.month,
    required this.sessionCount,
  }) : super(key: key);

  Future<Map<String, double>> _fetchDailyOccupancy() async {
    Map<String, double> dailyOccupancy = {};
    QuerySnapshot bookingSnapshot = await FirebaseFirestore.instance
        .collection('bookings')
        .where('room', isEqualTo: roomId)
        .where('status', isEqualTo: 'Accepted')
        .get();

    for (var doc in bookingSnapshot.docs) {
      var bookingDate = (doc['booking_date'] as Timestamp).toDate();
      if (bookingDate.year == month.year && bookingDate.month == month.month) {
        var dateKey = DateFormat('yyyy-MM-dd').format(bookingDate);
        dailyOccupancy[dateKey] = 100.0; // Assuming 100% occupancy for each booking
      }
    }

    return dailyOccupancy;
  }

  Future<void> _generateDailyReport(BuildContext context) async {
    await _requestPermissions();

    try {
      var dailyOccupancy = await _fetchDailyOccupancy();

      var excel = Excel.createExcel();
      Sheet sheet = excel['Daily Occupancy Report'];

      // Add header row
      sheet.cell(CellIndex.indexByString('A1')).value = TextCellValue('Date');
      sheet.cell(CellIndex.indexByString('B1')).value = TextCellValue('Occupancy (%)');

      // Add data rows
      int rowIndex = 2; // Start from row 2 to leave row 1 for headers
      dailyOccupancy.forEach((date, occupancy) {
        sheet.cell(CellIndex.indexByString('A$rowIndex')).value = TextCellValue(date);
        sheet.cell(CellIndex.indexByString('B$rowIndex')).value = DoubleCellValue(occupancy);
        rowIndex++;
      });

      // Save the file
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/DailyOccupancyReport_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx');
      await file.writeAsBytes(await excel.encode()!);

      // Notify user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Laporan okupansi harian berhasil diunduh. File disimpan di: ${file.path}')),
      );
    } catch (e) {
      // Handle errors appropriately
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengunduh laporan: $e')),
      );
    }
  }

  Future<void> _requestPermissions() async {
    var status = await Permission.storage.status;
    if (!status.isGranted) {
      await Permission.storage.request();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Detail Okupansi Harian'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: () => _generateDailyReport(context),
              child: Text('Generate Daily Report'),
            ),
          ),
          Expanded(
            child: FutureBuilder<Map<String, double>>(
              future: _fetchDailyOccupancy(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                var dailyOccupancy = snapshot.data!;
                int totalDays = DateTime(month.year, month.month + 1, 0).day;

                return ListView.builder(
                  itemCount: totalDays,
                  itemBuilder: (context, index) {
                    var date = DateTime(month.year, month.month, index + 1);
                    var dateKey = DateFormat('yyyy-MM-dd').format(date);
                    var occupancy = dailyOccupancy[dateKey] ?? 0.0;

                    return ListTile(
                      title: Text(DateFormat('yyyy-MM-dd').format(date)),
                      trailing: Text('${occupancy.toStringAsFixed(2)}%'),
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
