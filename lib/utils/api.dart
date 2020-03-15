import 'dart:convert';

import 'package:dio/dio.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';

Dio dio = Dio(BaseOptions(
  baseUrl: "${APP_HOST}api",
  connectTimeout: 5000,
  receiveTimeout: 3000,
));
// Response<Map> response;
Response<String> response;
Map responseBody;
dynamic err;

Future<Map> api(String what, {String type = 'get', Map<String, dynamic> data = const {}}) async {
  String url = "/data/$what";
  try {
    switch (what) {
      case 'user':
        switch (type) {
          case 'get':  response = await dio.get(url, queryParameters: data); break;
          case 'post': response = await dio.post(url, data: data); break;
        }
        break;
      case 'page':
        url = "$url/$type";
        response = await dio.get(url);
        // final jsonResponse = json.decode(response.data);
        // PageApi page = PageApi.fromJson(jsonResponse);
        // print(page.judul);
        break;
    }
    // responseBody = response?.data;
    responseBody = json.decode(response?.data);
  } catch (e) {
    responseBody = null;
    err = e;
  }
  print(" ==> API $what URL: $url $data");
  print(" ==> API $what RESPONSE: $response");
  print(" ==> API $what STATUS CODE: ${response?.statusCode}");
  print(" ==> API $what ERROR: $err");
  if (responseBody == null) h.failAlertInternet();
  return responseBody;
}

Future<Map> auth(String what, Map<String, dynamic> data) async {
  final url = "/auth/$what";
  try {
    response = await dio.post(url, data: data);
    responseBody = json.decode(response?.data);
  } catch (e) {
    responseBody = null;
    err = e;
  }
  print(" ==> AUTH $what RESPONSE: $response");
  print(" ==> AUTH $what STATUS CODE: ${response?.statusCode}");
  print(" ==> AUTH $what ERROR: $err");
  if (responseBody == null) h.failAlertInternet();
  return responseBody;
}
