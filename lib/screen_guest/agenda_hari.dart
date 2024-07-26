import 'package:flutter/material.dart';
import 'package:dropdown_button2/dropdown_button2.dart';

class agenda_hari extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: agenda_hariContent(),
    );
  }
}

class agenda_hariContent extends StatefulWidget {
  const agenda_hariContent({Key? key}) : super(key: key);

  @override
  _agenda_hariContentState createState() => _agenda_hariContentState();
}

class _agenda_hariContentState extends State<agenda_hariContent> {
  String _selectedItem = 'Hari Ini';

  // Contoh data acara, di mana Anda harus menggantinya dengan data sebenarnya
  final List<Map<String, dynamic>> _acara = [
    {
      'ruang': 'Ruang 1',
      'deskripsi': 'Deskripsi Ruang',
      'waktu': DateTime(2024, 1, 3, 9, 0),
      'pengguna': 'User123',
      'namaAcara': 'Acara 1',
      'keterangan': 'Diterima',
    },
    {
      'ruang': 'Ruang 2',
      'deskripsi': 'Deskripsi Ruang',
      'waktu': DateTime(2024, 1, 4, 10, 0),
      'pengguna': 'User456',
      'namaAcara': 'Acara 2',
      'keterangan': 'Ditolak',
    },
    // Tambahkan lebih banyak acara sesuai kebutuhan
  ];

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> ongoingEvents = [];
    List<Map<String, dynamic>> upcomingEvents = [];

    final sekarang = DateTime.now();

    for (final acara in _acara) {
      final berlangsung = acara['waktu'].isBefore(sekarang) &&
          sekarang.isBefore(acara['waktu'].add(Duration(hours: 1))); // Misal durasi 1 jam

      if (berlangsung) {
        ongoingEvents.add(acara);
      } else {
        upcomingEvents.add(acara);
      }
    }

    // Menambahkan acara baru ke dalam ongoingEvents
    ongoingEvents.add({
      'ruang': 'Ruang 3',
      'deskripsi': 'Deskripsi Ruang',
      'waktu': DateTime(2024, 1, 5, 11, 0),
      'pengguna': 'User789',
      'namaAcara': 'Acara 3',
      'keterangan': 'Diterima',
    });

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              SizedBox(height: 10),
              Center(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton2<String>(
                    isExpanded: true,
                    hint: Text(
                      'Select Item',
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).hintColor,
                      ),
                    ),
                    items: <String>[
                      'Hari Ini',
                      'Seminggu',
                      'Sebulan'
                    ].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(
                          value,
                          style: TextStyle(fontSize: 14, color: Colors.black),
                        ),
                      );
                    }).toList(),
                    value: _selectedItem,
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedItem = newValue!;
                      });
                    },
                    buttonStyleData: ButtonStyleData(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      height: 40,
                      width: 200,
                    ),
                    dropdownStyleData: DropdownStyleData(
                      maxHeight: 200,
                    ),
                    menuItemStyleData: MenuItemStyleData(
                      height: 40,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            children: [
              _buildEventCard('Sedang Berlangsung', ongoingEvents),
              _buildEventCard('Yang Akan Datang', upcomingEvents),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEventCard(String title, List<Map<String, dynamic>> events) {
    return Card(
      margin: EdgeInsets.all(16.0),
      child: Column(
        children: [
          Container(
            color: title == 'Sedang Berlangsung' ? Colors.blue : Colors.green, // Sesuaikan warna dengan kategori
            child: ListTile(
              title: Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final acara = events[index];
              return ListTile(
                title: Text('Ruang: ${acara['ruang']}'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(acara['deskripsi']),
                    Text('Waktu Peminjaman: ${acara['waktu']}'),
                  ],
                ),
                trailing: ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: Text('Detail Acara'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Pengguna: ${acara['pengguna']}'),
                              Text('Acara: ${acara['namaAcara']}'),
                              Text('Keterangan: ${acara['keterangan']}'),
                              // Tambahkan informasi detail acara di sini
                            ],
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
                  },
                  child: Text('Detail'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
