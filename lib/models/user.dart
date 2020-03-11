class UserModel {
  UserModel({
    this.uid,
    this.lat,
    this.lng,
    this.timee,
  });

  final String uid;
  final double lat;
  final double lng;
  final int timee;

  UserModel.fromJson(Map<String, dynamic> parsedJson)
  : uid = parsedJson['uid'],
    lat = double.parse(parsedJson['lat']),
    lng = double.parse(parsedJson['lng']),
    timee = int.parse(parsedJson['timee']);
}