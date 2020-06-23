import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:multi_image_picker/multi_image_picker.dart';
import 'api.dart';
import 'constants.dart';
import 'helpers.dart';

Future<http.StreamedResponse> uploadImages(String dir, List<Asset> images, int hash) async {
  var data = <String, String>{
    'hash' : hash.toString(),
    'uid'  : userSession.uid,
    'dir'  : dir,
  };
  var request = http.MultipartRequest("POST", Uri.parse("${APP_HOST}api/data/images")) ..fields.addAll(data);
  for (var asset in images) {
    print("PREPARE IMAGE FOR UPLOAD: ${asset.name}");
    var byteData = await asset.getByteData(quality: 80);
    var multipartFile = http.MultipartFile.fromBytes(
      'images[]',
      byteData.buffer.asUint8List(),
      filename: asset.name,
      contentType: MediaType("image", "jpg"),
    );

    // add file to multipart
    request.files.add(multipartFile);
  }
  Future<http.StreamedResponse> send;
  try {
    send = request.send();
  } on SocketException catch(e) {
    print("upload images STATUS ERR = $e");
  }
  return send;
}

Future<ApiModel> uploadImage(
  String dir,
  String uid,
  String imageName,
  File image,
  int hash,
) async {
  Map data = <String, String>{
    'dir'       : dir,
    'uid'       : uid,
    'imageName' : imageName ?? '',
    'image'     : image != null ? 'data:image/png;base64,' + base64Encode(image.readAsBytesSync()) : '',
    'hash'      : hash.toString(),
  };
  try {
    final http.Response response = await http.post(
      Uri.encodeFull("${APP_HOST}api/data/image"),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: data,
      encoding: Encoding.getByName("utf-8")
    );
    final int statusCode = response.statusCode;
    if (statusCode < 200 || statusCode > 400 || json == null) {
      throw Exception("post image STATUS CODE = $statusCode");
    }
    final responseJson = json.decode(response.body);
    print("post image RESPONSE JSON = $responseJson");
    return ApiModel.fromJson(responseJson, type: 'post');
  } catch(e) {
    print("post image STATUS ERR = $e");
    return null;
  }
}