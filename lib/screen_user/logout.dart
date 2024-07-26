import 'package:flutter/material.dart';

class FourthPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white, // Mengubah warna AppBar
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.exit_to_app, color: Colors.red), // Mengatur warna ikon menjadi merah
            onPressed: () {
              // Tempatkan logika logout Anda di sini
              // Misalnya, menampilkan dialog konfirmasi
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text('Logout'),
                    content: Text('Apakah Anda yakin ingin logout?'),
                    actions: <Widget>[
                      TextButton(
                        child: Text('Tidak'),
                        onPressed: () {
                          Navigator.of(context).pop(); // Tutup dialog
                        },
                      ),
                      TextButton(
                        child: Text('Ya'),
                        onPressed: () {
                          // Tempatkan fungsi logout Anda di sini
                          // Misalnya, kembali ke layar login
                          Navigator.of(context).pop(); // Tutup dialog
                          // Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => LoginPage()));
                        },
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView( // Memungkinkan teks untuk discroll
          child: Card(
            margin: EdgeInsets.all(16), // Tambahkan margin sesuai kebutuhan
            child: Padding(
              padding: EdgeInsets.all(16), // Tambahkan padding sesuai kebutuhan
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Layanan Pesan Lokasi Terintegrasi Perangkat Daerah Kota Surakarta',
                    style: Theme.of(context).textTheme.headlineSmall, // Sesuaikan dengan perubahan API terbaru
                    textAlign: TextAlign.justify,
                  ),
                  SizedBox(height: 8), // Menambahkan sedikit ruang antar paragraf
                  Text(
                    'Layanan peminjaman tempat dan ruangan di lingkungan Pemerintah Kota Surakarta berbasis elektronik.',
                    textAlign: TextAlign.justify,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'S & K Peminjaman Tempat dan Ruangan antara lain:',
                    textAlign: TextAlign.justify,
                  ),
                  ListTile(
                    leading: Icon(Icons.check, size: 20),
                    title: Text('Peminjaman tempat hanya dapat digunakan di hari kerja.'),
                  ),
                  ListTile(
                    leading: Icon(Icons.check, size: 20),
                    title: Text('Peminjaman tempat hanya dapat dijadwalkan oleh pengelola tempat setelah disetujui.'),
                  ),
                  ListTile(
                    leading: Icon(Icons.check, size: 20),
                    title: Text('Bersedia sewaktu-waktu dipindah/diganti/dibatalkan jadwal peminjaman.'),
                  ),
                  ListTile(
                    leading: Icon(Icons.check, size: 20),
                    title: Text('Untuk peminjaman harap dilakukan 1 hari sebelum acara pada jam kerja.'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: FourthPage(),
  ));
}
