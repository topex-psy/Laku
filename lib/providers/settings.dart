import 'package:flutter/material.dart';
import 'package:geocoder/geocoder.dart';
import 'package:shared_preferences/shared_preferences.dart';

const DEFAULT_RADIUS = 10000;
const DEFAULT_ZOOM = 16.34;

class SettingsProvider with ChangeNotifier {
  Address _address;
  bool _isGettingLocation;
  bool _isShowGraphics;
  int _radius;

  SettingsProvider() {
    _isGettingLocation = false;
    _isShowGraphics = false;
    _radius = DEFAULT_RADIUS;
    // loadPreferences();
  }

  Address get address => _address;
  bool get isGettingLocation => _isGettingLocation;
  bool get isShowGraphics => _isShowGraphics;
  int get radius => _radius;

  setSettings({
    Address address,
    bool isGettingLocation,
    bool isShowGraphics,
    int radius,
  }) {
    if (address != null) _address = address;
    if (isGettingLocation != null) _isGettingLocation = isGettingLocation;
    if (isShowGraphics != null) _isShowGraphics = isShowGraphics;
    if (radius != null) _radius = radius;
    notifyListeners();
    // savePreferences();
  }

  savePreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setInt('settings_radius', radius);
  }

  loadPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setSettings(
      radius: prefs.getInt('settings_radius'),
    );
  }
}
