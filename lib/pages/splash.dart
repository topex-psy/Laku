import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../utils/constants.dart';
import '../utils/variables.dart';
import '../utils/widgets.dart';

const SPLASH_LOGO_SIZE = 180.0;
const SPLASH_DURATION = 2000;

class SplashPage extends StatefulWidget {
  const SplashPage({Key? key}) : super(key: key);

  @override
  _SplashPageState createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance?.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: SPLASH_DURATION), _dismiss);
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  _dismiss() {
    Navigator.of(context).pushReplacementNamed(ROUTE_LOGIN, arguments: {'duration': 2000});
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => Future<bool>.value(false),
      child: Scaffold(
        backgroundColor: APP_UI_COLOR_MAIN,
        body: SafeArea(
          child: Center(
            child: GestureDetector(
              onTap: isDebugMode ? _dismiss : null,
              child: Stack(
                alignment: Alignment.center,
                children: <Widget>[
                  const Hero(
                    tag: "splash_logo",
                    child: MyAppLogo(type: MyLogoType.text, size: SPLASH_LOGO_SIZE, fit: BoxFit.fitWidth,)
                  ),
                  Transform.translate(
                    child: const SpinKitChasingDots(color: Colors.white70, size: 100,),
                    offset: const Offset(40, -50),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}