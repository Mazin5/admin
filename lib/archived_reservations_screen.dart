import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

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
    DatabaseReference archivesRef = FirebaseDatabase.instance.reference().child('archives');

    try {
      DatabaseEvent archivesEvent = await archivesRef.once();
      DataSnapshot archivesSnapshot = archivesEvent.snapshot;

      if (archivesSnapshot.value != null) {
        Map<dynamic, dynamic> archivesMap = Map<dynamic, dynamic>.from(archivesSnapshot.value as Map);
        List<Map<String, dynamic>> tempArchivedReservations = [];

        for (var venueId in archivesMap.keys) {
          Map<dynamic, dynamic> bookingsMap = Map<dynamic, dynamic>.from(archivesMap[venueId] as Map);
          for (var key in bookingsMap.keys) {
            Map<String, dynamic> bookingData = Map<String, dynamic>.from(bookingsMap[key] as Map);
            bookingData['bookingId'] = key;
            bookingData['venueId'] = venueId;
            tempArchivedReservations.add(bookingData);
          }
        }

        setState(() {
          _archivedReservations = tempArchivedReservations;
          _isLoading = false;
        });
        print('Archived reservations fetched: ${_archivedReservations.length}');
        _archivedReservations.forEach((reservation) {
          print('Reservation: $reservation');
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        print('No archived reservations found');
      }
    } catch (error) {
      setState(() {
        _isLoading = false;
      });
      print('Error fetching archived reservations: $error');
    }
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
                            Text('Venue ID: ${reservation['venueId']}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            SizedBox(height: 5),
                            Text('Date: ${reservation['date']}', style: TextStyle(fontSize: 16)),
                            SizedBox(height: 5),
                            Text('User ID: ${reservation['userId']}', style: TextStyle(fontSize: 16)),
                            SizedBox(height: 5),
                            Text('User Full Name: ${reservation['userFullName']}', style: TextStyle(fontSize: 16)),
                            SizedBox(height: 5),
                            Text('Transaction Code: ${reservation['transactionCode']}', style: TextStyle(fontSize: 16)),
                            SizedBox(height: 5),
                            Text('Note: ${reservation['note']}', style: TextStyle(fontSize: 16)),
                            SizedBox(height: 5),
                            Text('Status: ${reservation['status']}', style: TextStyle(fontSize: 16)),
                            SizedBox(height: 10),
                            reservation['receiptImageUrl'] != null
                                ? Image.network(reservation['receiptImageUrl'])
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
