
import 'package:flutter/material.dart';

//TODO Impelement editor, name pin color
class EditorWideget extends StatefulWidget {
  EditorWideget(this.title);

  final String title;
  @override
  State<StatefulWidget> createState() {
    return _EditorList();
  }
}

class _EditorList extends State<EditorWideget> {
  
  Widget buildList(){
    
  }
  
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      appBar: AppBar(title: Text("Topic editor"),),
    );
  }
}

