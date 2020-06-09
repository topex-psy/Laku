import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_analytics/observer.dart';
import 'package:provider/provider.dart';
// import 'models/report.dart';
import 'providers/notifications.dart';
import 'providers/person.dart';
import 'providers/settings.dart';
import 'routes/fade.dart';
// import 'services/firestore_service.dart';
import 'utils/constants.dart';
import 'utils/helpers.dart';
// import 'utils/localizations.dart';
import 'daftar.dart';
import 'home.dart';
import 'login.dart';
import 'intro.dart';
import 'peta.dart';
import 'profil.dart';
import 'splash.dart';
import 'tambah.dart';

void main() {
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    systemNavigationBarIconBrightness: Brightness.light,
    statusBarIconBrightness: Brightness.light,
    // systemNavigationBarColor: Colors.teal[700],
    statusBarColor: Colors.teal[800],
  ));
  WidgetsFlutterBinding.ensureInitialized();
  runApp(EasyLocalization(
    supportedLocales: [Locale('id', 'ID'), Locale('en', 'US')],
    path: 'assets/translations',
    fallbackLocale: Locale('id', 'ID'),
    child: MyApp()
  ),);
}

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
        localizationsDelegates: context.localizationDelegates,
        supportedLocales: context.supportedLocales,
        locale: context.locale,
        theme: ThemeData(
          scaffoldBackgroundColor: THEME_BACKGROUND,
          primarySwatch: THEME_COLOR,
          fontFamily: THEME_FONT_MAIN,
        ),
        onGenerateRoute: (RouteSettings settings) {
          final Map arguments = settings.arguments ?? {};
          print(" ==> TO ROUTE: ${settings.name} $arguments");
          Widget page;
          switch (settings.name) {
            case ROUTE_SPLASH: page = Splash(); break;
            case ROUTE_INTRO:  page = Intro();  break;
            case ROUTE_LOGIN:  page = Login();  break;
            case ROUTE_DAFTAR: page = Daftar(); break;
            case ROUTE_PROFIL: page = Profil(); break;
            case ROUTE_TAMBAH: page = Tambah(); break;
            case ROUTE_PETA:   page = Peta(); break;
            case ROUTE_HOME:
            case '/':
            default: page = Home(analytics: analytics, observer: observer,); break;
          }
          // TODO return MaterialPageRoute(settings: settings, builder: (_) => page);
          return FadeRoute(page: page);
        },
        initialRoute: ROUTE_SPLASH,
        home: Splash(),
      ),
    );
  }
}