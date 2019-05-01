import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class GlobalDrawerWidget extends StatefulWidget {

  GlobalDrawerWidget(this.title);

  final String title;

  @override
  State<StatefulWidget> createState() {
    return _GlobalDrawer();
  }
}

class _GlobalDrawer extends State<GlobalDrawerWidget> {
  
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
          },
        ),
        ListTile(
          leading: Icon(Icons.settings),
          title: Text('Settings'),
          onTap: () {
            // Update the state of the app
            // ...
            // Then close the drawer
            Navigator.pop(context);
          },
        ),
      ],
    ));
  }
}
