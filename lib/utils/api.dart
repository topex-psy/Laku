import 'package:dio/dio.dart';
import '../utils/constants.dart';

Dio dio = Dio();
Response response;
dynamic err;

Future<Response> user(String what, Map<String, dynamic> data) async {
  var url = "${APP_HOST}user";
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
