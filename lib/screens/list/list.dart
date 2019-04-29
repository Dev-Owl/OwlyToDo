import 'dart:core';

import 'package:flutter/material.dart';
import 'package:owly_todo/main.dart';
import 'package:owly_todo/screens/editor/editor.dart';
import 'package:owly_todo/screens/list/widgets/todoListView.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

//TODO show setting icon to change setting
//TODO add setting screen to change:
// - Hide done by default
//TODO run background service to show notification

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  TodoList todoListWidgetHelper;
  bool loading = false;

  void _openAddNote() {
    todoListWidgetHelper.openEditor(TodoItem());
  }

  @override
  void initState() {
    super.initState();
    loading = true;

    var initializationSettingsAndroid =
        AndroidInitializationSettings('app_icon');
    var initializationSettingsIOS = IOSInitializationSettings(
        onDidReceiveLocalNotification: onDidRecieveLocalNotification);

    var initializationSettings = InitializationSettings(
        initializationSettingsAndroid, initializationSettingsIOS);

    flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onSelectNotification: onSelectNotification);
    _prepareApp();
  }

  Future _prepareApp() async {
    //Create, update prepare datbase for app
    await DBProvider.db.initDB();

    setState(() {
      loading = false;
    });
  }

  Future<void> onDidRecieveLocalNotification(
      int id, String title, String body, String payload) async {
    await _checkNotificationCallback(payload);
  }

  Future<void> onSelectNotification(String payload) async {
    await _checkNotificationCallback(payload);
  }

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
                          title: "To-do details",
                          item: TodoItem.fromMap(dbResult.first),
                          editMode: false)),
                );
              }
            }
            break;
        }
      }
    }
  }

  Widget _getBody() {
    if (loading) {
      return Center(
        child: CircularProgressIndicator(),
      );
    } else {
      return todoListWidgetHelper.buildList();
    }
  }

  void _stateChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    todoListWidgetHelper = new TodoList(context, _stateChanged);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: _getBody(),
      floatingActionButton: loading
          ? null
          : FloatingActionButton(
              onPressed: _openAddNote,
              tooltip: 'Add note',
              child: Icon(Icons.add),
            ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
