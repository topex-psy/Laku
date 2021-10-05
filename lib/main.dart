import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_analytics/observer.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';
import 'package:theme_provider/theme_provider.dart';
import 'pages/splash.dart';
import 'pages/intro.dart';
import 'pages/login.dart';
import 'pages/register.dart';
import 'pages/dashboard.dart';
import 'pages/create.dart';
import 'pages/listing.dart';
import 'pages/map.dart';
import 'utils/constants.dart';
import 'utils/providers.dart';
import 'utils/variables.dart';

// handle notifikasi background
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  await Firebase.initializeApp();

  print("push notif got a background message: ${message.messageId}");
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  runApp(EasyLocalization(
    path: 'assets/translations',
    supportedLocales: APP_LOCALE_SUPPORT,
    fallbackLocale: APP_LOCALE,
    startLocale: APP_LOCALE,
    useOnlyLangCode: true,
    child: const MyApp()
  ));
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  static FirebaseAnalytics analytics = FirebaseAnalytics();
  static FirebaseAnalyticsObserver observer = FirebaseAnalyticsObserver(analytics: analytics);

  @override
  Widget build(BuildContext context) {
    // cek apakah aplikasi berjalan dalam mode debug
    assert(isDebugMode = true);

    // menggunakan tipografi material design 2018
    TextTheme textTheme = const TextTheme(
      headline5: TextStyle(fontSize: 30.0, fontWeight: FontWeight.bold),
      headline6: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
      subtitle1: TextStyle(fontSize: 16.0, fontWeight: FontWeight.normal),
      subtitle2: TextStyle(fontSize: 14.0, fontWeight: FontWeight.w500),
      bodyText1: TextStyle(fontSize: 15.0, height: 1.4),
      bodyText2: TextStyle(fontSize: 14.0, height: 1.4),
      button:    TextStyle(fontSize: 15.0, fontWeight: FontWeight.w500),
      caption:   TextStyle(fontSize: 13.0, height: 1.4),
      overline:  TextStyle(fontSize: 11.0, height: 1.4),
    );

    // deklarasi tema terang
    ThemeData lightTheme = ThemeData(
      primarySwatch: APP_UI_COLOR,
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0XFFF8F2FA),
      fontFamily: APP_UI_FONT_MAIN,
      textTheme: textTheme,
    )..textTheme.apply(
      bodyColor: Colors.black,
      displayColor: Colors.black,
    );

    // deklarasi tema gelap
    ThemeData darkTheme = ThemeData(
      primarySwatch: APP_UI_COLOR,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0XFF262224),
      fontFamily: APP_UI_FONT_MAIN,
      textTheme: textTheme,
    )..textTheme.apply(
      bodyColor: Colors.white,
      displayColor: Colors.white,
    );

    // pake multiprovider untuk state management
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => SettingsProvider()),
      ],
      // menyediakan tema custom yang dapat dipilih secara runtime
      child: ThemeProvider(
        saveThemesOnChange: true,
        loadThemeOnInit: true,
        defaultThemeId: APP_UI_THEME_LIGHT,
        themes: [
          AppTheme(
            id: APP_UI_THEME_LIGHT,
            description: "Mode Terang",
            data: lightTheme,
          ),
          AppTheme(
            id: APP_UI_THEME_DARK,
            description: "Mode Gelap",
            data: darkTheme,
          ),
        ],
        child: MaterialApp(
          title: APP_NAME,
          locale: context.locale,
          supportedLocales: context.supportedLocales,
          localizationsDelegates: context.localizationDelegates,
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            scaffoldBackgroundColor: Colors.white,
            primarySwatch: APP_UI_COLOR,
            fontFamily: APP_UI_FONT_MAIN,
            pageTransitionsTheme: const PageTransitionsTheme(
              builders: {
                TargetPlatform.android: CupertinoPageTransitionsBuilder(),
                TargetPlatform.iOS: CupertinoPageTransitionsBuilder()
              }
            ),
          ),
          initialRoute: '/',
          onGenerateRoute: (settings) {
            final args = settings.arguments as Map<String, dynamic>? ?? {};
            Widget page = const SplashPage();
            switch (settings.name) {
              case ROUTE_INTRO: page = IntroPage(analytics, args); break;
              case ROUTE_LOGIN: page = LoginPage(analytics, args); break;
              case ROUTE_REGISTER: page = RegisterPage(analytics, args); break;
              case ROUTE_DASHBOARD: page = DashboardPage(analytics, args); break;
              case ROUTE_CREATE: page = CreatePage(analytics, args); break;
              case ROUTE_LISTING: page = ListingPage(analytics, args); break;
              case ROUTE_MAP: page = MapPage(analytics, args); break;
            }
            // return PageTransition(
            //   type: PageTransitionType.fade,
            //   duration: Duration(milliseconds: arguments['duration'] ?? 300),
            //   settings: settings,
            //   child: page ?? Login()
            // );
            Future.microtask(() => FocusScope.of(context).requestFocus(FocusNode()));
            return MaterialPageRoute(
              settings: settings,
              builder: (context) {
                reInitContext(context);
                return page;
              }
            );
          },
          navigatorObservers: <NavigatorObserver>[observer],
        ),
      ),
    );
  }
}