import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'provider/vendor_provider.dart';

class ManageVendorService extends StatefulWidget {
  @override
  _ManageVendorServiceState createState() => _ManageVendorServiceState();
}

class _ManageVendorServiceState extends State<ManageVendorService>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, bool> _loadingVendors = {}; // Track loading state for each vendor

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    final vendorProvider = Provider.of<VendorProvider>(context, listen: false);
    vendorProvider.fetchVendors();
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
            child: InteractiveViewer(
              child: Image.network(imageUrl),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showConfirmationDialog(BuildContext context, String action, String vendorId, String serviceType, Function onConfirm) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // Prevent dismiss by tapping outside
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Confirm $action'),
          content: Text('Are you sure you want to $action this vendor?'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Dismiss the dialog
              },
            ),
            TextButton(
              child: Text('Confirm'),
              onPressed: () async {
                Navigator.of(dialogContext).pop(); // Dismiss the dialog
                // Optimistic UI update: update state before confirming backend success
                setState(() {
                  _loadingVendors[vendorId] = true;
                });

                await onConfirm();
                
                // Once done, stop loading
                setState(() {
                  _loadingVendors[vendorId] = false;
                });
              },
            ),
          ],
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
        backgroundColor: Color(0xFF0A73B7),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: [
            Tab(text: 'Verified'),
            Tab(text: 'Pending'),
          ],
        ),
      ),
      body: vendorProvider.vendors.isEmpty
          ? Center(
              child: CircularProgressIndicator(),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildVendorList(
                    vendorProvider.vendors
                        .where((v) => v['vendorData']['status'] == 'verified')
                        .toList(),
                    vendorProvider,
                    isVerifiedTab: true),
                _buildVendorList(
                    vendorProvider.vendors
                        .where((v) => v['vendorData']['status'] == 'pending')
                        .toList(),
                    vendorProvider,
                    isVerifiedTab: false),
              ],
            ),
    );
  }

  Widget _buildVendorList(
      List<Map<String, dynamic>> vendors, VendorProvider vendorProvider,
      {required bool isVerifiedTab}) {
    return RefreshIndicator(
      onRefresh: () async {
        await vendorProvider.fetchVendors();
      },
      child: ListView.builder(
        padding: EdgeInsets.all(10.0),
        itemCount: vendors.length,
        itemBuilder: (context, index) {
          Map<String, dynamic> vendor = vendors[index];
          Map<String, dynamic> vendorData = vendor['vendorData'];
          Map<String, dynamic> serviceData = vendor['serviceData'];
          String status = vendorData['status'];
          String vendorId = vendor['uid'];

          // Get the first picture URL
          String? firstPictureUrl;
          if (serviceData['pictures'] != null &&
              (serviceData['pictures'] as List<dynamic>).isNotEmpty) {
            firstPictureUrl = (serviceData['pictures'] as List<dynamic>).first;
          }

          return Card(
            elevation: 3,
            margin: EdgeInsets.symmetric(vertical: 8.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: ExpansionTile(
              leading: firstPictureUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: Image.network(
                        firstPictureUrl,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                      ),
                    )
                  : CircleAvatar(
                      backgroundColor: Colors.grey[300],
                      radius: 25,
                      child: Icon(
                        Icons.store,
                        size: 25,
                        color: Colors.grey[700],
                      ),
                    ),
              title: Text(
                serviceData['name'] ?? 'No Name',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(vendorData['email'] ?? 'No Email'),
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    children: [
                      // Phone and Location
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.phone, color: Colors.blue),
                              SizedBox(width: 4),
                              Text(
                                serviceData['phone'] ?? 'No Phone',
                                style: TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Icon(Icons.location_on, color: Colors.red),
                              SizedBox(width: 4),
                              Text(
                                serviceData['location'] ?? 'No Location',
                                style: TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      // Description
                      if (serviceData['description'] != null &&
                          serviceData['description'].isNotEmpty)
                        Text(
                          serviceData['description'],
                          style: TextStyle(fontSize: 14),
                        ),
                      SizedBox(height: 8),
                      // Price
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Price: ${serviceData['price'] ?? 'N/A'}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ),
                      SizedBox(height: 8),
                      // Images
                      if (serviceData['pictures'] != null &&
                          (serviceData['pictures'] as List<dynamic>)
                              .isNotEmpty)
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: (serviceData['pictures'] as List<dynamic>)
                                .map((url) {
                              return GestureDetector(
                                onTap: () => _showFullImage(context, url),
                                child: Container(
                                  margin: EdgeInsets.only(right: 10.0),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8.0),
                                    child: Image.network(
                                      url,
                                      width: 80,
                                      height: 80,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      SizedBox(height: 8),
                      // Action Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          if (isVerifiedTab) ...[
                            // Only show Suspend button in the Verified tab
                            ElevatedButton.icon(
                              onPressed: () async {
                                _showConfirmationDialog(
                                  context,
                                  'suspend',
                                  vendorId,
                                  vendorData['serviceType'],
                                  () async {
                                    // Optimistic UI update: Suspend the vendor locally
                                    setState(() {
                                      vendorData['status'] = 'pending';
                                    });
                                    await vendorProvider.updateVendorStatus(
                                      vendorId,
                                      vendorData['serviceType'],
                                      'pending',
                                    );
                                  },
                                );
                              },
                              icon: _loadingVendors[vendorId] == true
                                  ? SizedBox(
                                      height: 16,
                                      width: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                            Colors.white),
                                      ),
                                    )
                                  : Icon(Icons.pause),
                              label: _loadingVendors[vendorId] == true
                                  ? Text('Suspending...')
                                  : Text('Suspend'),
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor: Colors.orange,
                                padding: EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                textStyle: TextStyle(fontSize: 14),
                              ),
                            ),
                          ] else ...[
                            // Only show Verify button in the Pending tab
                            ElevatedButton.icon(
                              onPressed: () async {
                                _showConfirmationDialog(
                                  context,
                                  'verify',
                                  vendorId,
                                  vendorData['serviceType'],
                                  () async {
                                    // Optimistic UI update: Verify the vendor locally
                                    setState(() {
                                      vendorData['status'] = 'verified';
                                    });
                                    await vendorProvider.updateVendorStatus(
                                      vendorId,
                                      vendorData['serviceType'],
                                      'verified',
                                    );
                                  },
                                );
                              },
                              icon: _loadingVendors[vendorId] == true
                                  ? SizedBox(
                                      height: 16,
                                      width: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                            Colors.white),
                                      ),
                                    )
                                  : Icon(Icons.check),
                              label: _loadingVendors[vendorId] == true
                                  ? Text('Verifying...')
                                  : Text('Verify'),
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor: Colors.green,
                                padding: EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                textStyle: TextStyle(fontSize: 14),
                              ),
                            ),
                          ]
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
    );
  }
}
