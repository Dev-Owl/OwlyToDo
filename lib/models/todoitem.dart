import 'package:owly_todo/helper/dbProvider.dart';
import 'package:owly_todo/main.dart';
import 'package:uuid/uuid.dart';

class TodoItem {
  String id;
  String title;
  String description;
  bool done = false;
  DateTime dueDate;
  DateTime doneDate;
  String topicId;

  TodoItem();

  Future setDoneFlag(bool newState) async {
    done = newState;
    var db = await DBProvider.db.database;
    //Set or reset the related doneDate
    if (newState)
      doneDate = DateTime.now();
    else
      doneDate = null;

    await db
        .update("todo", toMap(skipId: true), where: "id = ?", whereArgs: [id]);
  }

  Future delete() async {
    var db = await DBProvider.db.database;
    try{
      flutterLocalNotificationsPlugin.cancel(id.hashCode);
    }catch(ex){
      //we dont care
    }
    await db.delete("todo", where: "id = ?", whereArgs: [id]);
  }

  Map<String, dynamic> toMap({bool skipId = false}) {
    var map = new Map<String, dynamic>();
    if(id?.isEmpty ?? true)
      id = new Uuid().v4();
    if (!skipId) map["id"] = id;

    map["title"] = title;
    map["description"] = description;
    map["done"] = this.done ? 1 : 0;
    if (dueDate != null) {
      map["dueDate"] = dueDate?.millisecondsSinceEpoch;
    } else {
      map["dueDate"] = null;
    }
    if (doneDate != null) {
      map["doneDate"] = doneDate?.millisecondsSinceEpoch;
    } else {
      map["doneDate"] = null;
    }
    map["topicId"] = topicId;
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
    topicId = map["topicId"];
  }
}