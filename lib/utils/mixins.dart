import 'package:flutter/material.dart';

abstract class MainPageStateMixin<T extends StatefulWidget> extends State<T> {
  void onPageVisible();
  void onPageInvisible();
}