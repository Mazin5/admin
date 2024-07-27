import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
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
    DatabaseReference venuesRef = FirebaseDatabase.instance.ref().child('venue');

    try {
      DatabaseEvent venuesEvent = await venuesRef.once();
      DataSnapshot venuesSnapshot = venuesEvent.snapshot;

      if (venuesSnapshot.value != null) {
        Map<dynamic, dynamic> venuesMap = Map<dynamic, dynamic>.from(venuesSnapshot.value as Map);
        List<Map<String, dynamic>> tempBookings = [];

        for (var venueId in venuesMap.keys) {
          DatabaseReference bookingsRef = venuesRef.child(venueId).child('bookings');
          DatabaseEvent bookingsEvent = await bookingsRef.once();
          DataSnapshot bookingsSnapshot = bookingsEvent.snapshot;

          if (bookingsSnapshot.value != null) {
            Map<dynamic, dynamic> bookingsMap = Map<dynamic, dynamic>.from(bookingsSnapshot.value as Map);
            for (var key in bookingsMap.keys) {
              Map<String, dynamic> bookingData = Map<String, dynamic>.from(bookingsMap[key] as Map);
              bookingData['bookingId'] = key;
              bookingData['venueId'] = venueId;
              bookingData['venueName'] = venuesMap[venueId]['name']; // Assuming 'name' is the field for venue name

              // Fetch user data from the 'users' collection in Firestore
              DocumentReference userRef = FirebaseFirestore.instance.collection('users').doc(bookingData['userId']);
              DocumentSnapshot userSnapshot = await userRef.get();

              if (userSnapshot.exists) {
                Map<String, dynamic> userData = userSnapshot.data() as Map<String, dynamic>;
                bookingData['userName'] = userData['email']; // Assuming 'email' is the field for user's email
                bookingData['userFullName'] = userData['name']; // Assuming 'name' is the field for user's full name
              }

              tempBookings.add(bookingData);
            }
          }
        }

        setState(() {
          _bookings = tempBookings;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (error) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateBookingStatus(String venueId, String bookingId, String newStatus) async {
    DatabaseReference bookingRef = FirebaseDatabase.instance.ref().child('venue').child(venueId).child('bookings').child(bookingId);
    await bookingRef.update({'status': newStatus});
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
                MaterialPageRoute(builder: (context) => ArchivedReservationsScreen()),
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
                            Text('Venue: ${booking['venueName']}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            SizedBox(height: 5),
                            Text( 'Date: ${booking['date']}', style: TextStyle(fontSize: 16)),
                            SizedBox(height: 5),
                            Text('Email: ${booking['userName']}', style: TextStyle(fontSize: 16)),
                            SizedBox(height: 5),
                            Text('Full Name: ${booking['userFullName']}', style: TextStyle(fontSize: 16)),
                            SizedBox(height: 5),
                            Text('Status: ${booking['status']}', style: TextStyle(fontSize: 16)),
                            SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                ElevatedButton(
                                  onPressed: () {
                                    _updateBookingStatus(booking['venueId'], booking['bookingId'], 'confirmed');
                                  },
                                  child: Text('Confirm'),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    _updateBookingStatus(booking['venueId'], booking['bookingId'], 'declined');
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
