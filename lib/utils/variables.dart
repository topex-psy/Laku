import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import 'helpers.dart';
import 'models.dart';

bool isDebugMode = false;
SessionModel? session;
UIHelper? h;
UserHelper? u;
FormatHelper? f;
final l = LocationHelper();
final a = AppHelper();

final screenScaffoldKey = GlobalKey<ScaffoldState>();
void reInitContext(BuildContext context) {
  h = UIHelper(context);
  u = UserHelper(context);
  f = FormatHelper(context);
}

var isTour1Completed = false;
var isTour2Completed = false;
var isTour3Completed = false;
var isFirstRun = true;

final genderOptions = <MenuModel>[
  MenuModel(tr('gender_male'), 'M'),
  MenuModel(tr('gender_female'), 'F'),
];

final pickImageOptions = <MenuModel>[
  MenuModel(tr('action_browse.camera'), ImageSource.camera, icon: Icons.camera),
  MenuModel(tr('action_browse.gallery'), ImageSource.gallery, icon: Icons.image),
];
