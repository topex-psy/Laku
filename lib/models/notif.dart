import 'package:flutter/material.dart';

class NotifModel {
  NotifModel({
    @required this.judul,
    this.deskripsi,
    this.waktu,
  });

  final String judul;
  final String deskripsi;
  final DateTime waktu;

  NotifModel.fromJson(Map<String, dynamic> parsedJson)
  : judul = parsedJson['JUDUL'],
    deskripsi = parsedJson['DESKRIPSI'],
    waktu = DateTime.parse(parsedJson['TIMEE']);
}