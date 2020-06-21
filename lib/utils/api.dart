import 'dart:convert';

import 'package:dio/dio.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';

class ApiModel {
  ApiModel({
    this.meta = const {},
    this.result = const [],
    this.message = '',
    this.output = '',
    this.isSuccess = true
  });
  final Map<String, dynamic> meta;
  final List<Map<String, dynamic>> result;
  final String message;
  final String output;
  final bool isSuccess;
}

Dio dio = Dio(BaseOptions(
  baseUrl: "${APP_HOST}api",
  connectTimeout: 5000,
  receiveTimeout: 3000,
));

// Response<Map> response;
Response<String> response;
Map responseBody;
dynamic err;

Future<ApiModel> api(String what, {String type = 'get', Map<String, dynamic> data = const {}}) async {
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
  return responseBody == null ? ApiModel(isSuccess: false) : ApiModel(
    meta: responseBody[type],
    // result: List.from(responseBody['result']),
    result: List.from(responseBody['result']).map((res) => Map<String, dynamic>.from(res)).toList(),
  );
}

Future<ApiModel> auth(String what, Map<String, dynamic> data) async {
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
  return responseBody == null ? ApiModel(isSuccess: false) : ApiModel(
    isSuccess: responseBody['status'] == 1,
    // result: List.from(responseBody['result']),
    result: List.from(responseBody['result']).map((res) => Map<String, dynamic>.from(res)).toList(),
    message: responseBody['message'],
    output: responseBody['output'],
  );
}

log(String type, String what, String url, Map<String, dynamic> data) {
  print(
    "\n ==> $type $what URL: ${dio.options.baseUrl}$url"
    "\n ==> $type $what PARAMS: $data"
    "\n ==> $type $what RESPONSE: $response"
    "\n ==> $type $what STATUS CODE: ${response?.statusCode}"
    "\n ==> $type $what ERROR: $err"
  );
}