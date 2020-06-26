import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_analytics/observer.dart';
import 'package:page_transition/page_transition.dart';
import 'package:provider/provider.dart';
import 'providers/person.dart';
import 'providers/settings.dart';
import 'utils/constants.dart';
import 'utils/helpers.dart';
import 'login.dart';
import 'register.dart';
import 'datalist.dart';
import 'home.dart';
import 'pasang.dart';
import 'peta.dart';
import 'profil.dart';
import 'splash.dart';

void main() {
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    systemNavigationBarIconBrightness: Brightness.light,
    statusBarIconBrightness: Brightness.light,
    // systemNavigationBarColor: Colors.teal[700],
    statusBarColor: Colors.teal[800],
  ));
  final supportedLocales = [Locale('id', 'ID'), Locale('en', 'US')];
  final defaultLocale = Locale('id', 'ID');
  WidgetsFlutterBinding.ensureInitialized();
  runApp(EasyLocalization(
    path: 'assets/translations',
    supportedLocales: supportedLocales,
    fallbackLocale: defaultLocale,
    startLocale: defaultLocale,
    preloaderColor: THEME_COLOR,
    useOnlyLangCode: true,
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

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => PersonProvider()),
        ChangeNotifierProvider(create: (context) => SettingsProvider()),
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
            case ROUTE_SPLASH:   page = Splash(); break;
            case ROUTE_HOME:     page = Home(analytics: analytics, observer: observer,); break;
            case ROUTE_DAFTAR:   page = Register(); break;
            case ROUTE_PASANG:   page = Pasang(arguments); break;
            case ROUTE_PETA:     page = Peta(); break;
            case ROUTE_PROFIL:   page = Profil(); break;
            case ROUTE_DATA:     page = DataList(arguments); break;
          }

          // return MaterialPageRoute(settings: settings, builder: (_) => page);
          return PageTransition(
            type: PageTransitionType.fade,
            duration: Duration(milliseconds: arguments['duration'] ?? 300),
            settings: settings,
            child: page ?? Login()
          );
        },
        navigatorObservers: [MyRouteObserver()],
        initialRoute: '/',
      ),
    );
  }
}

class MyRouteObserver extends RouteObserver<PageRoute<dynamic>> {
  void _sendScreenView(String what, PageRoute<dynamic> routeTo, PageRoute<dynamic> routeFrom) {
    var newScreenName = routeTo?.settings?.name;
    var oldScreenName = routeFrom?.settings?.name;
    if (what == "pop") print(' ==> ROUTE DID $what: $newScreenName => $oldScreenName');
    else print(' ==> ROUTE DID $what: $oldScreenName => $newScreenName');
    // do something with it, ie. send it to your analytics service collector
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic> previousRoute) {
    super.didPush(route, previousRoute);
    if (route is PageRoute) {
      _sendScreenView("push", route, previousRoute);
    }
  }

  @override
  void didReplace({Route<dynamic> newRoute, Route<dynamic> oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute is PageRoute) {
      _sendScreenView("replace", newRoute, oldRoute);
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic> previousRoute) {
    super.didPop(route, previousRoute);
    if (previousRoute is PageRoute && route is PageRoute) {
      _sendScreenView("pop", route, previousRoute);
    }
  }
}