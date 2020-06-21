import 'package:flutter/material.dart';

class IklanModel {
  IklanModel({
    this.id,
    @required this.judul,
    this.deskripsi,
    @required this.lat,
    @required this.lng,
    this.timee,
  });

  final int id;
  final String judul;
  final String deskripsi;
  final double lat;
  final double lng;
  final int timee;

  IklanModel.fromJson(Map<String, dynamic> parsedJson)
  : id = parsedJson['uid'],
    judul = parsedJson['judul'],
    deskripsi = parsedJson['deskripsi'],
    lat = double.parse(parsedJson['lat']),
    lng = double.parse(parsedJson['lng']),
    timee = int.parse(parsedJson['timee']);
}