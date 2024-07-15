import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'admin_login_page.dart';
import 'manage_vendor_service.dart';
import 'manage_user_reservations.dart';
import 'view_payments_screen.dart';
import 'archived_reservations_screen.dart';

class AdminHomePage extends StatefulWidget {
  @override
  _AdminHomePageState createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
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
        child: _selectedIndex == 0
            ? ManageVendorService()
            : _selectedIndex == 1
                ? ManageUserReservations()
                : _selectedIndex == 2
                    ? ViewPaymentsScreen()
                    : ArchivedReservationsScreen(),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
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
          BottomNavigationBarItem(
            icon: Icon(Icons.archive),
            label: 'Archived Reservations',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        onTap: _onItemTapped,
      ),
    );
  }
}
