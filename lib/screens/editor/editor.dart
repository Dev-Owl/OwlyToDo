import 'package:flutter/material.dart';
import 'package:owly_todo/helper/dbProvider.dart';
import 'package:owly_todo/helper/todoitem.dart';
import 'package:owly_todo/main.dart';
import 'package:validate/validate.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

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
    assert(item !=null);
    return _EditorState(initialEditMode ?? false);
  }
}

class _EditorState extends State<TodoEditorPage> {
  final GlobalKey<FormState> _formKey = new GlobalKey<FormState>();
  final TextEditingController _dueDateController = new TextEditingController();
  final TextEditingController _titleController = new TextEditingController();
  final TextEditingController _descrptionController =
      new TextEditingController();

  bool _editMode = false;
  bool _changed = false;
  bool _dateChanged = false;

  _EditorState(this._editMode);

  DateTime convertToDate(String input) {
    try {
      var d = new DateFormat.yMd().add_Hm().parseStrict(input);
      return d;
    } catch (e) {
      return null;
    }
  }

  Future _chooseDate(BuildContext context, String initialDateString) async {
    var now = new DateTime.now();
    var initialDate = convertToDate(initialDateString) ?? now;
    initialDate = (initialDate.year >= 1970 ? initialDate : now);
    //TODO Allow to pick time here too
    var result = await showDatePicker(
        context: context,
        initialDate: initialDate,
        firstDate: new DateTime(1970),
        lastDate: new DateTime(2040));
    setState(() {
      widget.item.dueDate = result;
      if (result != null)
        _dueDateController.text = new DateFormat.yMd().add_Hm().format(result);
      else
        _dueDateController.text = null;
      _dateChanged = true;
    });
  }

  bool isValidDate(String date) {
    if (date.isEmpty) return true;
    var d = convertToDate(date);
    return d != null;
  }

  Future _performeEditorAction() async {
    if (_editMode) {
      if (_formKey.currentState.validate()) {
        _formKey.currentState.save();
        var db = await DBProvider.db.database;
        await DBProvider.db.upsert(() {
          return db.update("todo", widget.item.toMap(skipId: true),
              where: "id = ?", whereArgs: [widget.item.id]);
        }, () {
          return db.insert("todo", widget.item.toMap());
        });
        if (widget.item.dueDate != null)
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

    var androidPlatformChannelSpecifics = new AndroidNotificationDetails(
        'todo_item_pending', 'Owly Todo', 'Pending todo items');
    var iOSPlatformChannelSpecifics = new IOSNotificationDetails();
    NotificationDetails platformChannelSpecifics = new NotificationDetails(
        androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.schedule(
        item.id.hashCode,
        item.title,
        'You have a todo item pending',
        item.dueDate,
        platformChannelSpecifics,
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
          new Row(
            children: <Widget>[
              new Expanded(
                  child: TextFormField(
                decoration: InputDecoration(
                  labelText: "Due date",
                ),
                onSaved: (String value) {
                  widget.item.dueDate = convertToDate(value);
                },
                keyboardType: TextInputType.datetime,
                controller: _dueDateController,
                validator: (val) => isValidDate(val) ? null : "Invalid date",
              )),
              new IconButton(
                  icon: Icon(Icons.calendar_today),
                  tooltip: 'Choose date',
                  onPressed: (() {
                    _chooseDate(context, _dueDateController.text);
                  }))
            ],
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

  Future<bool> _onWillPop() {
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
        : Navigator.of(context).pop(true);
  }

  void _checkForAnyChange() {
    var changeFound = false;
    if (_titleController.text != widget.item.title) changeFound = true;
    if (_descrptionController.text != widget.item.description)
      changeFound = true;
    if (widget.item.dueDate != null) {
      if (_dueDateController.text !=
          new DateFormat.yMd().add_Hm().format(widget.item.dueDate))
        changeFound = true;
    }

    _changed = changeFound;
  }

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.item.title;
    _descrptionController.text = widget.item.description;
    if (widget.item.dueDate != null)
      _dueDateController.text =
          new DateFormat.yMd().add_Hm().format(widget.item.dueDate);

    _dueDateController.addListener(_checkForAnyChange);
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
