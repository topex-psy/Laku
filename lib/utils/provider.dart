import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class PengirimanState with ChangeNotifier {
  PengirimanState();

  int _tahap = 0;
  int _kirim = 0;

  int get tahap => _tahap;
  int get kirim => _kirim;

  set tahap(int value) {
    _tahap = value;
    notifyListeners();
  }
  set kirim(int value) {
    _kirim = value;
    notifyListeners();
  }

  notify() {
    notifyListeners();
  }
}
