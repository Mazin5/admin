import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:provider/provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'admin_login_page.dart';
import 'provider/vendor_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => VendorProvider()),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    _initializeFCM();
  }

  void _initializeFCM() async {
    FirebaseMessaging _messaging = FirebaseMessaging.instance;

    // Request permissions for iOS
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
      _getToken();
    } else {
      print('User declined or has not accepted permission');
    }

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Received a message in the foreground!');
      print('Message data: ${message.data}');
      if (message.notification != null) {
        print('Message also contained a notification: ${message.notification}');
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Message clicked!');
    });
  }

  void _getToken() async {
    FirebaseMessaging _messaging = FirebaseMessaging.instance;
    String? token = await _messaging.getToken();
    print('FCM Token: $token');

    // Save the token to Firestore
    if (token != null) {
      CollectionReference tokens = FirebaseFirestore.instance.collection('adminTokens');
      await tokens.add({'token': token});
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EventPerfect Admin',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: AdminLoginPage(),
    );
  }
}
