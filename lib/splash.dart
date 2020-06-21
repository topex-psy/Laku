import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'utils/constants.dart';
import 'utils/helpers.dart';

const SPLASH_LOGO_SIZE = 200.0;
const SPLASH_DISMISS = 2000;

class Splash extends StatefulWidget {
  @override
  _SplashState createState() => _SplashState();
}

class _SplashState extends State<Splash> with TickerProviderStateMixin {
  AnimationController _animation1Controller;
  Animation _animation1;
  var _isFinished = false;

  @override
  void initState() {
    _animation1Controller = AnimationController(duration: Duration(milliseconds: 500), vsync: this);
    _animation1 = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _animation1Controller,
      curve: Curves.ease
    ));
    super.initState();

    // set orientation menjadi portrait untuk sementara
    try {
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    } on PlatformException {
      // PlatformException (PlatformException(error, Only fullscreen activities can request orientation, null))
      print("setPreferredOrientations FAILEEEEEEEEEEEED");
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(FocusNode());
      Future.delayed(Duration(milliseconds: 500), () {
        _startSplash();
      });
    });
  }

  @override
  void dispose() {
    _animation1Controller.dispose();
    // SystemChrome.setPreferredOrientations([
    //   DeviceOrientation.landscapeRight,
    //   DeviceOrientation.landscapeLeft,
    //   DeviceOrientation.portraitUp,
    //   DeviceOrientation.portraitDown,
    // ]);
    super.dispose();
  }

  _startSplash() {
    _animation1Controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) _loadPreferences();
    });
    _animation1Controller.forward();
  }

  _loadPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    isTour1Completed = isDebugMode && DEBUG_TOUR ? false : (prefs.getBool('isTour1Completed') ?? false);
    isTour2Completed = isDebugMode && DEBUG_TOUR ? false : (prefs.getBool('isTour2Completed') ?? false);
    isTour3Completed = isDebugMode && DEBUG_TOUR ? false : (prefs.getBool('isTour3Completed') ?? false);
    isFirstRun = (isDebugMode && DEBUG_ONBOARDING) || (prefs.getBool('isFirstRun') ?? true);
    Future.delayed(Duration(milliseconds: SPLASH_DISMISS), _dismiss);
  }

  _dismiss() {
    setState(() {
      _isFinished = true;
    });
    Navigator.of(context).pushReplacementNamed(isFirstRun ? ROUTE_INTRO : ROUTE_LOGIN, arguments: {'afterSplash': !isFirstRun});
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => Future<bool>.value(false),
      child: Scaffold(
        backgroundColor: THEME_COLOR,
        body: SafeArea(
          child: Center(
            child: GestureDetector(
              onTap: isDebugMode ? _dismiss : null,
              child: Stack(
                alignment: Alignment.center,
                children: <Widget>[
                  // Image.asset('images/logo_bg.png', width: SPLASH_LOGO_SIZE, fit: BoxFit.fitWidth,),
                  AnimatedBuilder(
                    animation: _animation1Controller,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, 17 * _animation1.value),
                        child: Opacity(
                          opacity: _animation1.value,
                          child: Hero(tag: "SplashLogo", child: Image.asset('images/logo_teks.png', width: SPLASH_LOGO_SIZE, fit: BoxFit.fitWidth,)),
                        )
                      );
                    }
                  ),
                  _isFinished ? SizedBox() : Transform.translate(
                    child: SpinKitChasingDots(color: Colors.white70, size: 100,),
                    offset: Offset(40, -50),
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