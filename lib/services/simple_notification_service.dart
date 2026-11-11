import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final FlutterLocalNotificationsPlugin notifications =
    FlutterLocalNotificationsPlugin();

class NotificationService {
  static Future<void> initialize() async {
    if (!Platform.isAndroid) {
      return;
    }

    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );

    await notifications.initialize(settings: settings);

    await notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  static Future<void> showTestNotification() async {
    if (!Platform.isAndroid) {
      return;
    }

    await notifications.show(
      id: 0,
      title: 'テスト通知',
      body: '通知が表示されました',
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'test_channel',
          'テスト通知',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
    );
  }
}
