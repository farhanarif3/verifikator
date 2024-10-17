import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:excel/excel.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class DailyOccupancyDetailPage extends StatefulWidget {
  final String roomId;
  final DateTime month;
  final int sessionCount;

  const DailyOccupancyDetailPage({
    Key? key,
    required this.roomId,
    required this.month,
    required this.sessionCount,
  }) : super(key: key);

  @override
  _DailyOccupancyDetailPageState createState() => _DailyOccupancyDetailPageState();
}

class _DailyOccupancyDetailPageState extends State<DailyOccupancyDetailPage> {
  Future<Map<String, double>> _fetchDailyOccupancy() async {
    Map<String, double> dailyOccupancy = {};
    QuerySnapshot bookingSnapshot = await FirebaseFirestore.instance
        .collection('bookings')
        .where('room', isEqualTo: widget.roomId)
        .where('status', isEqualTo: 'Accepted')
        .get();

    int totalSessionsPerDay = widget.sessionCount;

    for (var doc in bookingSnapshot.docs) {
      var bookingDate = (doc['booking_date'] as Timestamp).toDate();
      if (bookingDate.year == widget.month.year && bookingDate.month == widget.month.month) {
        var dateKey = DateFormat('yyyy-MM-dd').format(bookingDate);
        if (!dailyOccupancy.containsKey(dateKey)) {
          dailyOccupancy[dateKey] = 0;
        }
        dailyOccupancy[dateKey] = 100.0;
      }
    }

    return dailyOccupancy;
  }

  Future<void> _generateReport() async {
    // Request storage permission
    var status = await Permission.storage.request();
    if (!status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Storage permission is required to save the report')),
      );
      return;
    }

    var dailyOccupancy = await _fetchDailyOccupancy();
    var excel = Excel.createExcel();
    var sheetObject = excel['Occupancy Report'];

    // Add headers
    sheetObject.cell(CellIndex.indexByString('A1')).value = TextCellValue('Date');
    sheetObject.cell(CellIndex.indexByString('B1')).value = TextCellValue('Occupancy');

    // Add data
    int rowIndex = 2;
    dailyOccupancy.forEach((date, occupancy) {
      sheetObject.cell(CellIndex.indexByString('A$rowIndex')).value = TextCellValue(date);
      sheetObject.cell(CellIndex.indexByString('B$rowIndex')).value = DoubleCellValue(occupancy);
      rowIndex++;
    });

    // Save the file
    var fileBytes = excel.save();
    String? downloadsDirectory;
    if (Platform.isAndroid) {
      downloadsDirectory = (await getExternalStorageDirectories(type: StorageDirectory.downloads))?.first.path;
    } else {
      downloadsDirectory = (await getApplicationDocumentsDirectory()).path;
    }

    if (downloadsDirectory != null) {
      String filePath = '$downloadsDirectory/occupancy_report_${widget.roomId}_${DateFormat('yyyy_MM').format(widget.month)}.xlsx';
      File(filePath)
        ..createSync(recursive: true)
        ..writeAsBytesSync(fileBytes!);

      // Display success message
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Report Generated'),
            content: Text('The report has been saved to: $filePath'),
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
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to get the Downloads directory')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Detail Okupansi Harian'),
      ),
      body: FutureBuilder<Map<String, double>>(
        future: _fetchDailyOccupancy(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          var dailyOccupancy = snapshot.data!;
          int totalDays = DateTime(widget.month.year, widget.month.month + 1, 0).day;

          return Column(
            children: [
              
              Expanded(
                child: ListView.builder(
                  itemCount: totalDays,
                  itemBuilder: (context, index) {
                    var date = DateTime(widget.month.year, widget.month.month, index + 1);
                    var dateKey = DateFormat('yyyy-MM-dd').format(date);
                    var occupancy = dailyOccupancy[dateKey] ?? 0.0;

                    return ListTile(
                      title: Text(DateFormat('yyyy-MM-dd').format(date)),
                      trailing: Text('${occupancy.toStringAsFixed(2)}%'),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
