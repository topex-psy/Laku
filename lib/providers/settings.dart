import 'package:flutter/material.dart';
import 'package:geocoder/geocoder.dart';
// import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

const DEFAULT_ZOOM = 16.34;

class SettingsProvider with ChangeNotifier {
  Address _address;
  bool _isGettingLocation;
  bool _isUploadListing;
  bool _isViewFavorites;
  UserNotifModel _notif;

  SettingsProvider() {
    _isGettingLocation = false;
    _isUploadListing = false;
    _isViewFavorites = false;
    // loadPreferences();
  }

  Address get address => _address;
  bool get isGettingLocation => _isGettingLocation;
  bool get isUploadListing => _isUploadListing;
  bool get isViewFavorites => _isViewFavorites;
  UserNotifModel get notif => _notif;

  setSettings({
    Address address,
    bool isGettingLocation,
    bool isUploadListing,
    bool isViewFavorites,
    int radius,
    UserNotifModel notif,
  }) {
    if (address != null) _address = address;
    if (isGettingLocation != null) _isGettingLocation = isGettingLocation;
    if (isUploadListing != null) _isUploadListing = isUploadListing;
    if (isViewFavorites != null) _isViewFavorites = isViewFavorites;
    if (notif != null) _notif = notif;
    notifyListeners();
    // savePreferences();
  }

  // savePreferences() async {
  //   SharedPreferences prefs = await SharedPreferences.getInstance();
  //   prefs.setInt('settings_radius', radius);
  // }

  // loadPreferences() async {
  //   SharedPreferences prefs = await SharedPreferences.getInstance();
  //   setSettings(
  //     radius: prefs.getInt('settings_radius'),
  //   );
  // }
}
