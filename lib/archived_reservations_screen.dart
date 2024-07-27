import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ArchivedReservationsScreen extends StatefulWidget {
  @override
  _ArchivedReservationsScreenState createState() => _ArchivedReservationsScreenState();
}

class _ArchivedReservationsScreenState extends State<ArchivedReservationsScreen> {
  List<Map<String, dynamic>> _archivedReservations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchArchivedReservations();
  }

  Future<void> _fetchArchivedReservations() async {
    try {
      List<Map<String, dynamic>> tempArchivedReservations = [];
      QuerySnapshot archivesSnapshot = await FirebaseFirestore.instance.collection('archives').get();

      for (var venueDoc in archivesSnapshot.docs) {
        String venueId = venueDoc.id;
        QuerySnapshot venueArchivesSnapshot = await venueDoc.reference.collection('bookings').get();

        for (var bookingDoc in venueArchivesSnapshot.docs) {
          Map<String, dynamic> archiveData = bookingDoc.data() as Map<String, dynamic>;
          archiveData['bookingId'] = bookingDoc.id;
          archiveData['venueId'] = venueId;

          // Fetch user data from Firestore using the userId
          DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(archiveData['userId']).get();

          if (userDoc.exists) {
            archiveData['userFullName'] = '${userDoc['name']} ${userDoc['lastName']}';
            archiveData['userName'] = userDoc['email'];
            archiveData['phoneNumber'] = userDoc['phoneNumber'];
          } else {
            archiveData['userFullName'] = 'Not Available';
            archiveData['userName'] = 'Not Available';
            archiveData['phoneNumber'] = 'Not Available';
          }

          // Fetch venue data from Firestore
          DocumentSnapshot venueDocSnapshot = await FirebaseFirestore.instance.collection('vendors').doc(venueId).get();
          if (venueDocSnapshot.exists) {
            archiveData['name'] = venueDocSnapshot['name'] ?? 'No Name';
          } else {
            archiveData['name'] = 'No Name';
          }

          tempArchivedReservations.add(archiveData);
        }
      }

      setState(() {
        _archivedReservations = tempArchivedReservations;
        _isLoading = false;
      });
      print('Archived reservations fetched: ${_archivedReservations.length}');
      _archivedReservations.forEach((reservation) {
        print('Archived reservation: $reservation');
      });
    } catch (error) {
      setState(() {
        _isLoading = false;
      });
      print('Error fetching archived reservations: $error');
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Archived Reservations'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _archivedReservations.isEmpty
              ? Center(child: Text('No archived reservations found.'))
              : ListView.builder(
                  itemCount: _archivedReservations.length,
                  itemBuilder: (context, index) {
                    final reservation = _archivedReservations[index];
                    return Card(
                      margin: EdgeInsets.all(10.0),
                      child: Padding(
                        padding: EdgeInsets.all(10.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Venue: ${reservation['name']}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            SizedBox(height: 5),
                            Text('Date: ${reservation['date']}', style: TextStyle(fontSize: 16)),
                            SizedBox(height: 5),
                            Text('User Email: ${reservation['userName']}', style: TextStyle(fontSize: 16)),
                            SizedBox(height: 5),
                            Text('User Full Name: ${reservation['userFullName']}', style: TextStyle(fontSize: 16)),
                            SizedBox(height: 5),
                            Text('User Phone Number: ${reservation['phoneNumber']}', style: TextStyle(fontSize: 16)),
                            SizedBox(height: 5),
                            Text('Transaction Code: ${reservation['transactionCode']}', style: TextStyle(fontSize: 16)),
                            SizedBox(height: 5),
                            Text('Note: ${reservation['note']}', style: TextStyle(fontSize: 16)),
                            SizedBox(height: 5),
                            Text('Status: ${reservation['status']}', style: TextStyle(fontSize: 16)),
                            SizedBox(height: 10),
                            reservation['receiptImageUrl'] != null
                                ? GestureDetector(
                                    onTap: () => _showFullImage(context, reservation['receiptImageUrl']),
                                    child: Image.network(
                                      reservation['receiptImageUrl'],
                                      width: 100, // Set smaller width
                                      height: 100, // Set smaller height
                                    ),
                                  )
                                : Text('No receipt image available'),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
