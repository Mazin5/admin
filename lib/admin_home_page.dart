import 'package:admin/ManageReservationsWithPayments.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';
import 'admin_login_page.dart';
import 'manage_vendor_service.dart';
import 'provider/notification_provider.dart';

class AdminHomePage extends StatefulWidget {
  static const routeName = '/home-screen';

  @override
  _AdminHomePageState createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  int _selectedIndex = 0;

  // Define a list of widget options for navigation
  static List<Widget> _widgetOptions = <Widget>[
    ManageVendorService(),
    ManageReservationsWithPayments(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
    final notificationProvider =
        Provider.of<NotificationProvider>(context, listen: false);
    notificationProvider.initializeFCM();
  }

  @override
  Widget build(BuildContext context) {
    // Define your color scheme
    final Color primaryColor = Color(0xFF0A73B7); // Blue
    final Color backgroundColor = Colors.white;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Admin Dashboard',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: primaryColor,
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await FirebaseMessaging.instance.unsubscribeFromTopic('admin');
              await FirebaseAuth.instance.signOut();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => AdminLoginPage()),
              );
            },
          ),
        ],
      ),
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.store_mall_directory),
            label: 'Vendors',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book_online),
            label: 'Reservations',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        backgroundColor: backgroundColor,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }
}
