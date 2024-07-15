import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

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
    DatabaseReference venuesRef = FirebaseDatabase.instance.reference().child('venue');

    try {
      DatabaseEvent venuesEvent = await venuesRef.once();
      DataSnapshot venuesSnapshot = venuesEvent.snapshot;

      if (venuesSnapshot.value != null) {
        Map<dynamic, dynamic> venuesMap = Map<dynamic, dynamic>.from(venuesSnapshot.value as Map);
        List<Map<String, dynamic>> tempPayments = [];

        for (var venueId in venuesMap.keys) {
          DatabaseReference bookingsRef = venuesRef.child(venueId).child('bookings');
          DatabaseEvent bookingsEvent = await bookingsRef.once();
          DataSnapshot bookingsSnapshot = bookingsEvent.snapshot;

          if (bookingsSnapshot.value != null) {
            Map<dynamic, dynamic> bookingsMap = Map<dynamic, dynamic>.from(bookingsSnapshot.value as Map);
            for (var key in bookingsMap.keys) {
              Map<String, dynamic> bookingData = Map<String, dynamic>.from(bookingsMap[key] as Map);
              if (bookingData.containsKey('transactionCode') && bookingData.containsKey('receiptImageUrl') && bookingData['status'] != 'rejected' && bookingData['status'] != 'confirmed') {
                bookingData['bookingId'] = key;
                bookingData['venueId'] = venueId;
                bookingData['venueName'] = venuesMap[venueId]['name']; // Assuming 'name' is the field for venue name

                // Fetch user data from the 'users' node
                DatabaseReference userRef = FirebaseDatabase.instance.reference().child('users').child(bookingData['userId']);
                DatabaseEvent userEvent = await userRef.once();
                DataSnapshot userSnapshot = userEvent.snapshot;

                if (userSnapshot.value != null) {
                  Map<String, dynamic> userData = Map<String, dynamic>.from(userSnapshot.value as Map);
                  bookingData['userFullName'] = userData['name']; // Assuming 'name' is the field for user's full name
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
        print('Payments fetched: ${_payments.length}');
        _payments.forEach((payment) {
          print('Payment: $payment');
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        print('No venues found');
      }
    } catch (error) {
      setState(() {
        _isLoading = false;
      });
      print('Error fetching payments: $error');
    }
  }

  Future<void> _updateBookingStatus(String venueId, String bookingId, String newStatus, {String? rejectionReason}) async {
    DatabaseReference bookingRef = FirebaseDatabase.instance.reference().child('venue').child(venueId).child('bookings').child(bookingId);
    Map<String, dynamic> updateData = {'status': newStatus};
    if (rejectionReason != null) {
      updateData['rejectionReason'] = rejectionReason;
    }
    await bookingRef.update(updateData);

    // Move to archive if confirmed
    if (newStatus == 'confirmed') {
      DatabaseReference archiveRef = FirebaseDatabase.instance.reference().child('archives').child(venueId).child(bookingId);
      DataSnapshot snapshot = (await bookingRef.once()).snapshot;
      await archiveRef.set(snapshot.value);
      await bookingRef.remove();
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

  Future<void> _showRejectionDialog(String venueId, String bookingId) async {
    final TextEditingController rejectionReasonController = TextEditingController();

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
                  await _updateBookingStatus(venueId, bookingId, 'rejected', rejectionReason: rejectionReason);
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please enter a reason for rejection.')),
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
                            Text('Venue: ${payment['venueName']}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            SizedBox(height: 5),
                            Text('Date: ${payment['date']}', style: TextStyle(fontSize: 16)),
                            SizedBox(height: 5),
                            Text('User Email: ${payment['userName']}', style: TextStyle(fontSize: 16)),
                            SizedBox(height: 5),
                            Text('User Full Name: ${payment['userFullName']}', style: TextStyle(fontSize: 16)),
                            SizedBox(height: 5),
                            Text('Transaction Code: ${payment['transactionCode']}', style: TextStyle(fontSize: 16)),
                            SizedBox(height: 5),
                            Text('Note: ${payment['note']}', style: TextStyle(fontSize: 16)),
                            SizedBox(height: 5),
                            Text('Status: ${payment['status']}', style: TextStyle(fontSize: 16)),
                            SizedBox(height: 10),
                            payment['receiptImageUrl'] != null
                                ? GestureDetector(
                                    onTap: () => _showFullImage(context, payment['receiptImageUrl']),
                                    child: Image.network(payment['receiptImageUrl']),
                                  )
                                : Text('No receipt image available'),
                            SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                ElevatedButton(
                                  onPressed: () {
                                    _updateBookingStatus(payment['venueId'], payment['bookingId'], 'confirmed');
                                  },
                                  child: Text('Confirm'),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    _showRejectionDialog(payment['venueId'], payment['bookingId']);
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
