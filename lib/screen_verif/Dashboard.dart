import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Dashboard extends StatelessWidget {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final String userBidang;

  // Constructor with userBidang
  Dashboard({required this.userBidang});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        body: Column(
          children: [
            Container(
              padding: EdgeInsets.symmetric(vertical: 8),
              color: Colors.white,
              child: TabBar(
                indicatorColor: Colors.blue,
                labelColor: Colors.blue,
                unselectedLabelColor: Colors.grey,
                tabs: [
                  _buildTabWithCounter('Request', 'bookings', status: 'Request'),
                  _buildTabWithCounter('Approved', 'bookings', status: 'Accepted'),
                  _buildTabWithCounter('Rejected', 'bookings', status: 'Rejected'),
                  _buildTabWithCounter('Cancelled', 'bookings', status: 'Cancelled'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildBookingsTab(status: 'Request'),
                  _buildApprovedTab(),
                  _buildRejectedTab(),
                  _buildCancelledTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabWithCounter(String title, String collection, {String? status}) {
    return StreamBuilder<QuerySnapshot>(
      stream: status != null
          ? firestore.collection(collection).where('status', isEqualTo: status).where('room_bidang', isEqualTo: userBidang).snapshots()
          : firestore.collection(collection).where('room_bidang', isEqualTo: userBidang).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Tab(child: Text(title));
        }
        if (snapshot.hasError) {
          return Tab(child: Text('$title (Error)'));
        }

        int count = snapshot.data?.docs.length ?? 0;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Stack(
            children: [
              Tab(
                child: Text(title),
              ),
              if (count > 0)
                Positioned(
                  right: 0,
                  top: 0, // Adjust this value to move the badge downwards
                  child: Container(
                    padding: EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: BoxConstraints(minWidth: 20, minHeight: 20),
                    child: Center(
                      child: Text(
                        '$count',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBookingsTab({String? status}) {
    return StreamBuilder<QuerySnapshot>(
      stream: firestore.collection('bookings').where('status', isEqualTo: status).where('room_bidang', isEqualTo: userBidang).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('No booking data available.'));
        }

        var bookings = snapshot.data!.docs;

        return SingleChildScrollView(
          child: Column(
            children: bookings.map((booking) {
              String status = booking['status'];
              DateTime bookingDate = (booking['booking_date'] as Timestamp).toDate();

              if (status != 'Accepted' && status != 'Rejected' && status != 'Cancelled') {
                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    title: Text('Ruangan: ${booking['room_name']}'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Bidang: ${booking['bidang']}'),
                        Text('Phone: ${booking['phone']}'),
                        Text('Date: ${bookingDate.day}/${bookingDate.month}/${bookingDate.year}'),
                        Text('Sesi: ${booking['session']}'),
                        Text('Keperluan: ${booking['reason']}'),
                      ],
                    ),
                    trailing: Wrap(
                      spacing: 12,
                      children: [
                        ElevatedButton(
                          onPressed: () => _showConfirmationDialog(context, booking, true),
                          child: Text('Accept'),
                        ),
                        ElevatedButton(
                          onPressed: () => _showConfirmationDialog(context, booking, false),
                          child: Text('Reject'),
                        ),
                      ],
                    ),
                  ),
                );
              } else {
                return SizedBox.shrink();
              }
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildApprovedTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: firestore.collection('bookings').where('status', isEqualTo: 'Accepted').where('room_bidang', isEqualTo: userBidang).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('No approved bookings available.'));
        }

        var bookings = snapshot.data!.docs;

        return SingleChildScrollView(
          child: Column(
            children: bookings.map((booking) {
              DateTime bookingDate = (booking['booking_date'] as Timestamp).toDate();

              return Card(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text('Room: ${booking['room_name']}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Bidang: ${booking['bidang']}'),
                      Text('Phone: ${booking['phone']}'),
                      Text('Date: ${bookingDate.day}/${bookingDate.month}/${bookingDate.year}'),
                      Text('Sesi: ${booking['session']}'),
                      Text('Keperluan: ${booking['reason']}'),
                    ],
                  ),
                  trailing: Icon(Icons.check_circle, color: Colors.green),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

 Widget _buildRejectedTab() {
  return StreamBuilder<QuerySnapshot>(
    stream: firestore.collection('bookings')
        .where('status', isEqualTo: 'Rejected')
        .where('room_bidang', isEqualTo: userBidang)
        .snapshots(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return Center(child: CircularProgressIndicator());
      }
      if (snapshot.hasError) {
        return Center(child: Text('Error: ${snapshot.error}'));
      }
      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
        return Center(child: Text('No rejected bookings available.'));
      }

      var bookings = snapshot.data!.docs;

      return SingleChildScrollView(
        child: Column(
          children: bookings.map((booking) {
            DateTime bookingDate = (booking['booking_date'] as Timestamp).toDate();
            // Cast the document data to Map<String, dynamic>
            Map<String, dynamic> bookingData = booking.data() as Map<String, dynamic>;

            // Handle rejection reason safely
            String rejectionReason = bookingData.containsKey('rejection_reason')
                ? bookingData['rejection_reason']
                : 'No reason provided';

            return Card(
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                title: Text('Room: ${bookingData['room_name']}'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Bidang: ${bookingData['bidang']}'),
                    Text('Phone: ${bookingData['phone']}'),
                    Text('Date: ${bookingDate.day}/${bookingDate.month}/${bookingDate.year}'),
                    Text('Sesi: ${bookingData['session']}'),
                    Text('Keperluan: ${bookingData['reason']}'),
                    Text('Rejection Reason: $rejectionReason'),
                  ],
                ),
                trailing: Icon(Icons.cancel, color: Colors.red),
              ),
            );
          }).toList(),
        ),
      );
    },
  );
}



  Widget _buildCancelledTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: firestore.collection('bookings').where('status', isEqualTo: 'Cancelled').where('room_bidang', isEqualTo: userBidang).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
                if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('No cancelled bookings available.'));
        }

        var bookings = snapshot.data!.docs;

        return SingleChildScrollView(
          child: Column(
            children: bookings.map((booking) {
              DateTime bookingDate = (booking['booking_date'] as Timestamp).toDate();

              return Card(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text('Room: ${booking['room_name']}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Bidang: ${booking['bidang']}'),
                      Text('Phone: ${booking['phone']}'),
                      Text('Date: ${bookingDate.day}/${bookingDate.month}/${bookingDate.year}'),
                      Text('Sesi: ${booking['session']}'),
                      Text('Keperluan: ${booking['reason']}'),
                    ],
                  ),
                  trailing: Icon(Icons.cancel, color: Colors.grey),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void _showConfirmationDialog(BuildContext context, DocumentSnapshot booking, bool isAccept) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isAccept ? 'Accept Booking' : 'Reject Booking'),
          content: Text('Are you sure you want to ${isAccept ? 'accept' : 'reject'} this booking?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _updateBookingStatus(booking.id, isAccept ? 'Accepted' : 'Rejected');
                Navigator.of(context).pop();
              },
              child: Text(isAccept ? 'Accept' : 'Reject'),
            ),
          ],
        );
      },
    );
  }

  void _updateBookingStatus(String bookingId, String status) {
    firestore.collection('bookings').doc(bookingId).update({'status': status});
  }
}

         
