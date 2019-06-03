import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:owly_todo/helper/settingProvider.dart';
import 'package:owly_todo/homePage.dart';
import 'package:owly_todo/screens/topic/topicList.dart';

//Global endpoint for notifications
FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

void main() async {
  flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  var firstStart = await SettingProvider()
      .getSettingValue(SettingProvider.FirstStart, defaultValue: true);
  var details =
      await flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();
  var notificationLaunch = false;
  String notificationPayload;
  if (details != null) {
    notificationLaunch = details.didNotificationLaunchApp;
    notificationPayload = details.payload;
  }
  runApp(MyApp(firstStart, notificationLaunch, notificationPayload));
}

class MyApp extends StatelessWidget {
  MyApp(this.firstStart, this.notificationLaunch, this.notificationPayload);

  final bool firstStart;
  final bool notificationLaunch;
  final String notificationPayload;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Owly To-do',
      theme: ThemeData(
        primarySwatch: Colors.amber,
      ),
      home: MyHomePage(notificationLaunch, notificationPayload,
      title: 'Owly To-do'), //TODO show a silder if its the first start
    );
  }
}
