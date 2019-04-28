import 'dart:core';

import 'package:flutter/material.dart';
import 'package:owly_todo/main.dart';
import 'package:owly_todo/screens/list/widgets/todoListView.dart';


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
    _prepareApp();
  }

  Future _prepareApp() async {
    //Create, update prepare datbase for app
    await DBProvider.db.initDB(); 
    
    setState(() {
      loading = false;  
    });
  }

  Widget _getBody(){
    return loading ? Center(child: 
      CircularProgressIndicator(),)  : todoListWidgetHelper.buildList();
  }

  void _stateChanged(){
    setState(() {
      
    });
  }

  @override
  Widget build(BuildContext context) {
    todoListWidgetHelper = new TodoList(context,_stateChanged);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: _getBody(),
      floatingActionButton: loading ? null : FloatingActionButton(
        onPressed: _openAddNote,
        tooltip: 'Add note',
        child: Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
