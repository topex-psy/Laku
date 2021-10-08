import 'package:flutter/material.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_analytics/observer.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:line_icons/line_icons.dart';
import 'package:preload_page_view/preload_page_view.dart';

import 'helpers.dart';
import 'models.dart';

late FirebaseAnalytics firebaseAnalytics;
late FirebaseAnalyticsObserver firebaseObserver;

bool isDebugMode = false;
SessionModel? session;
UserModel? profile;
UIHelper? h;
UserHelper? u;
FormatHelper? f;
final l = LocationHelper();
final a = AppHelper();

final screenPageController = PreloadPageController();
final screenScaffoldKey = GlobalKey<ScaffoldState>();
const screenNames = [ "home", "browse", "broadcast", "profile" ];
const tabHome = 0;
const tabBrowse = 1;
const tabBroadcast = 2;
const tabProfile = 3;

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
  MenuModel(tr('gender.male'), 'm'),
  MenuModel(tr('gender.female'), 'f'),
];

final pickImageOptions = <MenuModel>[
  MenuModel(tr('action_browse.camera'), ImageSource.camera, icon: Icons.camera),
  MenuModel(tr('action_browse.gallery'), ImageSource.gallery, icon: Icons.image),
];

final listingCategories = [
  MenuModel('Semua', 'all', icon: LineIcons.at),
  MenuModel('Jual-Beli', 'market', icon: LineIcons.at),
  MenuModel('Tempat', 'place', icon: LineIcons.at),
  MenuModel('Servis', 'service', icon: LineIcons.at),
  MenuModel('Event', 'event', icon: LineIcons.at),
  MenuModel('Loker', 'job', icon: LineIcons.at),
  MenuModel('Jodoh', 'dating', icon: LineIcons.at),
  MenuModel('Lainnya', 'other', icon: LineIcons.at),
];
