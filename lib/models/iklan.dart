import 'package:flutter/material.dart';

class IklanPicModel {
  IklanPicModel({
    this.id,
    this.foto,
    this.judul,
    this.waktu,
  });

  final int id;
  final String foto;
  final String judul;
  final DateTime waktu;

  IklanPicModel.fromJson(Map<String, dynamic> parsedJson)
  : id = int.parse(parsedJson['ID']),
    foto = parsedJson['FOTO'],
    judul = parsedJson['JUDUL'],
    waktu = DateTime.parse(parsedJson['TIMEE']);
}

class IklanModel {
  IklanModel({
    this.id,
    this.idUser,
    this.idShop,
    @required this.judul,
    @required this.deskripsi,
    this.keyword,
    this.tipe,
    this.waktu,
    this.waktuUpdate,
    @required this.lat,
    @required this.lng,
    @required this.judulLapak,
    @required this.pengiklan,
    this.foto,
  });

  final int id;
  final int idUser;
  final int idShop;
  final String judul;
  final String deskripsi;
  final String keyword;
  final String tipe;
  final DateTime waktu;
  final DateTime waktuUpdate;
  final double lat;
  final double lng;
  final String judulLapak;
  final String pengiklan;
  final List<IklanPicModel> foto;

  IklanModel.fromJson(Map<String, dynamic> parsedJson)
  : id = int.parse(parsedJson['ID']),
    idUser = int.parse(parsedJson['ID_USER']),
    idShop = int.parse(parsedJson['ID_USER_LOCATION']),
    judul = parsedJson['JUDUL'],
    deskripsi = parsedJson['DESKRIPSI'],
    keyword = parsedJson['KEYWORD'],
    tipe = parsedJson['TIPE'],
    waktu = DateTime.parse(parsedJson['TIMEE']),
    waktuUpdate = DateTime.parse(parsedJson['LAST_UPDATED']),
    lat = double.parse(parsedJson['LATITUDE']),
    lng = double.parse(parsedJson['LONGITUDE']),
    judulLapak = parsedJson['JUDUL_LAPAK'],
    pengiklan = parsedJson['PENGIKLAN'],
    foto = List.from(parsedJson['FOTO']).map((f) => IklanPicModel.fromJson(f)).toList();
}