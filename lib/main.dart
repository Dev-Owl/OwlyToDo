import 'dart:io';

import 'package:flutter/material.dart';
import 'package:owly_todo/screens/list/list.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

//TODO Scheduler for notification to remind

class DBProvider {
  DBProvider._();
  static final DBProvider db = DBProvider._();
  static final int version = 1;
  static Database _database;

  Future<Database> get database async {
    if (_database != null) return _database;

    // if _database is null we instantiate it
    _database = await initDB();
    return _database;
  }

  Future<bool> checkIfDbExists() async {
    String path = join(await getDatabasesPath(), "OwlyTodo.db");
    return new File(path).exists();
  }

  Future initDB() async {
    String path = join(await getDatabasesPath(), "OwlyTodo.db");
    return await openDatabase(path, version: version, onOpen: (db) {},
        onCreate: (Database db, int version) async {
      //TODO add other tables as batch below
      await db.execute("CREATE TABLE Todo ("
          "id TEXT PRIMARY KEY,"
          "title TEXT,"
          "description TEXT,"
          "done BIT,"
          "dueDate INTEGER,"
          "doneDate INTEGER"
          ")");
    } //TODO Add funcion to handle db upgrade
        );
  }
}

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Owly Todo',
      theme: ThemeData(
        primarySwatch: Colors.amber,
      ),
      home: MyHomePage(title: 'Owly To-do'),
    );
  }
}
