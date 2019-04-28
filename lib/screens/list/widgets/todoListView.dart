import 'dart:async';

import 'package:flutter/material.dart';
import 'package:owly_todo/main.dart';
import 'package:owly_todo/screens/editor/editor.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'package:flutter_slidable/flutter_slidable.dart';


class TodoItem {
  String id;
  String title;
  String description;
  bool done = false;
  DateTime dueDate;
  DateTime doneDate;

  TodoItem({this.title = "New todo item"});

  Future setDoneFlag(bool newState) async {
    done = newState;
    var db = await DBProvider.db.database;
    //Set or reset the related doneDate
    if (newState)
      doneDate = DateTime.now();
    else
      doneDate = null;

    await db.update("todo", toMap(skipId: true),
        where: "id = ?", whereArgs: [id]);
  }
  
  Future delete() async{
     var db = await DBProvider.db.database;
     await db.delete("todo",where: "id = ?", whereArgs: [id]);
  }

  Map<String, dynamic> toMap({bool skipId = false}) {
    var map = new Map<String, dynamic>();
    if (!skipId) map["id"] = id?.isEmpty ?? new Uuid().v4();

    map["title"] = title;
    map["description"] = description;
    map["done"] = this.done ? 1 : 0;
    if (dueDate != null) {
      map["dueDate"] = dueDate?.millisecondsSinceEpoch;
    }
    if (doneDate != null) {
      map["doneDate"] = doneDate?.millisecondsSinceEpoch;
    }
    return map;
  }

  TodoItem.fromMap(Map<String, dynamic> map) {
    id = map["id"];
    title = map["title"];
    description = map["description"];
    done = map["done"] == 1 ? true : false;
    if (map["dueDate"] != null)
      dueDate = new DateTime.fromMillisecondsSinceEpoch(map["dueDate"]);
    if (map["doneDate"] != null)
      doneDate = new DateTime.fromMillisecondsSinceEpoch(map["doneDate"]);
  }
}

class TodoList {
  TodoList(this._context,this._stateChanged);

  final BuildContext _context;
  final List<TodoItem> listData = new List();
  final VoidCallback _stateChanged;

  bool get isEmpty {
    return listData.isEmpty;
  }

  void openEditor(TodoItem itemToEdit, {bool editMode = true}) {
    Navigator.push(
        _context,
        MaterialPageRoute(
            builder: (context) => TodoEditorPage(
                title: "Add ToDo", item: itemToEdit, editMode: editMode)));
  }

  Future<List<TodoItem>> getData() async {
    var db = await DBProvider.db.database;
    var data =
        await db.rawQuery("SELECT * FROM Todo ORDER BY done ASC,dueDate DESC");
    return data?.map((map) {
          return TodoItem.fromMap(map);
        })?.toList() ??
        new List<TodoItem>();
  }

 

  Widget buildList() {
    final List<Widget> data = new List<Widget>();
    return FutureBuilder<List<TodoItem>>(
      future: getData(),
      builder: (BuildContext context, AsyncSnapshot<List<TodoItem>> snapshot) {
        switch (snapshot.connectionState) {
          case ConnectionState.active:
          case ConnectionState.waiting:
          case ConnectionState.none:
            return Center(child: CircularProgressIndicator());
          case ConnectionState.done:
            {
              if (snapshot.data == null || snapshot.data.isEmpty) {
                data.add(_buildEmptyRow());
              } else {
                data.addAll(snapshot.data.map((singleTodoItem) {
                  return _buildTodoRow(singleTodoItem);
                }));
              }
              return ListView(
                padding: EdgeInsets.all(16.0),
                children: data,
              );
            }
        }
      },
    );
  }

  Widget _buildEmptyRow() {
    return ListTile(
      title: Text("Create your first todo item, get things done :)"),
    );
  }

  Widget _getSubTitle(TodoItem item) {
    var dateFormater = DateFormat();
    if (item.done)
      return Text("Done at ${dateFormater.format(item.doneDate)}");
    else if (item.dueDate != null)
      return Text("Due at ${dateFormater.format(item.dueDate)}");
    else
      return Text("No due date");
  }

  Widget _buildTodoRow(TodoItem item) {
    return Slidable(
      delegate: SlidableDrawerDelegate(),
      actionExtentRatio: 0.25,
      child: ListTile(
        title: Text(item.title),
        subtitle: _getSubTitle(item),
        leading: Icon(
          item.done ? Icons.done : null,
          color: Colors.green,
          size: 32.0,
        ),
        trailing: Icon(Icons.keyboard_arrow_right),
        onTap: () {
          openEditor(item, editMode: false);
        },
      ),
      actions: <Widget>[
        new IconSlideAction(
          caption: item.done ? 'Undue' : 'Done',
          color: Colors.blue,
          icon: Icons.done,
          onTap: ()async {
            await item.setDoneFlag(!item.done);
            if(_stateChanged != null)
              _stateChanged();
          }
        ),
        new IconSlideAction(
          caption: 'Edit',
          color: Colors.indigo,
          icon: Icons.edit,
          onTap: () => openEditor(item, editMode: true),
        ),
      ],
      secondaryActions: <Widget>[
        new IconSlideAction(
          caption: 'Delete',
          color: Colors.red,
          icon: Icons.delete,
          onTap:  ()async {
            await item.delete();
            if(_stateChanged != null)
              _stateChanged();
          }
        ),
      ],
    );
  }
}
