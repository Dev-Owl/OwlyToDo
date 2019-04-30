import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

typedef IntCallback = Future<int> Function();

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
     //TODO Add funcion to handle db upgrade below
    return await openDatabase(path, version: version, onOpen: (db) {},
        onCreate: (Database db, int version) async {
      //TODO add other tables using batch below
      await db.execute("CREATE TABLE Todo ("
          "id TEXT PRIMARY KEY,"
          "title TEXT,"
          "description TEXT,"
          "done BIT,"
          "dueDate INTEGER,"
          "doneDate INTEGER"
          ")");
    });
  }

  Future<int> upsert(IntCallback updateFunction, IntCallback insert) async {
    final updateResult = await updateFunction();
    if (updateResult == 0) {
      return await insert();
    } else {
      return updateResult;
    }
  }
}
