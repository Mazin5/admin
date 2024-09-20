import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ViewPaymentsScreen extends StatefulWidget {
  @override
  _ViewPaymentsScreenState createState() => _ViewPaymentsScreenState();
}

class _ViewPaymentsScreenState extends State<ViewPaymentsScreen> {
  List<Map<String, dynamic>> _payments = [];
  bool _isLoading = true;
  final List<String> _statuses = ['pending', 'confirmed', 'rejected', 'archived'];
  late List<bool> _expanded; // Tracks expansion state of each card

  @override
  void initState() {
    super.initState();
    _fetchAllPayments();
  }

  /// Fetches all payments from Firestore across specified collections.
  Future<void> _fetchAllPayments() async {
    final List<String> tables = ['venue', 'singer', 'decoration', 'meal'];

    try {
      List<Map<String, dynamic>> tempPayments = [];

      for (String table in tables) {
        QuerySnapshot tableSnapshot =
            await FirebaseFirestore.instance.collection(table).get();

        for (var entityDoc in tableSnapshot.docs) {
          String entityId = entityDoc.id;
          QuerySnapshot bookingsSnapshot =
              await entityDoc.reference.collection('bookings').get();

          for (var bookingDoc in bookingsSnapshot.docs) {
            Map<String, dynamic> bookingData =
                bookingDoc.data() as Map<String, dynamic>;

            // Ensure necessary fields are present
            if (bookingData.containsKey('transactionCode') &&
                bookingData.containsKey('receiptImageUrl')) {
              bookingData['bookingId'] = bookingDoc.id;
              bookingData['entityId'] = entityId;
              bookingData['entityType'] = table;
              bookingData['entityName'] = entityDoc['name'];

              // Fetch user data from the 'users' collection
              DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
                  .collection('users')
                  .doc(bookingData['userId'])
                  .get();

              if (userSnapshot.exists) {
                Map<String, dynamic> userData =
                    userSnapshot.data() as Map<String, dynamic>;

                bookingData['lastname'] =
                    '${userData['name'] ?? ''} ${userData['lastName'] ?? ''}';
                bookingData['email'] = userData['email'] ?? '';
                bookingData['phoneNumber'] = userData['phoneNumber'] ?? '';
              }

              tempPayments.add(bookingData);
            }
          }
        }
      }

      setState(() {
        _payments = tempPayments;
        _isLoading = false;
        _expanded = List<bool>.filled(_payments.length, false);
      });
    } catch (error) {
      print('Error fetching payments: $error');
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
      if (newStatus == 'confirmed') 'archive_status': true
    };
    if (rejectionReason != null) {
      updateData['rejectionReason'] = rejectionReason;
    }
    await bookingRef.update(updateData);

    if (newStatus == 'rejected' && date != null) {
      DocumentReference reservedRef = FirebaseFirestore.instance
          .collection(entityType)
          .doc(entityId)
          .collection('reserved')
          .doc(date);
      await reservedRef.delete();
    }

    _fetchAllPayments();
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
        return AlertDialog(
          title: Text('Rejection Reason'),
          content: TextField(
            controller: rejectionReasonController,
            decoration: InputDecoration(
              labelText: 'Reason for rejection',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: Text('Submit'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              onPressed: () async {
                String rejectionReason = rejectionReasonController.text.trim();
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
        );
      },
    );
  }

  /// Returns the color associated with a given status.
  Color _getStatusColor(String status) {
    switch (status) {
      case 'confirmed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      case 'archived':
        return Colors.blueGrey;
      default:
        return Colors.grey;
    }
  }

  /// Determines if the status is editable.
  bool _isStatusEditable(String status) {
    // Only 'pending' status is editable
    return status == 'pending';
  }

  @override
  Widget build(BuildContext context) {
    // Define your color scheme
    final Color primaryColor = Color(0xFF0A73B7); // Blue

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'View Payments',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryColor,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _payments.isEmpty
              ? Center(
                  child: Text(
                    'No payments found.',
                    style: TextStyle(fontSize: 18),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchAllPayments,
                  child: ListView.builder(
                    padding: EdgeInsets.all(10.0),
                    itemCount: _payments.length,
                    itemBuilder: (context, index) {
                      final payment = _payments[index];
                      String currentStatus = payment['status'];
                      bool isExpanded = _expanded[index];

                      return Card(
                        elevation: 3,
                        margin: EdgeInsets.symmetric(vertical: 8.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: Column(
                          children: [
                            // Header Row
                            Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 8.0, vertical: 8.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // Icon
                                  CircleAvatar(
                                    backgroundColor: Colors.grey[300],
                                    radius: 30,
                                    child: Icon(
                                      Icons.payment,
                                      size: 30,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  // Title and Subtitle
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          payment['entityName'] ?? 'No Name',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          payment['entityType'] ?? 'No Type',
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
                                  SizedBox(width: 10),
                                  // Status and Expand Icon
                                  Column(
                                    children: [
                                      // Status Dropdown or Text
                                      _isStatusEditable(currentStatus)
                                          ? Container(
                                              width: 100,
                                              child:
                                                  DropdownButtonHideUnderline(
                                                child: DropdownButton<String>(
                                                  value: currentStatus,
                                                  icon: Icon(
                                                    Icons.arrow_drop_down,
                                                    color:
                                                        _getStatusColor(currentStatus),
                                                  ),
                                                  style: TextStyle(
                                                    color:
                                                        _getStatusColor(currentStatus),
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  items: _statuses
                                                      .where((status) =>
                                                          status != 'archived')
                                                      .map((String status) {
                                                    return DropdownMenuItem<String>(
                                                      value: status,
                                                      child: Text(
                                                        status.toUpperCase(),
                                                        style: TextStyle(
                                                          color:
                                                              _getStatusColor(status),
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                    );
                                                  }).toList(),
                                                  onChanged: (String? newStatus) async {
                                                    if (newStatus != null &&
                                                        newStatus != currentStatus) {
                                                      if (newStatus == 'rejected') {
                                                        await _showRejectionDialog(
                                                          payment['entityType'],
                                                          payment['entityId'],
                                                          payment['bookingId'],
                                                          payment['date'],
                                                        );
                                                      } else {
                                                        await _updateBookingStatus(
                                                          payment['entityType'],
                                                          payment['entityId'],
                                                          payment['bookingId'],
                                                          newStatus,
                                                        );
                                                      }
                                                    }
                                                  },
                                                ),
                                              ),
                                            )
                                          : Container(
                                              width: 100,
                                              child: Text(
                                                currentStatus.toUpperCase(),
                                                style: TextStyle(
                                                  color:
                                                      _getStatusColor(currentStatus),
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                textAlign: TextAlign.right,
                                              ),
                                            ),
                                      // Expand/Collapse Icon
                                      IconButton(
                                        icon: Icon(
                                          isExpanded
                                              ? Icons.expand_less
                                              : Icons.expand_more,
                                          color: Colors.grey[700],
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _expanded[index] = !isExpanded;
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            // Expanded Content
                            if (isExpanded)
                              Padding(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 16.0, vertical: 8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Divider(),
                                    Text(
                                      'Payment Details',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    ListTile(
                                      leading: Icon(Icons.calendar_today,
                                          color: primaryColor),
                                      title: Text('Date: ${payment['date']}'),
                                    ),
                                    ListTile(
                                      leading: Icon(Icons.email,
                                          color: primaryColor),
                                      title:
                                          Text('User Email: ${payment['email']}'),
                                    ),
                                    ListTile(
                                      leading:
                                          Icon(Icons.person, color: primaryColor),
                                      title:
                                          Text('User Name: ${payment['lastname']}'),
                                    ),
                                    ListTile(
                                      leading:
                                          Icon(Icons.phone, color: primaryColor),
                                      title: Text(
                                          'Phone Number: ${payment['phoneNumber']}'),
                                    ),
                                    ListTile(
                                      leading:
                                          Icon(Icons.code, color: primaryColor),
                                      title: Text(
                                          'Transaction Code: ${payment['transactionCode']}'),
                                    ),
                                    if (payment['note'] != null &&
                                        payment['note'].isNotEmpty)
                                      ListTile(
                                        leading:
                                            Icon(Icons.note, color: primaryColor),
                                        title: Text('Note: ${payment['note']}'),
                                      ),
                                    SizedBox(height: 16),
                                    // Receipt Image
                                    Center(
                                      child: payment['receiptImageUrl'] != null
                                          ? GestureDetector(
                                              onTap: () => _showFullImage(
                                                  context,
                                                  payment['receiptImageUrl']),
                                              child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(8.0),
                                                child: Image.network(
                                                  payment['receiptImageUrl'],
                                                  width: 200,
                                                  height: 200,
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                            )
                                          : Text(
                                              'No receipt image available',
                                              style:
                                                  TextStyle(color: Colors.grey[600]),
                                            ),
                                    ),
                                    SizedBox(height: 16),
                                    // Action Buttons
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        ElevatedButton.icon(
                                          onPressed: () {
                                            _updateBookingStatus(
                                              payment['entityType'],
                                              payment['entityId'],
                                              payment['bookingId'],
                                              'confirmed',
                                            );
                                          },
                                          icon: Icon(Icons.check),
                                          label: Text('Confirm'),
                                          style: ElevatedButton.styleFrom(
                                            foregroundColor: Colors.white,
                                            backgroundColor: Colors.green,
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 16, vertical: 12),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8.0),
                                            ),
                                          ),
                                        ),
                                        ElevatedButton.icon(
                                          onPressed: () {
                                            _showRejectionDialog(
                                              payment['entityType'],
                                              payment['entityId'],
                                              payment['bookingId'],
                                              payment['date'],
                                            );
                                          },
                                          icon: Icon(Icons.close),
                                          label: Text('Reject'),
                                          style: ElevatedButton.styleFrom(
                                            foregroundColor: Colors.white,
                                            backgroundColor: Colors.red,
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 16, vertical: 12),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8.0),
                                            ),
                                          ),
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
                ),
    );
  }
}
