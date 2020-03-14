import 'package:flutter/material.dart';

class SettingsProvider with ChangeNotifier {
  double _scrollPosition;

  double get scrollPosition => _scrollPosition;

  set scrollPosition(double val) {
    _scrollPosition = val;
    notifyListeners();
  }
}
