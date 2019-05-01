import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:owly_todo/helper/settingProvider.dart';

//TODO add setting screen to change:
// - Save on leave

class SettingScreenWidget extends StatefulWidget {
  SettingScreenWidget(this.title);

  final String title;
  final SettingProvider settingProvider = SettingProvider();

  @override
  State<StatefulWidget> createState() {
    return _SettingState();
  }
}

class _SettingState extends State<SettingScreenWidget> {
  Future<_LoadedSettingState> loadSettings() async {
    var result = _LoadedSettingState();
    result.hideDoneElements = await widget.settingProvider
        .getSettingValue<bool>(SettingProvider.HideDoneItems,
            defaultValue: false);
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: FutureBuilder<_LoadedSettingState>(
          future: loadSettings(),
          builder: (BuildContext context,
              AsyncSnapshot<_LoadedSettingState> snapshot) {
            switch (snapshot.connectionState) {
              case ConnectionState.waiting:
                return new Text('Loading....');
              default:
                if (snapshot.hasError)
                  return new Text('Error: ${snapshot.error}');
                else
                  return ListView(
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(child: Text("Hide done elements")),
                          Switch(
                            value: snapshot.data.hideDoneElements,
                            onChanged: (bool newVlaue) async {
                              await widget.settingProvider.setSettingBoolValue(SettingProvider.HideDoneItems, newVlaue);
                            },
                          )
                        ],
                      ),
                      Divider()
                    ],
                    padding: EdgeInsets.all(16),
                  );
            }
          },
        ));
  }
}

class _LoadedSettingState {
  bool hideDoneElements = false;
}
