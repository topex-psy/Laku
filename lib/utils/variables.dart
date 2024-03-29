import 'package:flutter/material.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_analytics/observer.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:line_icons/line_icons.dart';
import 'package:preload_page_view/preload_page_view.dart';

import 'helpers.dart';
import 'models.dart';

var isDebugMode = false;

// String languageCode = "id";

late FirebaseAnalytics firebaseAnalytics;
late FirebaseAnalyticsObserver firebaseObserver;
late String languageCode;
late UIHelper h;
late UserHelper u;
late FormatHelper f;
final l = LocationHelper();
final a = AppHelper();

SessionModel? session;
UserModel? profile;

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
  MenuModel('Semua', 'all', icon: LineIcons.searchLocation),
  MenuModel('Jual-Beli', 'market', icon: LineIcons.searchLocation),
  MenuModel('Tempat', 'place', icon: LineIcons.searchLocation),
  MenuModel('Servis', 'service', icon: LineIcons.searchLocation),
  MenuModel('Event', 'event', icon: LineIcons.searchLocation),
  MenuModel('Loker', 'job', icon: LineIcons.searchLocation),
  MenuModel('Jodoh', 'dating', icon: LineIcons.searchLocation),
  MenuModel('Lainnya', 'other', icon: LineIcons.searchLocation),
];
