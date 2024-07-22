import 'package:admin/provider/vendor_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ManageVendorService extends StatelessWidget {
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
    final vendorProvider = Provider.of<VendorProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Vendor Service'),
      ),
      body: vendorProvider.vendors.isEmpty
          ? Center(child: Text('No vendors found.'))
          : RefreshIndicator(
              onRefresh: () async {
                await vendorProvider.fetchVendors(); // Assuming this method exists to refresh the list
              },
              child: ListView.builder(
                itemCount: vendorProvider.vendors.length,
                itemBuilder: (context, index) {
                  Map<String, dynamic> vendor = vendorProvider.vendors[index];
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
                                  vendorProvider.updateVendorStatus(vendor['uid'], vendorData['serviceType'], 'verified');
                                },
                                child: Text('Verify'),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  vendorProvider.updateVendorStatus(vendor['uid'], vendorData['serviceType'], 'pending');
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
              ),
            ),
    );
  }
}
