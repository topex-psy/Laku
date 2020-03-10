import 'package:flutter/material.dart';
import 'utils/constants.dart';
import 'utils/helpers.dart';
import 'login.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // cek apakah aplikasi berjalan dalam mode debug
    assert(isDebugMode = true);

    return MaterialApp(
      title: APP_NAME,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: Color(0XFFDEFFF3),
        primarySwatch: THEME_COLOR,
        fontFamily: THEME_FONT_MAIN,
      ),
      home: Login(),
    );
  }
}