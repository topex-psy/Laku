import 'package:flutter/material.dart';

class TokoModel {
  TokoModel({
    this.id,
    @required this.judul,
    this.deskripsi,
    @required this.alamat,
    @required this.lat,
    @required this.lng,
    this.jumlahIklan,
    this.jumlahFavorit,
    this.isFavorit,
    this.isDalamRadius,
  });

  final int id;
  final String judul;
  final String deskripsi;
  final String alamat;
  final double lat;
  final double lng;
  final int jumlahIklan;
  final int jumlahFavorit;
  bool isFavorit;
  bool isDalamRadius;

  TokoModel.fromJson(Map<String, dynamic> parsedJson)
  : id = int.parse(parsedJson['ID']),
    judul = parsedJson['JUDUL'],
    deskripsi = parsedJson['DESKRIPSI'],
    alamat = parsedJson['ALAMAT'],
    lat = double.parse(parsedJson['LATITUDE']),
    lng = double.parse(parsedJson['LONGITUDE']),
    jumlahIklan = int.parse(parsedJson['JUMLAH_IKLAN']),
    jumlahFavorit = int.parse(parsedJson['JUMLAH_FAVORIT']),
    isFavorit = int.parse(parsedJson['IS_FAVORIT']) == 1,
    isDalamRadius = int.parse(parsedJson['IS_DALAM_RADIUS']) == 1;

  @override
  String toString() => judul;
}