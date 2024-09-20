import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManageReservationsWithPayments extends StatefulWidget {
  @override
  _ManageReservationsWithPaymentsState createState() =>
      _ManageReservationsWithPaymentsState();
}

class _ManageReservationsWithPaymentsState
    extends State<ManageReservationsWithPayments> with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _bookings = [];
  bool _isLoading = true;
  late TabController _tabController;
  late List<bool> _expanded;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchAllBookings();
  }

  /// Fetches all bookings from Firestore across multiple collections.
  Future<void> _fetchAllBookings() async {
    final List<String> collections = ['venue', 'singer', 'decoration', 'meal'];

    try {
      List<Map<String, dynamic>> tempBookings = [];

      // Loop over each collection and fetch its bookings
      for (String collection in collections) {
        QuerySnapshot collectionSnapshot =
            await FirebaseFirestore.instance.collection(collection).get();

        for (var entityDoc in collectionSnapshot.docs) {
          String entityId = entityDoc.id;
          QuerySnapshot bookingsSnapshot =
              await entityDoc.reference.collection('bookings').get();

          for (var bookingDoc in bookingsSnapshot.docs) {
            Map<String, dynamic> bookingData =
                bookingDoc.data() as Map<String, dynamic>;

            // Ensure necessary fields are present
            if (bookingData.containsKey('userId') && bookingData.containsKey('status')) {
              bookingData['bookingId'] = bookingDoc.id;
              bookingData['entityId'] = entityId;
              bookingData['entityType'] = collection;
              bookingData['entityName'] = entityDoc['name'];

              // Fetch user data from the 'users' collection
              DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
                  .collection('users')
                  .doc(bookingData['userId'])
                  .get();

              if (userSnapshot.exists) {
                Map<String, dynamic> userData = userSnapshot.data() as Map<String, dynamic>;
                bookingData['userName'] = userData['email'] ?? 'No Email';
                bookingData['userFullName'] = '${userData['name'] ?? ''} ${userData['lastName'] ?? ''}';
                bookingData['phoneNumber'] = userData['phoneNumber'] ?? 'No Phone Number';
              }

              tempBookings.add(bookingData);
            }
          }
        }
      }

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

  /// Updates the booking status in Firestore.
  Future<void> _updateBookingStatus(
    String entityType,
    String entityId,
    String bookingId,
    String newStatus, {
    String? rejectionReason,
    String? date,
  }) async {
    DocumentReference bookingRef = FirebaseFirestore.instance
        .collection(entityType)
        .doc(entityId)
        .collection('bookings')
        .doc(bookingId);
    Map<String, dynamic> updateData = {
      'status': newStatus,
    };
    if (rejectionReason != null) {
      updateData['rejectionReason'] = rejectionReason;
    }
    await bookingRef.update(updateData);

    // Optional: If rejected, delete the date from the reserved table
    if (newStatus == 'rejected' && date != null) {
      DocumentReference reservedRef = FirebaseFirestore.instance
          .collection(entityType)
          .doc(entityId)
          .collection('reserved')
          .doc(date);
      await reservedRef.delete();
    }

    _fetchAllBookings(); // Refresh the bookings list after status update
  }

  /// Displays the receipt image in full screen.
  void _showFullImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return GestureDetector(
          onTap: () {
            Navigator.of(context).pop();
          },
          child: Dialog(
            backgroundColor: Colors.transparent,
            child: InteractiveViewer(
              child: Image.network(imageUrl),
            ),
          ),
        );
      },
    );
  }

  /// Shows a dialog to input the rejection reason.
  Future<void> _showRejectionDialog(
  String entityType,
  String entityId,
  String bookingId,
  String date,
) async {
  final TextEditingController rejectionReasonController =
      TextEditingController();

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0), // Rounded corners
        ),
        child: Container(
          padding: EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15.0),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min, // Shrinks the dialog to fit content
            children: [
              // Title
              Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.redAccent, size: 28),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Rejection Reason',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 15),

              // Text Field for Rejection Reason
              TextField(
                controller: rejectionReasonController,
                decoration: InputDecoration(
                  labelText: 'Enter reason for rejection',
                  labelStyle: TextStyle(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: BorderSide(color: Colors.blueAccent, width: 2),
                  ),
                ),
                maxLines: 3,
              ),
              SizedBox(height: 20),

              // Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Cancel Button
                  TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey[600], padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      backgroundColor: Colors.grey[200],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop(); // Close the dialog
                    },
                  ),

                  // Submit Button
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                    child: Text(
                      'Submit',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                    onPressed: () async {
                      String rejectionReason =
                          rejectionReasonController.text.trim();
                      if (rejectionReason.isNotEmpty) {
                        await _updateBookingStatus(
                          entityType,
                          entityId,
                          bookingId,
                          'rejected',
                          rejectionReason: rejectionReason,
                          date: date,
                        );
                        Navigator.of(context).pop();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content:
                                Text('Please enter a reason for rejection.'),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// Shows a confirmation dialog before confirming the booking.
Future<void> _showConfirmationDialog(
  String entityType,
  String entityId,
  String bookingId,
) async {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0),
        ),
        child: Container(
          padding: EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15.0),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title and Icon
              Row(
                children: [
                  Icon(Icons.check_circle_outline, color: Colors.green, size: 28),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Confirm Booking',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 15),

              // Confirmation Text
              Text(
                'Are you sure you want to confirm this booking?',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),

              // Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Cancel Button
                  TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey[600], padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      backgroundColor: Colors.grey[200],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop(); // Close the dialog
                    },
                  ),

                  // Confirm Button
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                    child: Text(
                      'Confirm',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                    onPressed: () async {
                      await _updateBookingStatus(
                        entityType,
                        entityId,
                        bookingId,
                        'confirmed',
                      );
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}


  /// Builds the UI for each booking list based on status.
  Widget _buildBookingList(String status) {
    final bookingsByStatus =
        _bookings.where((booking) => booking['status'] == status).toList();

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
          bool isExpanded = _expanded[index];

          return Card(
            elevation: 3,
            margin: EdgeInsets.symmetric(vertical: 8.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Column(
              children: [
                // Header Row with expand icon
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.grey[300],
                        radius: 30,
                        child: Icon(Icons.event, size: 30, color: Colors.grey[700]),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              booking['entityName'] ?? 'No Name',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Date: ${booking['date'] ?? 'N/A'}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(isExpanded ? Icons.expand_less : Icons.expand_more),
                        onPressed: () {
                          setState(() {
                            _expanded[index] = !isExpanded;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                // Expanded content
                if (isExpanded)
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Divider(),
                        Text(
                          'User Details',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
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
                        if (status == 'processing_payment')
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
                                      _showConfirmationDialog(
                                        booking['entityType'],
                                        booking['entityId'],
                                        booking['bookingId'],
                                      );
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
                                      _showRejectionDialog(
                                        booking['entityType'],
                                        booking['entityId'],
                                        booking['bookingId'],
                                        booking['date'],
                                      );
                                    },
                                    icon: Icon(Icons.close),
                                    label: Text('Reject'),
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
                          )
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

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Color(0xFF0A73B7); // Blue

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Manage Reservations and Payments',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20.0,
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
            Tab(text: 'Rejected'), // Changed to Rejected
          ],
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildBookingList('processing_payment'),
                _buildBookingList('confirmed'),
                _buildBookingList('rejected'), // Changed to Rejected
              ],
            ),
    );
  }
}
