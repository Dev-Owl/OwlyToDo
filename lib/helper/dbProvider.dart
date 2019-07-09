import 'dart:async';
import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

typedef IntCallback = Future<int> Function();
typedef UpgradeCallback = FutureOr<void> Function(Database db, Batch dbBatch);

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

  String _createTopicTableScript() {
    return "CREATE TABLE Topic ("
        "id TEXT PRIMARY KEY,"
        "name TEXT,"
        "color TEXT,"
        "pinned BIT); ";
  }

  String _createTodoTopicTable() {
    return "CREATE TABLE TodoTopic ("
        "Id TEXT PRIMARY KEY,"
        "TodoId TEXT,"
        "TopicId TEXT)";
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
          "doneDate INTEGER"
          "); ");
      dbBatch.execute(_createTopicTableScript());
      dbBatch.execute(_createTodoTopicTable());
      await dbBatch.commit(noResult: true);
    }, onUpgrade: (Database db, currentVersion, newVersion) async {
      final upgradeCalls = {
        2: (Database db, Batch dbBatch) async {
          dbBatch.execute(_createTopicTableScript());
          dbBatch.execute(_createTodoTopicTable());
        },
      };
      var dbBatch = db.batch();
      upgradeCalls.forEach((vesion, call) async {
        if (version > currentVersion) await call(db, dbBatch);
      });
      await dbBatch.commit(noResult: true);
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
