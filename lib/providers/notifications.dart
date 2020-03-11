import 'package:flutter/material.dart';

class NotificationsProvider with ChangeNotifier {
  int _iklanTerpasang;
  int _pencarianTerpasang;
  int _pesanMasuk;
  int _iklan;
  int _pengguna;
  int _pencari;

  int get iklanTerpasang => _iklanTerpasang;
  int get pencarianTerpasang => _pencarianTerpasang;
  int get pesanMasuk => _pesanMasuk;
  int get iklan => _iklan;
  int get pengguna => _pengguna;
  int get pencari => _pencari;

  setNotif({
    int iklanTerpasang,
    int pencarianTerpasang,
    int pesanMasuk,
    int iklan,
    int pengguna,
    int pencari,
  }) {
    if (iklanTerpasang != null) _iklanTerpasang = iklanTerpasang;
    if (pencarianTerpasang != null) _pencarianTerpasang = pencarianTerpasang;
    if (pesanMasuk != null) _pesanMasuk = pesanMasuk;
    if (iklan != null) _iklan = iklan;
    if (pengguna != null) _pengguna = pengguna;
    if (pencari != null) _pencari = pencari;
    notifyListeners();
  }
}
