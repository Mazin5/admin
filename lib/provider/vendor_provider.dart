import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';

class VendorProvider with ChangeNotifier {
  List<Map<String, dynamic>> _vendors = [];

  List<Map<String, dynamic>> get vendors => _vendors;

  VendorProvider() {
    fetchVendors();
  }

  Future<void> fetchVendors() async {
    List<Map<String, dynamic>> vendors = [];

    try {
      // Fetch vendors from Firestore with status 'pending' or 'verified'
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('vendors')
          .where('status', whereIn: ['pending', 'verified'])
          .get();

      for (var doc in snapshot.docs) {
        String uid = doc.id;
        Map<String, dynamic> vendorData = doc.data() as Map<String, dynamic>;

        // Fetch service details from Realtime Database
        DatabaseReference serviceRef = FirebaseDatabase.instance.ref().child(vendorData['serviceType']).child(uid);
        DatabaseEvent event = await serviceRef.once();
        DataSnapshot serviceSnapshot = event.snapshot;

        if (serviceSnapshot.value != null) {
          Map<String, dynamic> serviceData = Map<String, dynamic>.from(serviceSnapshot.value as Map<dynamic, dynamic>);
          vendors.add({
            'uid': uid,
            'vendorData': vendorData,
            'serviceData': serviceData,
          });
        }
      }
    } catch (e) {
      print('Error fetching vendors: $e');
    }

    _vendors = vendors;
    notifyListeners();
  }

  Future<void> updateVendorStatus(String uid, String serviceType, String newStatus) async {
    try {
      // Update status in Firestore
      await FirebaseFirestore.instance.collection('vendors').doc(uid).update({'status': newStatus});

      // Update status in Realtime Database
      DatabaseReference serviceRef = FirebaseDatabase.instance.ref().child(serviceType).child(uid);
      await serviceRef.update({'status': newStatus});
      
      // Refresh vendors list
      fetchVendors();
    } catch (e) {
      print('Error updating vendor status: $e');
    }
  }
}
