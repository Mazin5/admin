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
    _tabController = TabController(length: 3, vsync: this); // Updated length to 3 for the new tab
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

  Future<void> _showConfirmationDialog(
      BuildContext context, String action, String vendorId, String serviceType, Function onConfirm) async {
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
                setState(() {
                  _loadingVendors[vendorId] = true;
                });

                await onConfirm();

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
            Tab(text: 'Pending Upd'), // New tab for pending updates
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
                _buildVendorList(
                    vendorProvider.vendors
                        .where((v) => v['vendorData']['status'] == 'pending_update')
                        .toList(),
                    vendorProvider,
                    isVerifiedTab: false), // Handle pending updates here
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
        padding: EdgeInsets.all(8.0), // Adjust padding for better fit
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
            margin: EdgeInsets.symmetric(vertical: 6.0), // Adjust vertical margin for better fit
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12.0), // Add padding inside card
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      firstPictureUrl != null
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
                      SizedBox(width: 10),
                      Expanded( // Added Expanded to fit long texts better
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              serviceData['name'] ?? 'No Name',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16, // Adjusted font size
                              ),
                            ),
                            SizedBox(height: 2), // Slight space between title and subtitle
                            Text(
                              vendorData['email'] ?? 'No Email',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                              overflow: TextOverflow.ellipsis, // Avoid overflow
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  // Phone and Location Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Icon(Icons.phone, color: Colors.blue, size: 18), // Reduced icon size
                            SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                serviceData['phone'] ?? 'No Phone',
                                style: TextStyle(fontSize: 14),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Row(
                          children: [
                            Icon(Icons.location_on, color: Colors.red, size: 18), // Reduced icon size
                            SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                serviceData['location'] ?? 'No Location',
                                style: TextStyle(fontSize: 14),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
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
                      maxLines: 2, // Limit description to 2 lines
                      overflow: TextOverflow.ellipsis,
                    ),
                  SizedBox(height: 8),
                  // Price and Image Section
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
                                  width: 70, // Reduced image size
                                  height: 70,
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
                      if (isVerifiedTab)
                        ElevatedButton.icon(
                          onPressed: () async {
                            _showConfirmationDialog(
                              context,
                              'suspend',
                              vendorId,
                              vendorData['serviceType'],
                              () async {
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
                        )
                      else
                        ElevatedButton.icon(
                          onPressed: () async {
                            _showConfirmationDialog(
                              context,
                              'verify',
                              vendorId,
                              vendorData['serviceType'],
                              () async {
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
