import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class PushNotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  Future<void> initialize() async {
    try {
      // Request permissions for iOS
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('User granted permission for notifications.');
      } else {
        print('User declined or has not accepted permission for notifications.');
      }

      // Handling foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('Received a foreground message');
        print('Message data: ${message.data}');
        if (message.notification != null) {
          print('Message notification: ${message.notification}');
        }
      });

      // Handling background and terminated message taps
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        if (kDebugMode) {
          print('User tapped on a notification');
        }
        print('Message data on tap: ${message.data}');
      });
    } catch (e) {
      print('Error initializing FCM: $e');
    }
  }

  Future<void> getToken() async {
    try {
      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        print('FCM Token: $token');
        // Store or send the token to your server here
      } else {
        print('Failed to retrieve FCM token.');
      }
    } catch (e) {
      print('Error retrieving FCM token: $e');
    }
  }
}
