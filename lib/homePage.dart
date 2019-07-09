import 'dart:core';

import 'package:flutter/material.dart';
import 'package:owly_todo/helper/dbProvider.dart';
import 'package:owly_todo/main.dart';
import 'package:owly_todo/models/todoitem.dart';
import 'package:owly_todo/screens/editor/editor.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:owly_todo/screens/topic/topicList.dart';

class MyHomePage extends StatefulWidget {
  MyHomePage(this.notificationLaunch, this.notificationPayload,
      {Key key, this.title})
      : super(key: key);
  final String title;
  final bool notificationLaunch;
  final String notificationPayload;

  @override
  _MyHomePageState createState() => _MyHomePageState(notificationLaunch);
}

class _MyHomePageState extends State<MyHomePage> {
  _MyHomePageState(this.notificationLaunch);

  bool _loading = true;
  bool notificationLaunch;
  TodoItem itemToLaunchFromNotification;

  @override
  void initState() {
    super.initState();
    //Init the notificaiton plugin
    var initializationSettingsAndroid = AndroidInitializationSettings(
        'app_icon'); //TODO Replace the current icon and launcher
    var initializationSettingsIOS = IOSInitializationSettings(
        onDidReceiveLocalNotification: onDidRecieveLocalNotification);

    var initializationSettings = InitializationSettings(
        initializationSettingsAndroid, initializationSettingsIOS);

    flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onSelectNotification: onSelectNotification);
    _prepareApp();
  }

  Future _prepareApp() async {
    await DBProvider.db.initDB();
    if (notificationLaunch) {
      itemToLaunchFromNotification = await getItemFromNotificationPayLoad();
      if (itemToLaunchFromNotification == null) notificationLaunch = false;
    }
    setState(() {
      _loading = false;
    });
  }

  Future<void> onDidRecieveLocalNotification(
      int id, String title, String body, String payload) async {
    await _checkNotificationCallback(payload);
  }

  Future<void> onSelectNotification(String payload) async {
    await _checkNotificationCallback(payload);
  }

  Future<TodoItem> getItemFromNotificationPayLoad({String payload}) async {
    payload = payload ?? widget.notificationPayload;
    assert(payload != null);
    var result = payload.split(";");
    var db = await DBProvider.db.database;
    var dbResult =
        await db.query("todo", where: "id = ?", whereArgs: [result[1]]);
    if (dbResult != null && dbResult.length > 0)
      return TodoItem.fromMap(dbResult.first);
    else
      return null;
  }

  //TODO Switch using JSON in here in case it gets more complex
  Future<void> _checkNotificationCallback(String payload) async {
    if (payload != null) {
      var result = payload.split(";");
      if (result != null && result.length >= 2) {
        switch (result[0]) {
          case 'openTodo':
            {
              var item = await getItemFromNotificationPayLoad(payload: payload);
              if (item != null) {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => TodoEditorPage(
                          "To-do details", item,
                          initialEditMode: false)),
                );
              } else {
                debugPrint("Unable to find notification element");
              }
            }
            break;
        }
      }
    }
  }

  Widget _getBody() {
    if (_loading)
      return Scaffold(
          appBar: AppBar(
            title: Text(widget.title),
          ),
          body: Center(child: CircularProgressIndicator()));
    else{
      if(notificationLaunch){
        notificationLaunch = false;
        return TodoEditorPage("To-do details",itemToLaunchFromNotification,initialEditMode: false,);
      }
      else{
        return TopicListWidget("Topics");
      }
    }
      
  }

  @override
  Widget build(BuildContext context) {
    return _getBody();
  }
}
