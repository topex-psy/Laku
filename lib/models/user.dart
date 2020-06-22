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

class UserTierModel {
  UserTierModel({this.maxShop, this.maxListingPic});

  final int maxShop;
  final int maxListingPic;

  UserTierModel.fromJson(Map<String, dynamic> parsedJson)
  : maxShop = int.parse(parsedJson['MAX_SHOP']),
    maxListingPic = int.parse(parsedJson['MAX_LISTING_PIC']);
}