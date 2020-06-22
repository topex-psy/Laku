import 'package:flutter/material.dart';

class TokoModel {
  TokoModel({
    this.id,
    @required this.judul,
    this.deskripsi,
    @required this.alamat,
    @required this.lat,
    @required this.lng,
  });

  final int id;
  final String judul;
  final String deskripsi;
  final String alamat;
  final double lat;
  final double lng;

  TokoModel.fromJson(Map<String, dynamic> parsedJson)
  : id = int.parse(parsedJson['ID']),
    judul = parsedJson['JUDUL'],
    deskripsi = parsedJson['DESKRIPSI'],
    alamat = parsedJson['ALAMAT'],
    lat = double.parse(parsedJson['LATITUDE']),
    lng = double.parse(parsedJson['LONGITUDE']);
}