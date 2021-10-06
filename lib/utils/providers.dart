import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
// import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';

const DEFAULT_ZOOM = 16.34;

class SettingsProvider with ChangeNotifier {
  late bool _isGettingAddress;
  late bool _isUploadListing;
  late bool _isViewFavorites;
  double? _lastLatitude;
  double? _lastLongitude;
  Placemark? _address;
  NotifModel? _notif;

  SettingsProvider() {
    _isGettingAddress = true;
    _isUploadListing = false;
    _isViewFavorites = false;
    // loadPreferences();
  }

  Placemark? get address => _address;
  bool get isGettingAddress => _isGettingAddress;
  bool get isUploadListing => _isUploadListing;
  bool get isViewFavorites => _isViewFavorites;
  NotifModel? get notif => _notif;
  double? get lastLatitude => _lastLatitude;
  double? get lastLongitude => _lastLongitude;

  setSettings({
    bool? isGettingAddress,
    bool? isUploadListing,
    bool? isViewFavorites,
    int? radius,
    double? lastLatitude,
    double? lastLongitude,
    Placemark? address,
    NotifModel? notif,
  }) {
    if (isGettingAddress != null) _isGettingAddress = isGettingAddress;
    if (isUploadListing != null) _isUploadListing = isUploadListing;
    if (isViewFavorites != null) _isViewFavorites = isViewFavorites;
    if (lastLatitude != null) _lastLatitude = lastLatitude;
    if (lastLongitude != null) _lastLongitude = lastLongitude;
    if (address != null) _address = address;
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
