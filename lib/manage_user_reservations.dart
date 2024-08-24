import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'archived_reservations_screen.dart';

class ManageUserReservations extends StatefulWidget {
  @override
  _ManageUserReservationsState createState() => _ManageUserReservationsState();
}

class _ManageUserReservationsState extends State<ManageUserReservations> {
  List<Map<String, dynamic>> _bookings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAllBookings();
  }

  Future<void> _fetchAllBookings() async {
    try {
      List<Map<String, dynamic>> tempBookings = [];
      QuerySnapshot venuesSnapshot =
          await FirebaseFirestore.instance.collection('venue').get();

      for (var venueDoc in venuesSnapshot.docs) {
        QuerySnapshot bookingsSnapshot =
            await venueDoc.reference.collection('bookings').get();
        for (var bookingDoc in bookingsSnapshot.docs) {
          Map<String, dynamic> bookingData =
              bookingDoc.data() as Map<String, dynamic>;
          bookingData['bookingId'] = bookingDoc.id;
          bookingData['venueId'] = venueDoc.id;
          bookingData['venueName'] =
              venueDoc['name']; // Assuming 'name' is the field for venue name

          // Fetch user data from the 'users' collection in Firestore
          DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
              .collection('users')
              .doc(bookingData['userId'])
              .get();

          if (userSnapshot.exists) {
            Map<String, dynamic> userData =
                userSnapshot.data() as Map<String, dynamic>;
            bookingData['userName'] = userData[
                'email']; // Assuming 'email' is the field for user's email
            bookingData['userFullName'] = userData[
                'name']; // Assuming 'name' is the field for user's full name
          }

          tempBookings.add(bookingData);
        }
      }

      setState(() {
        _bookings = tempBookings;
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateBookingStatus(
      String venueId, String bookingId, String newStatus) async {
    await FirebaseFirestore.instance
        .collection('venue')
        .doc(venueId)
        .collection('bookings')
        .doc(bookingId)
        .update({'status': newStatus});
    _fetchAllBookings();
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'confirmed':
        return Colors.lightGreen[100]!;
      case 'pending':
        return Colors.orange[100]!;
      case 'declined':
        return Colors.red[100]!;
      default:
        return Colors.white;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manage User Reservations'),
        actions: [
          IconButton(
            icon: Icon(Icons.archive),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => ArchivedReservationsScreen()),
              );
            },
          )
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _bookings.isEmpty
              ? Center(child: Text('No bookings yet.'))
              : ListView.builder(
                  itemCount: _bookings.length,
                  itemBuilder: (context, index) {
                    final booking = _bookings[index];
                    return Card(
                      color: _getStatusColor(booking['status']),
                      margin: EdgeInsets.all(10.0),
                      child: Padding(
                        padding: EdgeInsets.all(10.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Venue: ${booking['venueName']}',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold)),
                            SizedBox(height: 5),
                            Text('Date: ${booking['date']}',
                                style: TextStyle(fontSize: 16)),
                            SizedBox(height: 5),
                            Text('Email: ${booking['userName']}',
                                style: TextStyle(fontSize: 16)),
                            SizedBox(height: 5),
                            Text('Full Name: ${booking['userFullName']}',
                                style: TextStyle(fontSize: 16)),
                            SizedBox(height: 5),
                            Text('Status: ${booking['status']}',
                                style: TextStyle(fontSize: 16)),
                            SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                ElevatedButton(
                                  onPressed: () {
                                    _updateBookingStatus(booking['venueId'],
                                        booking['bookingId'], 'confirmed');
                                  },
                                  child: Text('Confirm'),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    _updateBookingStatus(booking['venueId'],
                                        booking['bookingId'], 'declined');
                                  },
                                  child: Text('Decline'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
