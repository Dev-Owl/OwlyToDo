import 'dart:async';
import 'package:flutter/material.dart';
import 'package:owly_todo/helper/dbProvider.dart';
import 'package:owly_todo/helper/settingProvider.dart';
import 'package:owly_todo/models/todoitem.dart';
import 'package:owly_todo/screens/editor/editor.dart';
import 'package:intl/intl.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:owly_todo/screens/widgets/gloablDrawer.dart';

//TODO Add a search view

class ListTodoWideget extends StatefulWidget {
  ListTodoWideget(this.title);

  final String title;
  @override
  State<StatefulWidget> createState() {
    return _TodoList();
  }
}

class _TodoList extends State<ListTodoWideget> {
  final List<TodoItem> listData = new List();
  final SettingProvider _setting = SettingProvider();
  bool get isEmpty {
    return listData.isEmpty;
  }

  void addNewItem() {
    openEditor(TodoItem());
  }

  void openEditor(TodoItem itemToEdit, {bool editMode = true}) {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => TodoEditorPage("Add ToDo", itemToEdit,
                initialEditMode: editMode)));
  }

  Future<List<TodoItem>> getData() async {
    var db = await DBProvider.db.database;
    bool hideDoneElements =
        await _setting.getSettingValue(SettingProvider.HideDoneItems, defaultValue: true);
    String wherePart;
    String orderByPart;
    if (hideDoneElements) {
      orderByPart = "dueDate ASC";
      wherePart = "done = 0";
    } else {
      orderByPart = "done ASC,dueDate ASC";
    }
    var data = await db.query("Todo", where: wherePart, orderBy: orderByPart);
    return data?.map((map) {
          return TodoItem.fromMap(map);
        })?.toList() ??
        new List<TodoItem>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: _buildList(),
      drawer: GlobalDrawerWidget(widget.title, addNewItem),
      floatingActionButton: FloatingActionButton(
        onPressed: () => addNewItem(),
        tooltip: 'Add note',
        child: Icon(Icons.add),
      ),
    );
  }

  Widget _buildList() {
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
            onTap: () async {
              await item.setDoneFlag(!item.done);
              setState(() {});
            }),
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
            onTap: () async {
              await item.delete();
              setState(() {});
            }),
      ],
    );
  }
}
