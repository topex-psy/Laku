import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'constants.dart';
import 'variables.dart';

class ApiProvider {
  ApiProvider(this.context);

  final BuildContext context;
  final baseOptions = BaseOptions(
    baseUrl: isDebugMode ? "http://192.168.1.68/yaku/api" : APP_URL_API,
    connectTimeout: 60000,
    receiveTimeout: 60000,
    sendTimeout: 60000,
  );

  Future<ApiModel> api(String url, {
    String method = "get",
    Map<String, String?> getParams = const {},
    dynamic data,
    Options? options,
    void Function(int, int)? onSendProgress,
    bool withLog = false,
  }) async {
    if (method.toLowerCase() == 'get') getParams = {...getParams, "lang": context.locale.languageCode, 'uid': session!.id.toString()};
    print("${method.toUpperCase()} $url $getParams");
    try {
      var response = method.toLowerCase() == 'post'
        ? await Dio(baseOptions).post('/$url', queryParameters: getParams, data: data, options: options, onSendProgress: onSendProgress)
        : method.toLowerCase() == 'put'
        ? await Dio(baseOptions).put('/$url', queryParameters: getParams, data: data, options: options, onSendProgress: onSendProgress)
        : await Dio(baseOptions).get('/$url', queryParameters: getParams);
      Map<String, dynamic>? responseBody = response.data is String ? json.decode(response.data) : response.data;
      if (withLog) {
        log("> data: ${f.formatJson(data)}");
        log("> response: ${f.formatJson(responseBody)}");
      }
      return ApiModel.fromJson(responseBody);
    } catch (e) {
      if (e is DioError) {
        switch (e.type) {
          case DioErrorType.connectTimeout:
            print("DioErrorType.connectTimeout");
            break;
          case DioErrorType.receiveTimeout:
            print("DioErrorType.receiveTimeout");
            break;
          default:
            print("DioErrorType.other");
        }
        print("dio error: $e");
        // DioError [DioErrorType.other]: SocketException: OS Error: Connection timed out, errno = 110, address = 192.168.1.68, port = 44796
        print("dio error response: ${e.response}");
        print("dio error error: ${e.error}");
        // SocketException: OS Error: Connection timed out, errno = 110, address = 192.168.1.68, port = 44892
      } else {
        print("api error: $e");
      }
      return ApiModel(message: "$e");
    }
  }
}

class ApiModel {
  ApiModel({
    this.data = const [],
    this.isSuccess = false,
    this.message = '',
    this.totalAll = 0,
  });

  final List<Map<String, dynamic>> data;
  final bool isSuccess;
  final String message;
  final int totalAll;

  ApiModel.fromJson(Map<String, dynamic>? responseBody)
  : isSuccess = responseBody != null && responseBody["success"],
    data = responseBody != null && responseBody["success"]
      ? List.from(responseBody.containsKey("rows") ? responseBody["rows"] : [responseBody]).map((res) => Map<String, dynamic>.from(res)).toList()
      : [],
    message = responseBody != null ? (responseBody["message"] ?? "no-message") : "null-response",
    totalAll = responseBody != null && responseBody.containsKey("total_all") ? responseBody["total_all"] : 0;

  @override
  String toString() => "ApiModel"
    "\n> data: $data"
    "\n> message: $message"
    "\n> success: $isSuccess";
}