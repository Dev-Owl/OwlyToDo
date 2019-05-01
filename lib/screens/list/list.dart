import 'dart:core';

import 'package:flutter/material.dart';
import 'package:owly_todo/helper/dbProvider.dart';
import 'package:owly_todo/main.dart';
import 'package:owly_todo/models/todoitem.dart';
import 'package:owly_todo/screens/editor/editor.dart';
import 'package:owly_todo/screens/list/widgets/todoListView.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    //Init the notificaiton plugin
    var initializationSettingsAndroid = AndroidInitializationSettings(
        'app_icon'); //TODO Replace the current icon
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

  //TODO Switch using JSON in here in case it gets more complex
  Future<void> _checkNotificationCallback(String payload) async {
    if (payload != null) {
      var result = payload.split(";");
      if (result != null && result.length >= 2) {
        switch (result[0]) {
          case 'openTodo':
            {
              var db = await DBProvider.db.database;
              var dbResult = await db
                  .query("todo", where: "id = ?", whereArgs: [result[1]]);
              if (dbResult != null && dbResult.length > 0) {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => TodoEditorPage(
                          "To-do details", TodoItem.fromMap(dbResult.first),
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
    else
      return ListTodoWideget(widget.title);
  }

  @override
  Widget build(BuildContext context) {
    return _getBody();
  }
}
