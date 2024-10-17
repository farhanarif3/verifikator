import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class Dashboard extends StatelessWidget {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4, // Jumlah tab yang akan ditampilkan (Requested, Accepted, Rejected, Cancelled)
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false, // Menghilangkan tombol kembali
          title: Text('Pesanan yang Diajukan'),
          bottom: TabBar(
            tabs: [
              Tab(text: 'Diajukan'),   // Tab untuk pesanan yang diajukan
              Tab(text: 'Diterima'),   // Tab untuk pesanan diterima
              Tab(text: 'Ditolak'),    // Tab untuk pesanan ditolak
              Tab(text: 'Dibatalkan'), // Tab untuk pesanan dibatalkan
            ],
          ),
        ),
        body: StreamBuilder<User?>(
          stream: auth.authStateChanges(),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            if (userSnapshot.hasData) {
              User? user = userSnapshot.data!;
              return FutureBuilder<DocumentSnapshot>(
                future: firestore.collection('users').doc(user.uid).get(),
                builder: (context, userDocSnapshot) {
                  if (userDocSnapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (!userDocSnapshot.hasData || !userDocSnapshot.data!.exists) {
                    return Center(child: Text('Data pengguna tidak ditemukan.'));
                  }

                  var userData = userDocSnapshot.data!.data() as Map<String, dynamic>?;
                  if (userData == null || !userData.containsKey('bidang')) {
                    return Center(child: Text('Bidang pengguna tidak ditemukan.'));
                  }

                  String userField = userData['bidang'];

                  return TabBarView(
                    children: [
                      _buildBookingList(context, userField, 'Request'),
                      _buildBookingList(context, userField, 'Accepted'),
                      _buildBookingList(context, userField, 'Rejected'),
                      _buildBookingList(context, userField, 'Cancelled'),
                    ],
                  );
                },
              );
            } else {
              return Center(child: Text('Silakan login untuk melihat pesanan.'));
            }
          },
        ),
      ),
    );
  }

  Widget _buildBookingList(BuildContext context, String userField, String status) {
    return StreamBuilder<QuerySnapshot>(
      stream: firestore.collection('bookings')
          .where('bidang', isEqualTo: userField)
          .where('status', isEqualTo: status)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text(
            status == 'Accepted' 
              ? 'Tidak ada pesanan yang diterima.' 
              : status == 'Rejected' 
                ? 'Tidak ada pesanan yang ditolak.' 
                : status == 'Cancelled' 
                  ? 'Tidak ada pesanan yang dibatalkan.' 
                  : 'Tidak ada pesanan yang diajukan.'
          ));
        }

        var bookings = snapshot.data!.docs;
        DateFormat dateFormat = DateFormat('dd-MM-yyyy'); // Format tanggal yang diinginkan

        return ListView.builder(
          itemCount: bookings.length,
          itemBuilder: (context, index) {
            var booking = bookings[index].data() as Map<String, dynamic>;
            return Card(
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Ruangan: ${booking['room_name']}'),
                    SizedBox(height: 8),
                    Text('Tujuan Meminjam: ${booking['reason']}'),
                    SizedBox(height: 8),
                    Text('Tanggal Pemesanan: ${dateFormat.format((booking['booking_date'] as Timestamp).toDate())}'), // Format tanggal
                    Text('Sesi: ${booking['session']}'),
                    SizedBox(height: 8),
                    Text('Status: ${booking['status']}'),
                    if (status == 'Request' || status == 'Accepted')
                      ElevatedButton(
                        onPressed: () {
                          _showCancelDialog(context, bookings[index].reference);
                        },
                        child: Text('Batalkan'),
                      ),
                    if (status == 'Rejected' && booking.containsKey('rejection_reason'))
                      Text('Alasan Ditolak: ${booking['rejection_reason']}'),
                    if (status == 'Cancelled' && booking.containsKey('cancel_reason'))
                      Text('Alasan Dibatalkan: ${booking['cancel_reason']}'),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showCancelDialog(BuildContext context, DocumentReference bookingRef) {
    TextEditingController cancelReasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Alasan Pembatalan'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: cancelReasonController,
                decoration: InputDecoration(labelText: 'Masukkan alasan pembatalan'),
                maxLines: null,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Batal'),
            ),
            TextButton(
              onPressed: () {
                String cancelReason = cancelReasonController.text.trim();
                if (cancelReason.isNotEmpty) {
                  // Update status menjadi Cancelled dan simpan alasan pembatalan
                  bookingRef.update({
                    'status': 'Cancelled',
                    'cancel_reason': cancelReason, // Menggunakan cancel_reason untuk alasan pembatalan
                  }).then((value) {
                    Navigator.of(context).pop();
                  }).catchError((error) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Gagal membatalkan pesanan. Silakan coba lagi.')),
                    );
                  });
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Masukkan alasan pembatalan terlebih dahulu.')),
                  );
                }
              },
              child: Text('Simpan'),
            ),
          ],
        );
      },
    );
  }
}
