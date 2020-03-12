import 'package:dio/dio.dart';
import '../utils/constants.dart';

Dio dio = Dio();
Response response;
dynamic err;

Future<Response> user(String what, Map<String, dynamic> data) async {
  final url = "${APP_HOST}api/data/user";
  try {
    switch(what) {
      case 'get':
        response = await dio.get(url, queryParameters: data);
        break;
      case 'post':
        response = await dio.post(url, data: data);
        break;
    }
  } catch (e) {
    err = e;
  }
  print(" ==> user $what RESPONSE: $response");
  print(" ==> user $what ERROR: $err");
  return response;
}

Future<Response> auth(String what, Map<String, dynamic> data) async {
  final url = "${APP_HOST}api/auth/$what";
  try {
    response = await dio.post(url, data: data);
  } catch (e) {
    err = e;
  }
  print(" ==> user $what RESPONSE: $response");
  print(" ==> user $what ERROR: $err");
  return response;
}
