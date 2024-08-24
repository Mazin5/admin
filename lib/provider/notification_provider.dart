import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

class NotificationProvider with ChangeNotifier {
  void initializeFCM() async {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    await Firebase.initializeApp();
    FirebaseMessaging.onMessage.listen((message) {
      print('notificationnn');
      print('notificationnn ${message.notification!.title}');
      onMessageOpenedApp(message);
    });
    print('notificationnn');

    // // Request permissions for iOS
    NotificationSettings settings =
        await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
      _subscribeAdmin();
    } else {
      print('User declined or has not accepted permission');
    }

    // FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    //   print('Received a message in the foreground!');
    //   print('Message data: ${message.data}');
    //   if (message.notification != null) {
    //     print('Message also contained a notification: ${message.notification}');
    //   }
    // });

    // FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    //   print('Message clicked!');
    // });
  }

  @pragma('vm:entry-point')
  static Future<void> _firebaseMessagingBackgroundHandler(
      RemoteMessage message) async {
    await Firebase.initializeApp();
    await onMessage(message);
    // If you're going to use other Firebase services in the background, such as Firestore,
    // make sure you call `initializeApp` before using other Firebase services.
    // await onMessage(message);
    print("1 Handling a background message: ${message.messageId}");
  }

  static Future<void> onMessage(RemoteMessage message) async {
    RemoteNotification? notification = message.notification;
    AndroidNotification? androidNotification = message.notification?.android;
    AppleNotification? appleNotification = message.notification?.apple;
    print("2 Handling a background message: ${message.messageId}");

    if (notification == null) return;

    if (androidNotification != null || appleNotification != null) {
      // showNotification(
      //     title: notification.title as String,
      //     body: notification.body as String);
      // notificationPlugin.show(
      //   notification.hashCode,
      //   notification.title,
      //   notification.body,
      //   _notificationDetails(),
      // );
    }
  }

  static Future<void> showNotification({
    required String title,
    required String body,
    final String summary = 'Notification',
    final Map<String, String>? payload,
    final ActionType actionType = ActionType.Default,
    final NotificationLayout notificationLayout = NotificationLayout.Default,
    final NotificationCategory? notificationCategory,
    final String? bigPicutre,
    final List<NotificationActionButton>? actionButtons,
    final bool scheduled = false,
    final int? interval,
  }) async {
    assert(!scheduled || (scheduled && interval != null));
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: -1,
        channelKey: 'awesome_high_importance_channel',
        title: title,
        // icon: '@mipmap/ic_launcher',
        body: body,
        // roundedLargeIcon: tr,
        actionType: actionType,
        notificationLayout: notificationLayout,
        summary: summary,

        category: notificationCategory,
        // color: Colors.red,
        criticalAlert: true,
        displayOnForeground: true,
        payload: payload,
        displayOnBackground: true,
        bigPicture: bigPicutre,
      ),
      actionButtons: actionButtons,
      schedule: null,
    );
  }

  static void onMessageOpenedApp(RemoteMessage message) {
    RemoteNotification? notification = message.notification;
    AndroidNotification? androidNotification = message.notification?.android;
    AppleNotification? appleNotification = message.notification?.apple;
    // if (notification == null) return;
    // if (androidNotification != null || appleNotification != null) {
    showNotification(
      title: notification!.title as String,
      body: notification.body as String,
    );
    // _notificationPlugin.show(
    //   notification.hashCode,
    //   notification.title,
    //   notification.body,
    //   _notificationDetails(),
    // );
    // }
  }

  void _subscribeAdmin() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    await messaging.subscribeToTopic('admin');
    print('admin noty');
  }
}
