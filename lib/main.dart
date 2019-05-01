import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:owly_todo/helper/settingProvider.dart';
import 'package:owly_todo/screens/list/list.dart';

//Global endpoint for notifications
FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

void main() async{
  flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  var firstStart = await SettingProvider().getSettingValue(SettingProvider.FirstStart,defaultValue: true);
  runApp(MyApp(firstStart));
}

class MyApp extends StatelessWidget {
  
  MyApp(this.firstStart);

  final bool firstStart;
 
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Owly To-do',
      theme: ThemeData(
        primarySwatch: Colors.amber,
      ),
      home: MyHomePage(title: 'Owly To-do'), //TODO show a silder if its the first start
    );
  }
}
