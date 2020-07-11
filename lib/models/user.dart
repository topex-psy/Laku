const jenisKelaminLbl = <String>['Laki-laki', 'Perempuan'];
const jenisKelaminVal = <String>['L', 'P'];

class UserModel {
  UserModel({
    this.uid,
    this.namaDepan,
    this.namaBelakang,
    this.jenisKelamin,
    this.tanggalLahir,
    this.phone,
    this.email,
    this.foto,
    this.tier,
    this.jumlahLapak,
    this.isBanned,
    this.banUntil,
    this.banReason,
  });

  final String uid;
  final String namaDepan;
  final String namaBelakang;
  final String jenisKelamin;
  final DateTime tanggalLahir;
  final String phone;
  final String email;
  final String foto;
  final int tier;
  final int jumlahLapak;
  final bool isBanned;
  final DateTime banUntil;
  final String banReason;

  String get namaLengkap => "$namaDepan $namaBelakang";
  String get jenisKelaminLengkap => jenisKelamin == 'L' ? 'Laki-laki' : 'Perempuan';

  UserModel.fromJson(Map<String, dynamic> parsedJson)
  : uid = parsedJson['FIREBASE_UID'],
    namaDepan = parsedJson['NAMA_DEPAN'],
    namaBelakang = parsedJson['NAMA_BELAKANG'],
    jenisKelamin = parsedJson['JENIS_KELAMIN'],
    tanggalLahir = DateTime.parse(parsedJson['TANGGAL_LAHIR']),
    phone = parsedJson['NO_HP'],
    email = parsedJson['EMAIL'],
    foto = parsedJson['FOTO'],
    tier = int.parse(parsedJson['TIER'] ?? '0'),
    jumlahLapak = int.parse(parsedJson['JUMLAH_LAPAK']),
    isBanned = parsedJson['IS_BANNED'] != null,
    banUntil = parsedJson['IS_BANNED'] == null ? null : DateTime.parse(parsedJson['BAN_UNTIL']),
    banReason = parsedJson['BAN_REASON'];

  @override
  String toString() => "UserModel("
  "\n  uid: $uid"
  "\n  namaDepan: $namaDepan"
  "\n  namaBelakang: $namaBelakang"
  "\n  jenisKelamin: $jenisKelamin"
  "\n  tanggalLahir: $tanggalLahir"
  "\n  phone: $phone"
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
  UserTierModel tier;

  clear() {
    uid = null;
    phone = null;
    tier = null;
  }
}

class UserNotifModel {
  UserNotifModel({
    this.iklanUploadPic,
    this.iklanTerpasang,
    this.iklanFavorit,
    this.broadcastAktif,
    this.pesanMasuk,
    this.notifikasi,
    this.tiketToa,
    this.iklan,
    this.pengguna,
    this.pencari,
  });

  final List<int> iklanUploadPic;
  final int iklanTerpasang;
  final int iklanFavorit;
  final int broadcastAktif;
  final int pesanMasuk;
  final int notifikasi;
  final int tiketToa;
  final int iklan;
  final int pengguna;
  final int pencari;

  UserNotifModel.fromJson(Map<String, dynamic> parsedJson)
  : iklanUploadPic = List.from(parsedJson['IKLAN_UPLOAD_PIC']).map((l) => int.parse(l['HASHCODE'])).toList(),
    iklanTerpasang = int.parse(parsedJson['IKLAN_TERPASANG']),
    iklanFavorit = int.parse(parsedJson['IKLAN_FAVORIT']),
    broadcastAktif = int.parse(parsedJson['BROADCAST_AKTIF']),
    pesanMasuk = int.parse(parsedJson['PESAN_MASUK']),
    notifikasi = int.parse(parsedJson['NOTIFIKASI']),
    tiketToa = int.parse(parsedJson['TIKET_TOA']),
    iklan = int.parse(parsedJson['IKLAN']),
    pengguna = int.parse(parsedJson['PENGGUNA']),
    pencari = int.parse(parsedJson['PENCARI']);
}

class UserTierModel {
  UserTierModel({
    this.tier,
    this.judul,
    this.maxShop,
    this.maxListingPic,
    this.maxListingDesc,
    this.radius,
    this.hargaUpgrade,
    this.hargaBeli
  });

  final int tier;
  final String judul;
  final int maxShop;
  final int maxListingPic;
  final int maxListingDesc;
  final int radius;
  final double hargaUpgrade;
  final double hargaBeli;

  UserTierModel.fromJson(Map<String, dynamic> parsedJson)
  : tier = int.parse(parsedJson['TIER']),
    judul = parsedJson['JUDUL'],
    maxShop = int.parse(parsedJson['MAX_SHOP']),
    maxListingPic = int.parse(parsedJson['MAX_LISTING_PIC']),
    maxListingDesc = int.parse(parsedJson['MAX_LISTING_DESC']),
    radius = int.parse(parsedJson['RADIUS']),
    hargaUpgrade = double.parse(parsedJson['HARGA_UPGRADE'] ?? '0.0'),
    hargaBeli = double.parse(parsedJson['HARGA_BELI'] ?? '0.0');

  @override
  String toString() => "$tier/$maxShop/$maxListingPic/$radius";
}