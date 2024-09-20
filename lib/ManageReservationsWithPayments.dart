import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManageReservationsWithPayments extends StatefulWidget {
  @override
  _ManageReservationsWithPaymentsState createState() => _ManageReservationsWithPaymentsState();
}

class _ManageReservationsWithPaymentsState extends State<ManageReservationsWithPayments>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _bookings = [];
  bool _isLoading = true;
  late TabController _tabController;
  late List<bool> _expanded;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchAllBookings();  // Fetch bookings when the page loads
  }

  // Fetch all bookings in parallel to improve speed
  Future<void> _fetchAllBookings() async {
    try {
      List<Map<String, dynamic>> tempBookings = [];
      QuerySnapshot venuesSnapshot = await FirebaseFirestore.instance.collection('venue').get();

      List<Future<void>> fetchTasks = venuesSnapshot.docs.map((venueDoc) async {
        QuerySnapshot bookingsSnapshot = await venueDoc.reference.collection('bookings').get();

        for (var bookingDoc in bookingsSnapshot.docs) {
          Map<String, dynamic> bookingData = bookingDoc.data() as Map<String, dynamic>;
          bookingData['bookingId'] = bookingDoc.id;
          bookingData['venueId'] = venueDoc.id;
          bookingData['venueName'] = venueDoc['name'];

          // Fetch user data in parallel
          DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
              .collection('users')
              .doc(bookingData['userId'])
              .get();

          if (userSnapshot.exists) {
            Map<String, dynamic> userData = userSnapshot.data() as Map<String, dynamic>;
            bookingData['userName'] = userData['email'];
            bookingData['userFullName'] = '${userData['name']} ${userData['lastName']}';
            bookingData['phoneNumber'] = userData['phoneNumber'];
          }

          tempBookings.add(bookingData);
        }
      }).toList();

      // Wait for all fetch tasks to complete
      await Future.wait(fetchTasks);

      setState(() {
        _bookings = tempBookings;
        _isLoading = false;
        _expanded = List<bool>.filled(_bookings.length, false);
      });
    } catch (error) {
      print('Error fetching bookings: $error');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Update the booking status and refresh the relevant booking
  Future<void> _updateBookingStatus(String venueId, String bookingId, String newStatus) async {
    await FirebaseFirestore.instance
        .collection('venue')
        .doc(venueId)
        .collection('bookings')
        .doc(bookingId)
        .update({'status': newStatus});
    
    // Instead of re-fetching all bookings, we only update the specific booking in local state
    setState(() {
      _bookings = _bookings.map((booking) {
        if (booking['bookingId'] == bookingId && booking['venueId'] == venueId) {
          booking['status'] = newStatus;
        }
        return booking;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Color(0xFF0A73B7); // Blue

    return Scaffold(
      appBar: AppBar(
        title: Text(
  'Manage Reservations and Payments',
  style: TextStyle(
    color: Colors.white, // Set text color to white
    fontWeight: FontWeight.bold,
    fontSize: 20.0, // Make the font size smaller
  ),
),
        backgroundColor: primaryColor,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: [
            Tab(text: 'Processing Payment'),
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
    final bookingsByStatus = _bookings.where((booking) => booking['status'] == status).toList();

    if (bookingsByStatus.isEmpty) {
      return Center(
        child: Text(
          'No $status bookings.',
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
            child: Column(
              children: [
                Padding(
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
                      ListTile(
                        leading: Icon(Icons.phone),
                        title: Text('Phone: ${booking['phoneNumber'] ?? 'N/A'}'),
                      ),
                      if (booking['status'] == 'processing_payment')
                        Column(
                          children: [
                            ListTile(
                              leading: Icon(Icons.code),
                              title: Text('Transaction Code: ${booking['transactionCode'] ?? 'N/A'}'),
                            ),
                            ListTile(
                              leading: Icon(Icons.image),
                              title: GestureDetector(
                                onTap: () => _showFullImage(context, booking['receiptImageUrl']),
                                child: Image.network(
                                  booking['receiptImageUrl'] ?? '',
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Text('No receipt available');
                                  },
                                ),
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () {
                                    _updateBookingStatus(booking['venueId'], booking['bookingId'], 'confirmed');
                                  },
                                  icon: Icon(Icons.check),
                                  label: Text('Confirm'),
                                  style: ElevatedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    backgroundColor: Colors.green,
                                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                  ),
                                ),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    _updateBookingStatus(booking['venueId'], booking['bookingId'], 'declined');
                                  },
                                  icon: Icon(Icons.close),
                                  label: Text('Decline'),
                                  style: ElevatedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    backgroundColor: Colors.red,
                                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showFullImage(BuildContext context, String? imageUrl) {
    if (imageUrl != null && imageUrl.isNotEmpty) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return Dialog(
            child: InteractiveViewer(
              child: Image.network(imageUrl),
            ),
          );
        },
      );
    }
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
