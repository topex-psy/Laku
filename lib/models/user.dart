class UserModel {
  UserModel({
    this.uid,
    this.namaDepan,
    this.namaBelakang,
    this.email,
    this.foto,
    this.jumlahLapak,
    this.isBanned,
    this.banUntil,
    this.banReason,
  });

  final String uid;
  final String namaDepan;
  final String namaBelakang;
  final String email;
  final String foto;
  final int jumlahLapak;
  final bool isBanned;
  final DateTime banUntil;
  final String banReason;

  UserModel.fromJson(Map<String, dynamic> parsedJson)
  : uid = parsedJson['FIREBASE_UID'],
    namaDepan = parsedJson['NAMA_DEPAN'],
    namaBelakang = parsedJson['NAMA_BELAKANG'],
    email = parsedJson['EMAIL'],
    foto = parsedJson['FOTO'],
    jumlahLapak = int.parse(parsedJson['JUMLAH_LAPAK']),
    isBanned = parsedJson['IS_BANNED'] != null,
    banUntil = parsedJson['IS_BANNED'] == null ? null : DateTime.parse(parsedJson['BAN_UNTIL']),
    banReason = parsedJson['BAN_REASON'];

  @override
  String toString() => "UserModel("
  "\n  uid: $uid"
  "\n  namaDepan: $namaDepan"
  "\n  namaBelakang: $namaBelakang"
  "\n  email: $email"
  "\n  foto: $foto"
  "\n  isBanned: $isBanned"
  "\n  banUntil: $banUntil"
  "\n  banReason: $banReason"
  "\n);";
}

class UserSessionModel {
  String uid;
  String phone;

  clear() {
    uid = null;
    phone = null;
  }
}

class UserNotifModel {
  UserNotifModel({
    this.iklanUploadPic,
    this.iklanTerpasang,
    this.pencarianTerpasang,
    this.pesanMasuk,
    this.notifikasi,
    this.iklan,
    this.pengguna,
    this.pencari,
  });

  final List<int> iklanUploadPic;
  final int iklanTerpasang;
  final int pencarianTerpasang;
  final int pesanMasuk;
  final int notifikasi;
  final int iklan;
  final int pengguna;
  final int pencari;

  UserNotifModel.fromJson(Map<String, dynamic> parsedJson)
  : iklanUploadPic = List.from(parsedJson['IKLAN_UPLOAD_PIC']).map((l) => int.parse(l['HASHCODE'])).toList(),
    iklanTerpasang = int.parse(parsedJson['IKLAN_TERPASANG']),
    pencarianTerpasang = int.parse(parsedJson['PENCARIAN_TERPASANG']),
    pesanMasuk = int.parse(parsedJson['PESAN_MASUK']),
    notifikasi = int.parse(parsedJson['NOTIFIKASI']),
    iklan = int.parse(parsedJson['IKLAN']),
    pengguna = int.parse(parsedJson['PENGGUNA']),
    pencari = int.parse(parsedJson['PENCARI']);
}

class UserSetupModel {
  UserSetupModel({this.radius});

  final int radius;

  UserSetupModel.fromJson(Map<String, dynamic> parsedJson)
  : radius = int.parse(parsedJson['RADIUS']);
}

class UserTierModel {
  UserTierModel({this.tier, this.maxShop, this.maxListingPic});

  final int tier;
  final int maxShop;
  final int maxListingPic;

  UserTierModel.fromJson(Map<String, dynamic> parsedJson)
  : tier = int.parse(parsedJson['TIER']),
    maxShop = int.parse(parsedJson['MAX_SHOP']),
    maxListingPic = int.parse(parsedJson['MAX_LISTING_PIC']);
}