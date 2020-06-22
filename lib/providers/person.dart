import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PersonProvider with ChangeNotifier {
  String _namaDepan;
  String _namaBelakang;
  String _email;
  String _foto;
  bool _isSignedIn;

  PersonProvider() {
    _isSignedIn = false;
    // loadPreferences();
  }

  String get namaDepan => _namaDepan;
  String get namaBelakang => _namaBelakang;
  String get email => _email;
  String get foto => _foto;
  bool get isSignedIn => _isSignedIn;

  setPerson({
    String namaDepan,
    String namaBelakang,
    String email,
    String foto,
    bool isSignedIn,
  }) {
    if (namaDepan != null) _namaDepan = namaDepan;
    if (namaBelakang != null) _namaBelakang = namaBelakang;
    if (email != null) _email = email;
    if (foto != null) _foto = foto;
    if (isSignedIn != null) _isSignedIn = isSignedIn;
    notifyListeners();
    // savePreferences();
  }

  savePreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('person_namaDepan', namaDepan);
    prefs.setString('person_namaBelakang', namaBelakang);
    prefs.setString('person_email', email);
    prefs.setString('person_foto', foto);
  }

  loadPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setPerson(
      namaDepan: prefs.getString('person_namaDepan'),
      namaBelakang: prefs.getString('person_namaBelakang'),
      email: prefs.getString('person_email'),
      foto: prefs.getString('person_foto'),
    );
  }
}
