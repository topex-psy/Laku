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
  var url = "/data/$what";
  response = null;
  responseBody = null;
  err = null;
  try {
    switch (what) {
      case 'user':
        switch (type) {
          case 'get':  response = await dio.get(url, queryParameters: data); break;
          case 'post': response = await dio.post(url, data: data, options: Options(contentType: "application/x-www-form-urlencoded",)); break;
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
    err = e;
  }
  log("API", what, url, data);
  if (responseBody == null) h.failAlertInternet();
  return responseBody;
}

Future<Map> auth(String what, Map<String, dynamic> data) async {
  final url = "/auth/$what";
  response = null;
  responseBody = null;
  err = null;
  try {
    // response = await dio.post(url, data: data);
    response = await dio.post(url, data: data, options: Options(
      contentType: "application/x-www-form-urlencoded",
      // responseType: ResponseType.json,
      // headers: {
      //   HttpHeaders.contentTypeHeader: "application/json"
      // }
    ));
    responseBody = json.decode(response?.data);
  } catch (e) {
    err = e;
  }
  log("AUTH", what, url, data);
  if (responseBody == null) h.failAlertInternet();
  return responseBody;
}

log(String type, String what, String url, Map<String, dynamic> data) {
  print(" ==> $type $what URL: ${dio.options.baseUrl}$url");
  print(" ==> $type $what PARAMS: $data");
  if (err == null) {
    print(" ==> $type $what RESPONSE: $response");
    print(" ==> $type $what STATUS CODE: ${response?.statusCode}");
    return;
  }
  print(" ==> $type $what ERROR: $err");
}