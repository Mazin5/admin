import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ViewPaymentsScreen extends StatefulWidget {
  @override
  _ViewPaymentsScreenState createState() => _ViewPaymentsScreenState();
}

class _ViewPaymentsScreenState extends State<ViewPaymentsScreen> {
  List<Map<String, dynamic>> _payments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAllPayments();
  }

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

            if (bookingData.containsKey('transactionCode') &&
                bookingData.containsKey('receiptImageUrl') &&
                bookingData['status'] != 'rejected' &&
                bookingData['status'] != 'confirmed') {
              bookingData['bookingId'] = bookingDoc.id;
              bookingData['entityId'] = entityId;
              bookingData['entityType'] =
                  table; // Add the type for identifying the table
              bookingData['entityName'] = entityDoc[
                  'name']; // Assuming 'name' is the field for entity name

              // Fetch user data from the 'users' collection
              DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
                  .collection('users')
                  .doc(bookingData['userId'])
                  .get();

              if (userSnapshot.exists) {
                Map<String, dynamic> userData =
                    userSnapshot.data() as Map<String, dynamic>;

                bookingData['lastname'] =
                    userData['name'] + ' ' + userData['lastName'];
                bookingData['email'] = userData['email'];
                bookingData['phoneNumber'] = userData['phoneNumber'];
              }

              tempPayments.add(bookingData);
            }
          }
        }
      }

      setState(() {
        _payments = tempPayments;
        _isLoading = false;
      });
    } catch (error) {
      print('Error fetching payments: $error'); // Add logging for debugging
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateBookingStatus(
      String entityType, String entityId, String bookingId, String newStatus,
      {String? rejectionReason, String? date}) async {
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
            child: Container(
              child: Image.network(imageUrl),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showRejectionDialog(
      String entityType, String entityId, String bookingId, String date) async {
    final TextEditingController rejectionReasonController =
        TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Rejection Reason'),
          content: TextField(
            controller: rejectionReasonController,
            decoration: InputDecoration(labelText: 'Reason for rejection'),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Submit'),
              onPressed: () async {
                String rejectionReason = rejectionReasonController.text;
                if (rejectionReason.isNotEmpty) {
                  await _updateBookingStatus(
                      entityType, entityId, bookingId, 'rejected',
                      rejectionReason: rejectionReason, date: date);
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Please enter a reason for rejection.')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('View Payments'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _payments.isEmpty
              ? Center(child: Text('No payments found.'))
              : ListView.builder(
                  itemCount: _payments.length,
                  itemBuilder: (context, index) {
                    final payment = _payments[index];
                    return Card(
                      margin: EdgeInsets.all(10.0),
                      child: Padding(
                        padding: EdgeInsets.all(10.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Entity: ${payment['entityName']}',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold)),
                            SizedBox(height: 5),
                            Text('Entity Type: ${payment['entityType']}',
                                style: TextStyle(fontSize: 16)),
                            SizedBox(height: 5),
                            Text('Date: ${payment['date']}',
                                style: TextStyle(fontSize: 16)),
                            SizedBox(height: 5),
                            Text('User Email: ${payment['email']}',
                                style: TextStyle(fontSize: 16)),
                            SizedBox(height: 5),
                            Text('User Full Name: ${payment['lastname']}',
                                style: TextStyle(fontSize: 16)),
                            SizedBox(height: 5),
                            Text('Phone Number: ${payment['phoneNumber']}',
                                style: TextStyle(fontSize: 16)),
                            SizedBox(height: 5),
                            Text(
                                'Transaction Code: ${payment['transactionCode']}',
                                style: TextStyle(fontSize: 16)),
                            SizedBox(height: 5),
                            Text('Note: ${payment['note']}',
                                style: TextStyle(fontSize: 16)),
                            SizedBox(height: 5),
                            Text('Status: ${payment['status']}',
                                style: TextStyle(fontSize: 16)),
                            SizedBox(height: 10),
                            payment['receiptImageUrl'] != null
                                ? GestureDetector(
                                    onTap: () => _showFullImage(
                                        context, payment['receiptImageUrl']),
                                    child: Image.network(
                                        payment['receiptImageUrl']),
                                  )
                                : Text('No receipt image available'),
                            SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                ElevatedButton(
                                  onPressed: () {
                                    _updateBookingStatus(
                                        payment['entityType'],
                                        payment['entityId'],
                                        payment['bookingId'],
                                        'confirmed');
                                  },
                                  child: Text('Confirm'),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    _showRejectionDialog(
                                        payment['entityType'],
                                        payment['entityId'],
                                        payment['bookingId'],
                                        payment['date']);
                                  },
                                  child: Text('Reject'),
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
