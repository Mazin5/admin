import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';

class ManageVendorService extends StatefulWidget {
  @override
  _ManageVendorServiceState createState() => _ManageVendorServiceState();
}

class _ManageVendorServiceState extends State<ManageVendorService> {
  Future<List<Map<String, dynamic>>> _fetchVendors() async {
    List<Map<String, dynamic>> vendors = [];

    try {
      // Fetch vendors from Firestore with status 'pending' or 'verified'
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('vendors')
          .where('status', whereIn: ['pending', 'verified'])
          .get();

      print('Vendors fetched: ${snapshot.docs.length}');

      for (var doc in snapshot.docs) {
        String uid = doc.id;
        Map<String, dynamic> vendorData = doc.data() as Map<String, dynamic>;

        // Fetch service details from Realtime Database
        DatabaseReference serviceRef = FirebaseDatabase.instance.reference().child(vendorData['serviceType']).child(uid);
        DatabaseEvent event = await serviceRef.once();
        DataSnapshot serviceSnapshot = event.snapshot;

        if (serviceSnapshot.value != null) {
          Map<String, dynamic> serviceData = Map<String, dynamic>.from(serviceSnapshot.value as Map<dynamic, dynamic>);
          vendors.add({
            'uid': uid,
            'vendorData': vendorData,
            'serviceData': serviceData,
          });

          print('Vendor data: $vendorData');
          print('Service data: $serviceData');
        } else {
          print('No service data found for UID: $uid');
        }
      }
    } catch (e) {
      print('Error fetching vendors: $e');
    }

    return vendors;
  }

  Future<void> _updateVendorStatus(String uid, String serviceType, String newStatus) async {
    try {
      // Update status in Firestore
      await FirebaseFirestore.instance.collection('vendors').doc(uid).update({'status': newStatus});
      
      // Update status in Realtime Database
      DatabaseReference serviceRef = FirebaseDatabase.instance.reference().child(serviceType).child(uid);
      await serviceRef.update({'status': newStatus});
      
      print('Vendor status updated to $newStatus for UID: $uid');

      // Refresh the list of vendors
      setState(() {});
    } catch (e) {
      print('Error updating vendor status: $e');
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
        title: Text('Manage Vendor Service'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchVendors(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No vendors found.'));
          }

          List<Map<String, dynamic>> vendors = snapshot.data!;

          return ListView.builder(
            itemCount: vendors.length,
            itemBuilder: (context, index) {
              Map<String, dynamic> vendor = vendors[index];
              Map<String, dynamic> vendorData = vendor['vendorData'];
              Map<String, dynamic> serviceData = vendor['serviceData'];
              String status = vendorData['status'];
              Color cardColor = status == 'verified' ? Colors.lightGreen[100]! : Colors.orange[100]!;

              return Card(
                color: cardColor,
                margin: EdgeInsets.all(10.0),
                child: Padding(
                  padding: EdgeInsets.all(10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Email: ${vendorData['email']}'),
                      Text('Service Type: ${vendorData['serviceType']}'),
                      Text('Name: ${serviceData['name']}'),
                      Text('Phone: ${serviceData['phone']}'),
                      Text('Location: ${serviceData['location']}'),
                      Text('Description: ${serviceData['description']}'),
                      Text('Price: ${serviceData['price']}'),
                      Text('Status: $status', style: TextStyle(fontWeight: FontWeight.bold)),
                      serviceData['pictures'] != null && (serviceData['pictures'] as List<dynamic>).isNotEmpty
                          ? Wrap(
                              spacing: 10,
                              children: (serviceData['pictures'] as List<dynamic>).map((url) {
                                return GestureDetector(
                                  onTap: () => _showFullImage(context, url),
                                  child: Image.network(url, width: 100, height: 100),
                                );
                              }).toList(),
                            )
                          : Text('No pictures found'),
                      SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              _updateVendorStatus(vendor['uid'], vendorData['serviceType'], 'verified');
                            },
                            child: Text('Verify'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              _updateVendorStatus(vendor['uid'], vendorData['serviceType'], 'pending');
                            },
                            child: Text('Suspend'),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
