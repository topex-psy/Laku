class ReportModel {
  ReportModel({
    this.iklanTerpasang,
    this.pesanMasuk,
    this.iklan,
    this.pengguna,
    this.pencari,
    this.uid,
    this.timee,
  });

  final int iklanTerpasang;
  final int pesanMasuk;
  final int iklan;
  final int pengguna;
  final int pencari;
  final String uid;
  final int timee;

  ReportModel.fromJson(Map<String, dynamic> parsedJson)
  : iklanTerpasang = parsedJson['iklanTerpasang'],
    pesanMasuk = parsedJson['pesanMasuk'],
    iklan = parsedJson['iklan'],
    pengguna = parsedJson['pengguna'],
    pencari = parsedJson['pencari'],
    uid = parsedJson['uid'],
    timee = parsedJson['timee'];
}