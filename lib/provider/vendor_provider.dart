import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class VendorProvider with ChangeNotifier {
  List<Map<String, dynamic>> _vendors = [];

  List<Map<String, dynamic>> get vendors => _vendors;

  VendorProvider() {
    fetchVendors();
  }

  Future<void> fetchVendors() async {
    List<Map<String, dynamic>> vendors = [];

    try {
      // Fetch vendors from Firestore with status 'pending', 'verified', or 'pending_update'
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('vendors')
          .where('status', whereIn: ['pending', 'verified', 'pending_update'])
          .get();

      for (var doc in snapshot.docs) {
        String uid = doc.id;
        Map<String, dynamic> vendorData = doc.data() as Map<String, dynamic>;

        // Fetch service details from Firestore
        DocumentSnapshot serviceDoc = await FirebaseFirestore.instance
            .collection(vendorData['serviceType'])
            .doc(uid)
            .get();

        if (serviceDoc.exists) {
          Map<String, dynamic> serviceData = serviceDoc.data() as Map<String, dynamic>;
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

      // Update status in the service collection in Firestore
      await FirebaseFirestore.instance.collection(serviceType).doc(uid).update({'status': newStatus});
      
      // Refresh vendors list
      fetchVendors();
    } catch (e) {
      print('Error updating vendor status: $e');
    }
  }
}
