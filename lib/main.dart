import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/firestore_service.dart';
// import 'models/report.dart';
import 'providers/settings.dart';
import 'utils/constants.dart';
import 'utils/helpers.dart';
import 'login.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // cek apakah aplikasi berjalan dalam mode debug
    assert(isDebugMode = true);

    final _firestore = FirestoreService();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => SettingsProvider()),
        // StreamProvider<ReportModel>.value(value: _firestore.getReport()),
        StreamProvider(create: (context) => _firestore.getReport())
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
          scaffoldBackgroundColor: Color(0XFFDEFFF3),
          primarySwatch: THEME_COLOR,
          fontFamily: THEME_FONT_MAIN,
        ),
        home: Login(),
      ),
    );
  }
}