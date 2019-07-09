import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:owly_todo/helper/dbProvider.dart';
import 'package:owly_todo/models/topic.dart';
import 'package:owly_todo/screens/topic/topicEditor.dart';
import 'package:owly_todo/screens/widgets/gloablDrawer.dart';

class TopicListWidget extends StatefulWidget {
  TopicListWidget(this.title);

  final String title;
  @override
  State<StatefulWidget> createState() {
    return _TopicList();
  }
}

class _TopicList extends State<TopicListWidget> {
  void addNewItem() {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => TopicEditorWideget("New topic", TopicItem())));
  }

  Future<List<TopicItem>> getData() async {
    var db = await DBProvider.db.database;
    var data = await db.rawQuery("SELECT topic.*,(SELECT COUNT(1) FROM TodoTopic WHERE TopicId = topic.id) as totalChilds FROM topic ORDER BY pinned ASC, name ASC");
    return data?.map((map) {
          return TopicItem.fromMap(map);
        })?.toList() ??
        new List<TopicItem>();
  }

  Widget _buildList() {
    final List<Widget> data = new List<Widget>();
    return FutureBuilder<List<TopicItem>>(
      future: getData(),
      builder: (BuildContext context, AsyncSnapshot<List<TopicItem>> snapshot) {
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
                data.addAll(snapshot.data.map((singleTopicItem) {
                  return _buildTopicRow(singleTopicItem);
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
      title: Text("Get started with a topic, get things done"),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Topics"),
      ),
      body: _buildList(),
      drawer: GlobalDrawerWidget(widget.title, addNewItem),
      floatingActionButton: FloatingActionButton(
        onPressed: () => addNewItem(),
        tooltip: 'Add topic',
        child: Icon(Icons.add),
      ),
    );
  }

  Widget _buildTopicRow(TopicItem singleTopicItem) {
    return Slidable(
      delegate: SlidableDrawerDelegate(),
      actionExtentRatio: 0.25,
      child: Container(
          decoration: new BoxDecoration(color: Colors.red),
          child: ListTile(
            title: Text(singleTopicItem.name),
            subtitle: Text("${singleTopicItem.totalChilds} open items"),
            trailing: Icon(Icons.keyboard_arrow_right),
            onTap: () {},
          )),
      actions: <Widget>[
        new IconSlideAction(
          caption: 'Edit',
          color: Colors.indigo,
          icon: Icons.edit,
          onTap: () => {},
        ),
      ],
      secondaryActions: <Widget>[
        new IconSlideAction(
            caption: 'Delete',
            color: Colors.red,
            icon: Icons.delete,
            onTap: () async {
              await singleTopicItem.delete();
              setState(() {});
            }),
      ],
    );
  }
}
