import 'package:owly_todo/helper/dbProvider.dart';
import 'package:uuid/uuid.dart';

class TopicItem {
  String id;
  String name;
  String color;
  bool pinned = false;
  int totalChilds = 0;
  TopicItem();

  Future delete() async {
    var db = await DBProvider.db.database;
    //Delete topic and related todos
    await db.delete("Topic", where: "id = ?", whereArgs: [id]);
    await db.delete("todo", where: "topicId = ?", whereArgs: [id]);
  }

  Map<String, dynamic> toMap({bool skipId = false}) {
    var map = new Map<String,dynamic>();
    if(id?.isEmpty ?? true)
      id = new Uuid().v4();
    if (!skipId) map["id"] = id;
    map["name"] = name;
    map["color"] = color;
    map["pinned"] = pinned ? 1 : 0;
    return map;
  }

  TopicItem.fromMap(Map<String, dynamic> map) {
      id = map["id"];
      name = map["name"];
      color = map["color"];
      pinned = map["pinned"] == 1;
      totalChilds = map["totalChilds"];
  }
}
