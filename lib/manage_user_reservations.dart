import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'archived_reservations_screen.dart';

class ManageUserReservations extends StatefulWidget {
  @override
  _ManageUserReservationsState createState() => _ManageUserReservationsState();
}

class _ManageUserReservationsState extends State<ManageUserReservations>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _bookings = [];
  bool _isLoading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _fetchAllBookings();
    _tabController = TabController(length: 3, vsync: this);
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
          bookingData['venueName'] = venueDoc['name'];

          // Fetch user data from the 'users' collection
          DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
              .collection('users')
              .doc(bookingData['userId'])
              .get();

          if (userSnapshot.exists) {
            Map<String, dynamic> userData =
                userSnapshot.data() as Map<String, dynamic>;
            bookingData['userName'] = userData['email'];
            bookingData['userFullName'] =
                userData['name'] + ' ' + userData['lastName'];
          }

          tempBookings.add(bookingData);
        }
      }

      setState(() {
        _bookings = tempBookings;
        _isLoading = false;
      });
    } catch (error) {
      print('Error fetching bookings: $error');
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

  @override
  Widget build(BuildContext context) {
    // Define your color scheme
    final Color primaryColor = Color(0xFF0A73B7); // Blue

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Manage User Reservations',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryColor,
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
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'processing_payment'),
            Tab(text: 'Confirmed'),
            Tab(text: 'Declined'),
          ],
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _bookings.isEmpty
              ? Center(
                  child: Text(
                    'No bookings yet.',
                    style: TextStyle(fontSize: 18),
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildBookingList('processing_payment'),
                    _buildBookingList('confirmed'),
                    _buildBookingList('declined'),
                  ],
                ),
    );
  }

  Widget _buildBookingList(String status) {
    final bookingsByStatus =
        _bookings.where((booking) => booking['status'] == status).toList();

    if (bookingsByStatus.isEmpty) {
      return Center(
        child: Text(
          'No ${status} bookings.',
          style: TextStyle(fontSize: 18),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchAllBookings,
      child: ListView.builder(
        padding: EdgeInsets.all(10.0),
        itemCount: bookingsByStatus.length,
        itemBuilder: (context, index) {
          final booking = bookingsByStatus[index];
          return Card(
            elevation: 3,
            margin: EdgeInsets.symmetric(vertical: 8.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            color: _getStatusColor(booking['status']),
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Booking Header
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.grey[300],
                        radius: 30,
                        child: Icon(
                          Icons.event,
                          size: 30,
                          color: Colors.grey[700],
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              booking['venueName'] ?? 'No Venue Name',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Date: ${booking['date'] ?? 'N/A'}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Status displayed as text
                      Text(
                        booking['status'].toUpperCase(),
                        style: TextStyle(
                          color: booking['status'] == 'confirmed'
                              ? Colors.green
                              : booking['status'] == 'processing_payment'
                                  ? Colors.orange
                                  : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  // User Details
                  Text(
                    'User Details',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Divider(),
                  ListTile(
                    leading: Icon(Icons.person),
                    title: Text('Full Name: ${booking['userFullName']}'),
                  ),
                  ListTile(
                    leading: Icon(Icons.email),
                    title: Text('Email: ${booking['userName']}'),
                  ),
                  SizedBox(height: 16),
                  // Action Buttons
                  if (booking['status'] == 'processing_payment')
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () {
                            _updateBookingStatus(booking['venueId'],
                                booking['bookingId'], 'confirmed');
                          },
                          icon: Icon(Icons.check),
                          label: Text('Confirm'),
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.green,
                            padding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            _updateBookingStatus(booking['venueId'],
                                booking['bookingId'], 'declined');
                          },
                          icon: Icon(Icons.close),
                          label: Text('Decline'),
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.red,
                            padding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                          ),
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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'confirmed':
        return Colors.lightGreen[50]!;
      case 'processing_payment':
        return Colors.orange[50]!;
      case 'declined':
        return Colors.red[50]!;
      default:
        return Colors.white;
    }
  }
}
