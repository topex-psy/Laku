class UserModel {
  UserModel({
    this.uid,
    this.namaDepan,
    this.namaBelakang,
    this.foto,
    this.jumlahLapak,
    this.isBanned,
    this.banUntil,
    this.banReason,
  });

  final String uid;
  final String namaDepan;
  final String namaBelakang;
  final String foto;
  final int jumlahLapak;
  final bool isBanned;
  final DateTime banUntil;
  final String banReason;

  UserModel.fromJson(Map<String, dynamic> parsedJson)
  : uid = parsedJson['FIREBASE_UID'],
    namaDepan = parsedJson['NAMA_DEPAN'],
    namaBelakang = parsedJson['NAMA_BELAKANG'],
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
  "\n  foto: $foto"
  "\n  isBanned: $isBanned"
  "\n  banUntil: $banUntil"
  "\n  banReason: $banReason"
  "\n);";
}

class CurrentUserModel {
  String uid;
  String phone;

  clear() {
    uid = null;
    phone = null;
  }
}