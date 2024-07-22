import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'admin_login_page.dart';
import 'manage_vendor_service.dart';
import 'manage_user_reservations.dart';
import 'view_payments_screen.dart';

class AdminHomePage extends StatefulWidget {
  @override
  _AdminHomePageState createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  int _selectedIndex = 0;

  // Define a list of widget options for navigation
  static List<Widget> _widgetOptions = <Widget>[
    ManageVendorService(),
    ManageUserReservations(),
    ViewPaymentsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Home'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => AdminLoginPage()),
              );
            },
          )
        ],
      ),
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.store),
            label: 'Manage Vendors',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book),
            label: 'Manage Reservations',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.payment),
            label: 'View Payments',
          ),
        ],
        currentIndex: _selectedIndex,
        unselectedItemColor: Colors.blue,
        selectedItemColor: Colors.black,
        onTap: _onItemTapped,
      ),
    );
  }
}
