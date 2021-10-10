import 'package:flutter/material.dart';

const APP_NAME           = "Yaku";
const APP_DESCRIPTION    = "Aplikasi super praktis buat ngiklan apa aja ke sekitarmu.";
const APP_TAGLINE        = "Yakin laku pake Yaku";
const APP_COPYRIGHT      = "TaufikNur Production";
const APP_LOCALE         = Locale('id', 'ID');
const APP_LOCALE_SUPPORT = [Locale('id', 'ID'), Locale('en', 'US')];
const APP_PHONE_CODE     = '+62';
const APP_URL_HOST       = "https://www.taufiknur.com/yaku";
const APP_URL_PRIVACY    = "$APP_URL_HOST/privacy";
const APP_URL_TERMS      = "$APP_URL_HOST/terms";
const APP_URL_API        = "$APP_URL_HOST/api";
const APP_FACEBOOK_ID    = "844479926196457";

// colors from: https://maketintsandshades.com/#009688
const APP_UI_COLOR_MAIN    = Color(0xFF009688);
const APP_UI_COLOR_ACCENT  = Color(0xFF75c6bf);
const APP_UI_COLOR_SUCCESS = Color(0xFF08D159);
const APP_UI_COLOR_WARNING = Color(0xFFDECB21);
const APP_UI_COLOR_DANGER  = Color(0xFFFF1744);
const APP_UI_COLOR_INFO    = Color(0xFF21A5DE);
const APP_UI_COLOR_PRIMARY = Color(0xFF2176DE);
const APP_UI_COLOR_SECONDARY = Color(0xFFD6D6D6);
const APP_UI_COLOR_LIGHT   = Color(0xFFF1F3F1);
const APP_UI_COLOR = MaterialColor(0xFFDC143C, <int, Color>{
  50:  Color(0xFFE6F5F3),
  100: Color(0xFFCCEAE7),
  200: Color(0xFF99D5CF),
  300: Color(0xFF66C0B8),
  400: Color(0xFF33ABA0),
  500: APP_UI_COLOR_MAIN,
  600: Color(0xFF00786D),
  700: Color(0xFF005A52),
  800: Color(0xFF003C36),
  900: Color(0xFF001E1B),
},);

const APP_UI_BACKGROUND_LIGHT = Color(0xFFF2FAF9);
const APP_UI_BACKGROUND_DARK  = Color(0xFF262224);
const APP_UI_BORDER_COLOR     = Colors.grey;
const APP_UI_BORDER_RADIUS    = 8.0;
const APP_UI_BUTTON_ELEVATION = 2.0;
const APP_UI_CARD_ELEVATION   = 4.0;
const APP_UI_CARD_RADIUS      = 8.0;
const APP_UI_CONTENT_PADDING  = 20.0;
const APP_UI_FONT_MAIN        = "Quicksand";
const APP_UI_FONT_SECONDARY   = "Lato";
const APP_UI_INPUT_HEIGHT     = 48.0;
const APP_UI_THEME_LIGHT      = "theme_light";
const APP_UI_THEME_DARK       = "theme_dark";

const ROUTE_INTRO      = '/Intro';
const ROUTE_LOGIN      = '/Login';
const ROUTE_REGISTER   = '/Register';
const ROUTE_DASHBOARD  = '/Dashboard';
const ROUTE_PROFILE    = '/Profile';
const ROUTE_CREATE     = '/Create';
const ROUTE_LISTING    = '/Listing';
const ROUTE_MAP        = '/Map';

const DEBUG_USER = "topexgames@yahoo.com";
const DEBUG_TOUR = true;
const DEBUG_ONBOARDING = false;

const SETUP_IMAGE_COMPRESS_QUALITY = 75;
const SETUP_IMAGE_COMPRESS_RESIZE = 1000;
const SETUP_IMAGE_NONE = "assets/images/none.jpg";
const SETUP_IMAGE_NONE_USER = "assets/images/anon.png";
const SETUP_MAX_LENGTH_PIN = 6;
const SETUP_MAX_LENGTH_CURRENCY = 15;
const SETUP_MAX_USER_AGE = 100;
const SETUP_MIN_USER_AGE = 13;
