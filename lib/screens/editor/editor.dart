import 'package:flutter/material.dart';
import 'package:owly_todo/main.dart';
import 'package:owly_todo/screens/list/widgets/todoListView.dart';
import 'package:validate/validate.dart';
import 'dart:async';
import 'package:intl/intl.dart';


enum ConfirmAction { CANCEL, ACCEPT }

class TodoEditorPage extends StatefulWidget {
  TodoEditorPage({Key key, this.title, this.item, this.editMode})
      : super(key: key);

  final bool editMode;
  final String title;
  final TodoItem item;

  @override
  _EditorState createState() => _EditorState(editMode);
}

class _EditorState extends State<TodoEditorPage> {
  final GlobalKey<FormState> _formKey = new GlobalKey<FormState>();
  final TextEditingController _dueDateController = new TextEditingController();
  final TextEditingController _titleController = new TextEditingController();
  final TextEditingController _descrptionController =
      new TextEditingController();

  bool _editMode = false;
  bool _changed = false;

  _EditorState(this._editMode);

  DateTime convertToDate(String input) {
    try {
      var d = new DateFormat.yMd().parseStrict(input);
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

    if (result == null) return;
    if (widget.item.dueDate != result) _changed = true;

    widget.item.dueDate = result;
    setState(() {
      _dueDateController.text = new DateFormat.yMd().format(result);
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
        //TODO refactore the below lines into an upsert call
        if (await db.update("todo", widget.item.toMap(skipId: true),
                where: "id = ?", whereArgs: [widget.item.id]) ==
            0) await db.insert("todo", widget.item.toMap());
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
    if (widget.item.dueDate != null)
      _dueDateController.text =
          new DateFormat.yMd().format(widget.item.dueDate);
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
    return _editMode && _changed
        ? showDialog(
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

    if (_dueDateController.text !=
        new DateFormat.yMd().format(widget.item.dueDate)) changeFound = true;

    _changed = changeFound;
  }

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.item.title;
    _descrptionController.text = widget.item.description;

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
                                  onPressed: (){
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