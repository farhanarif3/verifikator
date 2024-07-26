import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _sessionController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  DocumentSnapshot? _selectedSession;

  Future<void> _addSession() async {
    if (_sessionController.text.isEmpty || _startTime == null || _endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Harap isi semua field.'),
      ));
      return;
    }

    DateTime startDateTime = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
      _startTime!.hour,
      _startTime!.minute,
    );

    DateTime endDateTime = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
      _endTime!.hour,
      _endTime!.minute,
    );

    try {
      if (_selectedSession == null) {
        // Generate a new document with a unique ID
        DocumentReference newSessionRef = _firestore.collection('sessions').doc();
        await newSessionRef.set({
          'id': newSessionRef.id,
          'code' : _codeController.text,
          'name': _sessionController.text,
          'start_time': Timestamp.fromDate(startDateTime),
          'end_time': Timestamp.fromDate(endDateTime),
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Sesi berhasil ditambahkan.'),
        ));
      } else {
        await _selectedSession!.reference.update({
          'name': _sessionController.text,
          'start_time': Timestamp.fromDate(startDateTime),
          'end_time': Timestamp.fromDate(endDateTime),
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Sesi berhasil diperbarui.'),
        ));
      }

      _clearInputs();
    } catch (e) {
      print('Error adding/updating session: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Gagal menambahkan/perbarui sesi.'),
      ));
    }
  }

  void _clearInputs() {
    _sessionController.clear();
    setState(() {
      _startTime = null;
      _endTime = null;
      _selectedSession = null;
    });
  }

  Future<void> _selectStartTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _startTime = picked;
      });
    }
  }

  Future<void> _selectEndTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _endTime = picked;
      });
    }
  }

  void _editSession(DocumentSnapshot session) {
    setState(() {
      _selectedSession = session;
      _sessionController.text = session['name'];
      _startTime = TimeOfDay.fromDateTime(session['start_time'].toDate());
      _endTime = TimeOfDay.fromDateTime(session['end_time'].toDate());
    });
  }

  void _deleteSession(String sessionId) async {
    try {
      await _firestore.collection('sessions').doc(sessionId).delete();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Sesi berhasil dihapus.'),
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Gagal menghapus sesi.'),
      ));
    }
  }

  void _confirmDeleteSession(String sessionId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Konfirmasi Hapus'),
          content: Text('Apakah Anda yakin ingin menghapus sesi ini?'),
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
                _deleteSession(sessionId);
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
        title: Text('Pengaturan'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _sessionController,
              decoration: InputDecoration(
                labelText: 'Nama Sesi',
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _codeController,
              decoration: InputDecoration(
                labelText: 'Code',
              ),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => _selectStartTime(context),
                    child: Text(
                      _startTime == null
                          ? 'Pilih Waktu Mulai'
                          : 'Mulai: ${_startTime!.hour}:${_startTime!.minute.toString().padLeft(2, '0')}',
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: TextButton(
                    onPressed: () => _selectEndTime(context),
                    child: Text(
                      _endTime == null
                          ? 'Pilih Waktu Selesai'
                          : 'Selesai: ${_endTime!.hour}:${_endTime!.minute.toString().padLeft(2, '0')}',
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _addSession,
              child: Text(_selectedSession == null ? 'Tambah Sesi' : 'Perbarui Sesi'),
            ),
            SizedBox(height: 20),
            Text(
              'Sesi yang Sudah Ada:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore.collection('sessions').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(child: CircularProgressIndicator());
                  }

                  var sessions = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: sessions.length,
                    itemBuilder: (context, index) {
                      var session = sessions[index];

                      return Card(
                        margin: EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          title: Text(session['name']),
                          subtitle: Text(
                            'Mulai: ${DateFormat.Hm().format(session['start_time'].toDate())}, '
                            'Selesai: ${DateFormat.Hm().format(session['end_time'].toDate())}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.edit),
                                onPressed: () => _editSession(session),
                              ),
                              IconButton(
                                icon: Icon(Icons.delete),
                                onPressed: () => _confirmDeleteSession(session.id),
                              ),
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
      ),
    );
  }
}
