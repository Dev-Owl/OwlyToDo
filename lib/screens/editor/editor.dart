import 'package:flutter/material.dart';
import 'package:owly_todo/helper/dbProvider.dart';
import 'package:owly_todo/helper/settingProvider.dart';
import 'package:owly_todo/main.dart';
import 'package:owly_todo/models/todoitem.dart';
import 'package:validate/validate.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:datetime_picker_formfield/datetime_picker_formfield.dart';

//TODO Check code here, clean up if required

enum ConfirmAction { CANCEL, ACCEPT }

class TodoEditorPage extends StatefulWidget {
  TodoEditorPage(this.title, this.item, {Key key, this.initialEditMode})
      : super(key: key);

  final bool initialEditMode;
  final String title;
  final TodoItem item;

  @override
  _EditorState createState() {
    assert(item != null);
    return _EditorState(initialEditMode ?? false);
  }
}

class _EditorState extends State<TodoEditorPage> {
  final GlobalKey<FormState> _formKey = new GlobalKey<FormState>();
  final TextEditingController _titleController = new TextEditingController();
  final TextEditingController _descrptionController =
      new TextEditingController();

  bool _editMode = false;
  bool _changed = false;
  bool _dateChanged = false;

  _EditorState(this._editMode);

  Future<bool> upsertDataIfValid() async {
    if (_formKey.currentState.validate()) {
      _formKey.currentState.save();
      var db = await DBProvider.db.database;
      await DBProvider.db.upsert(() {
        return db.update("todo", widget.item.toMap(skipId: true),
            where: "id = ?", whereArgs: [widget.item.id]);
      }, () {
        return db.insert("todo", widget.item.toMap());
      });
      return true;
    } else {
      return false;
    }
  }

  Future _performeEditorAction() async {
    if (_editMode) {
      if (await upsertDataIfValid()) {
        await _sheduleNotification(widget.item);
        Navigator.of(context).pop();
      }
    } else {
      if (widget.item.done) {
        var result = await _asyncConfirmDialog(context);
        if (result == ConfirmAction.ACCEPT) {
          await widget.item.setDoneFlag(false);
          setState(() {});
        }
      } else {
        await widget.item.setDoneFlag(true);
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _sheduleNotification(TodoItem item) async {
    try {
      flutterLocalNotificationsPlugin.cancel(item.id.hashCode);
    } catch (e) {}
    if (item.dueDate == null) return;
    var androidPlatformChannelSpecifics = new AndroidNotificationDetails(
        'todo_item_pending', 'Owly Todo', 'Pending todo items');
    var iOSPlatformChannelSpecifics = new IOSNotificationDetails();
    NotificationDetails platformChannelSpecifics = new NotificationDetails(
        androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.schedule(item.id.hashCode, item.title,
        'You have a todo item pending', item.dueDate, platformChannelSpecifics,
        payload: "openTodo;${item.id}");
  }

  Future<ConfirmAction> _asyncConfirmDialog(BuildContext context) async {
    return showDialog<ConfirmAction>(
      context: context,
      barrierDismissible: false, // user must tap button for close dialog!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Please confirm?'),
          content: const Text('This will move the task back to your todo list'),
          actions: <Widget>[
            FlatButton(
              child: const Text('Changed my mind'),
              onPressed: () {
                Navigator.of(context).pop(ConfirmAction.CANCEL);
              },
            ),
            FlatButton(
              child: const Text('Make it so'),
              onPressed: () {
                Navigator.of(context).pop(ConfirmAction.ACCEPT);
              },
            )
          ],
        );
      },
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
                hintText: "Enter your todo", labelText: "Title"),
            onSaved: (String value) {
              widget.item.title = value;
            },
            autofocus: true,
            controller: _titleController,
            validator: (String value) {
              try {
                Validate.notBlank(value);
              } catch (ex) {
                return "Title is required";
              }
            },
          ),
          TextFormField(
            decoration: InputDecoration(
                hintText: "Further description", labelText: "Leave a note"),
            keyboardType: TextInputType.multiline,
            maxLines: null,
            onSaved: (String value) {
              widget.item.description = value;
            },
            controller: _descrptionController,
          ),
          DateTimePickerFormField(
            inputType: InputType.both,
            format: DateFormat.yMd().add_jm(),
            editable: false,
            initialValue: widget.item.dueDate,
            decoration: InputDecoration(
                labelText: 'Due date', hasFloatingPlaceholder: false),
            onSaved: (value) {
              widget.item.dueDate = value;
            },
            onChanged: (result){
               _dateChanged = result != widget.item.dueDate;
            },
          )
        ],
      ),
    );
  }

  Widget _buildViewer() {
    var dateFormater = DateFormat();
    var dateString = widget.item.done
        ? "item done since ${dateFormater.format(widget.item.doneDate)}"
        : widget.item.dueDate == null
            ? "no due date"
            : dateFormater.format(widget.item.dueDate);

    return ListView(
      children: <Widget>[
        Text(
          widget.item.title,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
          textAlign: TextAlign.center,
        ),
        Divider(),
        Padding(
          padding: EdgeInsets.only(top: 10),
          child: Text(widget.item.description ?? "no description",
              style: TextStyle(fontSize: 18)),
        ),
        Padding(padding: EdgeInsets.only(top: 10), child: Text(dateString))
      ],
      padding: EdgeInsets.all(16),
    );
  }

  Future<bool> _onWillPop() async {
    if (_editMode && (_changed | _dateChanged)) {
      var saveOnLeave = await SettingProvider().getSettingValue<bool>(
          SettingProvider.SaveOnLeave,
          defaultValue: false);
      if (saveOnLeave) {
        if (await upsertDataIfValid()) {
          await _sheduleNotification(widget.item);
          return true;
        }
      }
    }

    return _editMode && (_changed | _dateChanged)
        ? showDialog<bool>(
              context: context,
              barrierDismissible: false,
              builder: (context) => new AlertDialog(
                    title: new Text('Are you sure?'),
                    content: new Text('Unsaved changes will be lost'),
                    actions: <Widget>[
                      new FlatButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: new Text('No'),
                      ),
                      new FlatButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: new Text('Yes'),
                      ),
                    ],
                  ),
            ) ??
            false
        : true;
  }

  void _checkForAnyChange() {
    var changeFound = false;
    if (_titleController.text != widget.item.title) changeFound = true;
    if (_descrptionController.text != widget.item.description)
      changeFound = true;

    _changed = changeFound;
  }

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.item.title;
    _descrptionController.text = widget.item.description;
    _titleController.addListener(_checkForAnyChange);
    _descrptionController.addListener(_checkForAnyChange);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          actions: _editMode || widget.item.done
              ? <Widget>[
                  IconButton(
                    icon: Icon(Icons.delete),
                    tooltip: "Delete",
                    onPressed: () async {
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) => new AlertDialog(
                              title: new Text('Are you sure?'),
                              content: new Text('Delete this record?'),
                              actions: <Widget>[
                                new FlatButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                  child: new Text('No'),
                                ),
                                new FlatButton(
                                  onPressed: () async {
                                    await widget.item.delete();
                                    Navigator.of(context).pop();
                                    Navigator.of(context).pop();
                                  },
                                  child: new Text('Yes'),
                                ),
                              ],
                            ),
                      );
                    },
                  )
                ]
              : <Widget>[
                  IconButton(
                    icon: Icon(Icons.edit),
                    tooltip: "Edit todo",
                    onPressed: () {
                      setState(() {
                        _editMode = true;
                      });
                    },
                  )
                ],
        ),
        body: _editMode ? _buildForm() : _buildViewer(),
        floatingActionButton: FloatingActionButton(
          onPressed: _performeEditorAction,
          tooltip: 'Add note',
          child: Icon(_editMode
              ? Icons.save
              : widget.item.done ? Icons.undo : Icons.done_all),
        ),
      ),
    );
  }
}
