import 'dart:async';
import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

typedef IntCallback = Future<int> Function();
typedef UpgradeCallback = FutureOr<void> Function(Database db);

class DBProvider {
  DBProvider._();
  static final DBProvider db = DBProvider._();
  static final int version = 2;
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
      var dbBatch = db.batch();
      dbBatch.execute("CREATE TABLE Todo ("
          "id TEXT PRIMARY KEY,"
          "title TEXT,"
          "description TEXT,"
          "done BIT,"
          "dueDate INTEGER,"
          "doneDate INTEGER,"
          "topicId TEXT"
          "); ");
      dbBatch.execute("CREATE TABLE Topic ("
          "id TEXT PRIMARY KEY,"
          "name TEXT"
          "color TEXT"
          "pinned BIT); ");
      await dbBatch.commit(noResult: true);
    }, onUpgrade: (Database db, currentVersion, newVersion) async {
      final upgradeCalls = {
        2 : (Database db) async {
          await db.execute("CREATE TABLE Topic ("
          "id TEXT PRIMARY KEY,"
          "name TEXT,"
          "color TEXT,"
          "pinned BIT);");
          await db.execute("ALTER TABLE todo ADD COLUMN topicId TEXT");
        },
        
      };
      upgradeCalls.forEach((vesion,call) async {
        if(version > currentVersion)
          await call(db);
      });
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
