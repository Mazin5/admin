import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'admin_login_page.dart'; // Import the admin login page

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EventPerfect Admin',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: AdminLoginPage(), // Set the admin login page as the home screen
    );
  }
}
