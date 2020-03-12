import 'package:flutter/material.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_analytics/observer.dart';
import 'package:provider/provider.dart';
// import 'services/firestore_service.dart';
// import 'models/report.dart';
import 'providers/notifications.dart';
import 'providers/person.dart';
import 'utils/constants.dart';
import 'utils/helpers.dart';
import 'login.dart';

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
        home: Login(
          analytics: analytics,
          observer: observer,
        ),
      ),
    );
  }
}