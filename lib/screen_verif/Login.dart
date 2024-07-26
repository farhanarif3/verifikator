import 'package:flutter/material.dart';

class LoginPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Silakan masuk untuk melanjutkan:',
                  style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10.0),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Username',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 10.0),
                TextFormField(
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 20.0),
                ElevatedButton(
                  onPressed: () {
                    // Implement login functionality here
                  },
                  child: Text('Login'),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Layanan Pesan Lokasi Terintegrasi Perangkat Daerah Kota Surakarta',
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 20.0),
                  Text(
                    'Layanan peminjaman tempat dan ruangan di lingkungan Pemerintah Kota Surakarta berbasis elektronik.',
                    style: TextStyle(fontSize: 16.0),
                  ),
                  SizedBox(height: 20.0),
                  Text(
                    'S & K Peminjaman Tempat dan Ruangan antara lain :',
                    style: TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10.0),
                  Text(
                    '1. Peminjaman tempat hanya dapat digunakan di hari kerja yaitu :',
                    style: TextStyle(fontSize: 14.0),
                  ),
                  Text(
                    '- Senin - Kamis : jam 07.00 - 16.00',
                    style: TextStyle(fontSize: 14.0),
                  ),
                  Text(
                    '- Jum\'at : jam 07.00 - 11.00',
                    style: TextStyle(fontSize: 14.0),
                  ),
                  SizedBox(height: 10.0),
                  Text(
                    '2. Peminjaman tempat hanya dapat dijadwalkan oleh pengelola tempat setelah disetujui dan surat permohonan pinjam tempat sudah diupload pada aplikasi (Khusus Pengguna Diluar OPD);',
                    style: TextStyle(fontSize: 14.0),
                  ),
                  Text(
                    '3. Bersedia sewaktu-waktu dipindah/diganti/dibatalkan jadwal peminjaman jika tempat/ruangan akan digunakan oleh Pimpinan Pemerintahan;',
                    style: TextStyle(fontSize: 14.0),
                  ),
                  Text(
                    '4. Untuk peminjaman harap dilakukan 1 hari sebelum acara pada jam kerja.',
                    style: TextStyle(fontSize: 14.0),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
