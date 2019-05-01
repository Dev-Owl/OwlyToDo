import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:owly_todo/screens/settings/settings.dart';

class GlobalDrawerWidget extends StatefulWidget {
  GlobalDrawerWidget(this.title, this.addNew);

  final String title;
  final VoidCallback addNew;

  @override
  State<StatefulWidget> createState() {
    return _GlobalDrawer();
  }
}

class _GlobalDrawer extends State<GlobalDrawerWidget> {
  
  void _openSettings() {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => SettingScreenWidget("Settings")));
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
        child: ListView(
      padding: EdgeInsets.zero,
      children: <Widget>[
        DrawerHeader(
          child: ListTile(
              title: Text(
            'Owly To do',
            style: TextStyle(fontSize: 25),
          )),
          decoration: BoxDecoration(
              color: Colors.amberAccent,
              image: DecorationImage(
                  image: ExactAssetImage('assets/app_icon.png'),
                  alignment: Alignment.bottomRight)),
        ),
        ListTile(
          leading: Icon(Icons.add),
          title: Text("Add new"),
          onTap: () {
            Navigator.pop(context);
            widget.addNew();
          },
        ),
        ListTile(
          leading: Icon(Icons.settings),
          title: Text('Settings'),
          onTap: () {
            Navigator.pop(context);
             _openSettings();
          },
        ),
      ],
    ));
  }
}
