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
    this.isSuccess = true,
  });

  final Map<String, dynamic> meta;
  final List<Map<String, dynamic>> result;
  final String message;
  final String output;
  final bool isSuccess;

  ApiModel.fromJson(Map<String, dynamic> responseBody, {String type = 'get'})
  : isSuccess = (responseBody['status'] ?? 1) == 1,
    result = List.from(responseBody['result']).map((res) => Map<String, dynamic>.from(res)).toList(),
    message = responseBody['message'],
    output = responseBody['output'],
    meta = type == 'get' ? Map.from(responseBody[type]) : {};
}

Dio dio = Dio(BaseOptions(
  baseUrl: "${APP_HOST}api",
  connectTimeout: 30000,
  receiveTimeout: 3000,
));

// Response<Map> response;
Response<String> response;
Map responseBody;
dynamic err;

Future<ApiModel> api(String what, {String sub1, String type = 'get', Map<String, dynamic> data = const {}}) async {
  var url = "/data/$what${sub1 == null ? '' : '/$sub1'}";
  response = null;
  responseBody = null;
  err = null;
  try {
    switch (type) {
      case 'get':  response = await dio.get(url, queryParameters: data); break;
      case 'post': response = await dio.post(url, data: data, options: Options(contentType: "application/x-www-form-urlencoded",)); break;
      default:
        url = "$url/$type";
        response = await dio.get(url);
    }
    // responseBody = response?.data;
    responseBody = json.decode(response?.data);
  } on DioError catch (e) {
    if (e.type == DioErrorType.CONNECT_TIMEOUT) {
      // ...
    }
    if (e.type == DioErrorType.RECEIVE_TIMEOUT) {
      // ...
    }
    h.failAlertInternet();
    err = e;
  } catch (e) {
    err = e;
  }
  log("API", type, url, data);
  return responseBody == null ? ApiModel(isSuccess: false) : ApiModel.fromJson(responseBody, type: type);
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
  } on DioError catch (e) {
    if (e.type == DioErrorType.CONNECT_TIMEOUT) {
      // ...
    }
    if (e.type == DioErrorType.RECEIVE_TIMEOUT) {
      // ...
    }
    h.failAlertInternet();
    err = e;
  } catch (e) {
    err = e;
  }
  log("AUTH", "post", url, data);
  return responseBody == null ? ApiModel(isSuccess: false) : ApiModel.fromJson(responseBody, type: 'post');
}

log(String tag, String type, String url, Map<String, dynamic> data) {
  type = type.toUpperCase();
  print(
    "\n ==> $tag $type $url URL: ${dio.options.baseUrl}$url"
    "\n ==> $tag $type $url PARAMS: $data"
    "\n ==> $tag $type $url RESPONSE: $response"
    "\n ==> $tag $type $url STATUS CODE: ${response?.statusCode}"
    "\n ==> $tag $type $url ERROR: $err"
  );
}