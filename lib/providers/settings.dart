import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider with ChangeNotifier {
  String _units;

  SettingsProvider() {
    _units = 'Imperial';
    loadPreferences();
  }

  String get units => _units;
  set units(String units) {
    _units = units;
    notifyListeners();
    savePreferences();
  }

  savePreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('units', _units);
  }

  loadPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    units = prefs.getString('units');
  }
}
