import 'package:flutter/material.dart';

class IklanKelompokModel {
  IklanKelompokModel({
    @required this.id,
    @required this.judul,
    @required this.icon,
    @required this.isWTS,
    @required this.isWTB,
    @required this.isPriceable,
    @required this.isScheduleable,
  });

  final int id;
  final String judul;
  final String icon;
  final bool isWTS;
  final bool isWTB;
  final bool isPriceable;
  final bool isScheduleable;
}

class IklanKategoriModel {
  IklanKategoriModel({
    @required this.id,
    @required this.idKelompok,
    @required this.judul,
    this.icon,
    this.tier,
    this.isWTS,
    this.isWTB,
    this.isPriceable,
    this.isScheduleable,
    this.kelompok,
    this.iconKelompok,
  });

  final int id;
  final int idKelompok;
  final String judul;
  final String icon;
  final int tier;
  final bool isWTS;
  final bool isWTB;
  final bool isPriceable;
  final bool isScheduleable;
  final String kelompok;
  final String iconKelompok;

  IklanKategoriModel.fromJson(Map<String, dynamic> parsedJson)
  : id = int.parse(parsedJson['ID']),
    idKelompok = int.parse(parsedJson['ID_KELOMPOK']),
    judul = parsedJson['JUDUL'],
    icon = parsedJson['ICON'],
    tier = int.parse(parsedJson['TIER']),
    isWTS = int.parse(parsedJson['WTS']??'0') == 1,
    isWTB = int.parse(parsedJson['WTB']??'0') == 1,
    isPriceable = int.parse(parsedJson['IS_PRICEABLE']??'0') == 1,
    isScheduleable = int.parse(parsedJson['IS_SCHEDULEABLE']??'0') == 1,
    kelompok = parsedJson['KELOMPOK'],
    iconKelompok = parsedJson['ICON_KELOMPOK'];

  @override
  String toString() => judul;
}

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
    this.kondisi,
    this.stok,
    this.harga,
    this.isNego,
    this.layananAntar,
    this.jadwalMulai,
    this.jadwalAkhir,
    this.keyword,
    this.tipe,
    this.kategori,
    this.waktu,
    this.waktuUpdate,
    @required this.lat,
    @required this.lng,
    @required this.jarakMeter,
    @required this.judulLapak,
    @required this.alamatLapak,
    @required this.fotoLapak,
    @required this.pengiklan,
    this.jumlahIklan,
    this.jumlahFavoritLapak,
    this.jumlahFavorit,
    this.telepon,
    this.whatsapp,
    this.tokopedia,
    this.shopee,
    this.instagram,
    this.facebook,
    this.bukalapak,
    this.foto,
    this.tier,
    this.isFavorit,
    this.isMine,
    this.isDalamRadius,
  });

  final int id;
  final int idUser;
  final int idShop;
  final String judul;
  final String deskripsi;
  final String kondisi;
  final String stok;
  final double harga;
  final bool isNego;
  final String layananAntar;
  final DateTime jadwalMulai;
  final DateTime jadwalAkhir;
  final String keyword;
  final String tipe;
  final String kategori;
  final DateTime waktu;
  final DateTime waktuUpdate;
  final double lat;
  final double lng;
  final double jarakMeter;
  final String judulLapak;
  final String alamatLapak;
  final String fotoLapak;
  final String pengiklan;
  final int jumlahIklan;
  final int jumlahFavoritLapak;
  int jumlahFavorit;
  final String telepon;
  final String whatsapp;
  final String tokopedia;
  final String shopee;
  final String instagram;
  final String facebook;
  final String bukalapak;
  final List<IklanPicModel> foto;
  final int tier;
  bool isFavorit;
  bool isMine;
  bool isDalamRadius;

  toggleFav() {
    isFavorit = !isFavorit;
    if (isFavorit) {
      jumlahFavorit++;
    } else if (jumlahFavorit > 0) {
      jumlahFavorit--;
    }
  }
  bool isInRadius(double meter) {
    return jarakMeter <= meter;
  }

  IklanModel.fromJson(Map<String, dynamic> parsedJson)
  : id = int.parse(parsedJson['ID']),
    idUser = int.parse(parsedJson['ID_USER']),
    idShop = int.parse(parsedJson['ID_USER_LOCATION']),
    judul = parsedJson['JUDUL'],
    deskripsi = parsedJson['DESKRIPSI'],
    kondisi = parsedJson['KONDISI'],
    stok = parsedJson['STOK'],
    keyword = parsedJson['KEYWORD'],
    harga = double.parse(parsedJson['HARGA'] ?? '0.0'),
    isNego = int.parse(parsedJson['IS_NEGO'] ?? '0') == 1,
    layananAntar = parsedJson['LAYANAN_ANTAR'],
    jadwalMulai = parsedJson['JADWAL_MULAI'] == null ? null : DateTime.parse(parsedJson['JADWAL_MULAI']),
    jadwalAkhir = parsedJson['JADWAL_AKHIR'] == null ? null : DateTime.parse(parsedJson['JADWAL_AKHIR']),
    tipe = parsedJson['TIPE'],
    kategori = parsedJson['JUDUL_KATEGORI'],
    waktu = DateTime.parse(parsedJson['TIMEE']),
    waktuUpdate = DateTime.parse(parsedJson['LAST_UPDATED']),
    lat = double.parse(parsedJson['LATITUDE']),
    lng = double.parse(parsedJson['LONGITUDE']),
    jarakMeter = double.parse(parsedJson['JARAK_METER']),
    judulLapak = parsedJson['JUDUL_LAPAK'],
    alamatLapak = parsedJson['ALAMAT_LAPAK'],
    fotoLapak = parsedJson['FOTO_LAPAK'],
    pengiklan = parsedJson['PENGIKLAN'],
    jumlahIklan = int.parse(parsedJson['JUMLAH_IKLAN']),
    jumlahFavoritLapak = int.parse(parsedJson['JUMLAH_FAVORIT_LAPAK']),
    jumlahFavorit = int.parse(parsedJson['JUMLAH_FAVORIT']),
    telepon = parsedJson['TELEPON'],
    whatsapp = parsedJson['WHATSAPP'],
    tokopedia = parsedJson['TOKOPEDIA'],
    shopee = parsedJson['SHOPEE'],
    instagram = parsedJson['INSTAGRAM'],
    facebook = parsedJson['FACEBOOK'],
    bukalapak = parsedJson['BUKALAPAK'],
    foto = List.from(parsedJson['FOTO']).map((f) => IklanPicModel.fromJson(f)).toList(),
    tier = int.parse(parsedJson['TIER']),
    isFavorit = int.parse(parsedJson['IS_FAVORIT']) == 1,
    isMine = int.parse(parsedJson['IS_MINE']) == 1,
    isDalamRadius = int.parse(parsedJson['IS_DALAM_RADIUS']) == 1;
}