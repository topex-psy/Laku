import 'package:flutter/material.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_analytics/observer.dart';
import 'package:provider/provider.dart';
// import 'services/firestore_service.dart';
// import 'models/report.dart';
import 'providers/notifications.dart';
import 'providers/person.dart';
import 'providers/settings.dart';
import 'utils/constants.dart';
import 'utils/helpers.dart';
import 'home.dart';
import 'intro.dart';
// import 'login.dart';
import 'profil.dart';
import 'splash.dart';
import 'tambah.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {

  // inisiasi firebase analytics untuk route navigation observer
  static FirebaseAnalytics analytics = FirebaseAnalytics();
  static FirebaseAnalyticsObserver observer = FirebaseAnalyticsObserver(analytics: analytics);

  @override
  Widget build(BuildContext context) {
    // cek apakah aplikasi berjalan dalam mode debug
    assert(isDebugMode = true);

    // final _firestore = FirestoreService();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => PersonProvider()),
        ChangeNotifierProvider(create: (context) => NotificationsProvider()),
        ChangeNotifierProvider(create: (context) => SettingsProvider()),
        // StreamProvider<ReportModel>.value(value: _firestore.getReport()),
        // StreamProvider(create: (context) => _firestore.getReport())
      ],
      child: MaterialApp(
        title: APP_NAME,
        debugShowCheckedModeBanner: false,
        locale: Locale('id', 'ID'),
        // localizationsDelegates: [
        //   GlobalMaterialLocalizations.delegate,
        //   GlobalWidgetsLocalizations.delegate,
        //   GlobalCupertinoLocalizations.delegate,
        //   RefreshLocalizations.delegate,
        // ],
        // supportedLocales: [
        //   Locale('id', 'ID'),
        //   Locale('en', 'US'),
        // ],
        theme: ThemeData(
          scaffoldBackgroundColor: THEME_BACKGROUND,
          primarySwatch: THEME_COLOR,
          fontFamily: THEME_FONT_MAIN,
        ),
        onGenerateRoute: (RouteSettings settings) {
          final Map arguments = settings.arguments ?? {};
          print(" ==> TO ROUTE NAME: ${settings.name}");
          print(" ==> TO ROUTE ARGS: $arguments");
          switch (settings.name) {
            case ROUTE_SPLASH:
              return MaterialPageRoute(settings: settings, builder: (_) => Splash());
            case ROUTE_INTRO:
              return MaterialPageRoute(settings: settings, builder: (_) => Intro(analytics: analytics, observer: observer,));
            case ROUTE_PROFIL:
              return MaterialPageRoute(settings: settings, builder: (_) => Profil());
            case ROUTE_TAMBAH:
              return MaterialPageRoute(settings: settings, builder: (_) => Tambah());
            case ROUTE_HOME:
            case '/':
            default:
              return MaterialPageRoute(settings: settings, builder: (_) => Home());
          }
        },
        initialRoute: ROUTE_SPLASH,
        home: Splash(),
      ),
    );
  }
}