import 'package:shared_preferences/shared_preferences.dart';

class SettingProvider {
  static const String HideDoneItems = "HideDoneItems";
  static const String FirstStart = "FirstStart";

  Future<T> getSettingValue<T>(String key,{dynamic defaultValue}) async {
    assert(key != null);
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.get(key) ?? defaultValue;
  }

  Future<bool> setSettingStringValue(String key, String value) async {
    assert(key != null);
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString(key, value);
  }

  Future<bool> setSettingIntValue(String key, int value) async {
    assert(key != null);
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setInt(key, value);
  }

  Future<bool> setSettingBoolValue(String key, bool value) async {
    assert(key != null);
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(key, value);
  }
}
