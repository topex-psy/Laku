import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PersonProvider with ChangeNotifier {
  String _namaDepan;
  String _namaBelakang;
  DateTime _tanggalLahir;
  String _jenisKelamin;
  String _email;
  String _foto;

  PersonProvider() {
    // loadPreferences();
  }

  String get namaDepan => _namaDepan;
  String get namaBelakang => _namaBelakang;
  DateTime get tanggalLahir => _tanggalLahir;
  String get jenisKelamin => _jenisKelamin;
  String get email => _email;
  String get foto => _foto;

  setPerson({
    String namaDepan,
    String namaBelakang,
    DateTime tanggalLahir,
    String jenisKelamin,
    String email,
    String foto,
  }) {
    if (namaDepan != null) _namaDepan = namaDepan;
    if (namaBelakang != null) _namaBelakang = namaBelakang;
    if (tanggalLahir != null) _tanggalLahir = tanggalLahir;
    if (jenisKelamin != null) _jenisKelamin = jenisKelamin;
    if (email != null) _email = email;
    if (foto != null) _foto = foto;
    notifyListeners();
    // savePreferences();
  }

  savePreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('person_namaDepan', namaDepan);
    prefs.setString('person_namaBelakang', namaBelakang);
    prefs.setString('person_tanggalLahir', tanggalLahir.toString().substring(0, 10));
    prefs.setString('person_jenisKelamin', jenisKelamin);
    prefs.setString('person_email', email);
    prefs.setString('person_foto', foto);
  }

  loadPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var dob = prefs.getString('person_tanggalLahir');
    setPerson(
      namaDepan: prefs.getString('person_namaDepan'),
      namaBelakang: prefs.getString('person_namaBelakang'),
      tanggalLahir: dob == null ? null : DateTime.parse(dob),
      jenisKelamin: prefs.getString('person_jenisKelamin'),
      email: prefs.getString('person_email'),
      foto: prefs.getString('person_foto'),
    );
  }

  clearPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.remove('person_namaDepan');
    prefs.remove('person_namaBelakang');
    prefs.remove('person_tanggalLahir');
    prefs.remove('person_jenisKelamin');
    prefs.remove('person_email');
    prefs.remove('person_foto');
  }
}
