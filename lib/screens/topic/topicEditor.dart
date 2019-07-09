import 'package:flutter/material.dart';
import 'package:owly_todo/models/topic.dart';
import 'package:validate/validate.dart';

class TopicEditorWideget extends StatefulWidget {
  TopicEditorWideget(this.title, this.itemToWork);

  final String title;
  final TopicItem itemToWork;
  @override
  State<StatefulWidget> createState() {
    return _EditorList();
  }
}

class _EditorList extends State<TopicEditorWideget> {
  
  final GlobalKey<FormState> _formKey = new GlobalKey<FormState>();
  final TextEditingController _nameController = new TextEditingController();

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: _buildForm(),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.save),
        onPressed: () {},
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: new ListView(
        padding: EdgeInsets.all(16),
        children: <Widget>[
          TextFormField(
            decoration: InputDecoration(
                hintText: "Name your topic", labelText: "Name"),
            onSaved: (String value) {
              widget.itemToWork.name = value;
            },
            autofocus: true,
            controller: _nameController,
            validator: (String value) {
              try {
                Validate.notBlank(value);
              } catch (ex) {
                return "Name is required";
              }
            },
          ),
        ],
      ),
    );
  }
}
