import 'package:flutter/material.dart';
// import 'package:line_icons/line_icons.dart';
import 'utils/constants.dart';

const SPLASH_LOGO_SIZE = 200.0;

class Splash extends StatefulWidget {
  @override
  _SplashState createState() => _SplashState();
}

class _SplashState extends State<Splash> with TickerProviderStateMixin {
  AnimationController _animation1Controller, _animation2Controller, _animation3Controller;
  Animation _animation1, _animation2, _animation3;
  bool _showOriginal = false;

  @override
  void initState() {
    _animation1Controller = AnimationController(duration: Duration(milliseconds: 500), vsync: this);
    _animation2Controller = AnimationController(duration: Duration(milliseconds: 1500), vsync: this);
    _animation3Controller = AnimationController(duration: Duration(milliseconds: 1500), vsync: this);
    _animation1 = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _animation1Controller,
      curve: Curves.ease
    ));
    _animation2 = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _animation1Controller,
      curve: Curves.easeOutBack
    ));
    _animation3 = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _animation1Controller,
      curve: Curves.bounceInOut
    ));
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(Duration(milliseconds: 500), () {
        _animation1Controller.forward();
      });
      Future.delayed(Duration(milliseconds: 1000), () {
        _animation2Controller.forward();
      });
      Future.delayed(Duration(milliseconds: 1250), () {
        _animation3Controller.forward();
      });
      Future.delayed(Duration(milliseconds: 3000), () {
        Navigator.of(context).pop({'isSplashDone': true});
      });
    });
  }

  @override
  void dispose() {
    _animation1Controller.dispose();
    _animation2Controller.dispose();
    _animation3Controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: THEME_COLOR,
      // floatingActionButton: FloatingActionButton(child: Icon(_showOriginal ? LineIcons.image : null), onPressed: () {
      //   setState(() {
      //     _showOriginal = !_showOriginal;
      //   });
      // }),
      body: SafeArea(
        child: Center(
          child: Hero(
            tag: "SplashLogo",
            child: Stack(
              alignment: Alignment.center,
              children: <Widget>[
                Image.asset('images/logo_bg.png', width: SPLASH_LOGO_SIZE, fit: BoxFit.fitWidth,),
                AnimatedBuilder(
                  animation: _animation1Controller,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, 17 * _animation1.value),
                      child: Opacity(
                        opacity: _animation1.value,
                        child: Image.asset('images/logo_teks.png', width: SPLASH_LOGO_SIZE, fit: BoxFit.fitWidth,),
                      )
                    );
                  }
                ),
                AnimatedBuilder(
                  animation: _animation2Controller,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(41.75, -22.5),
                      child: Transform.scale(
                        scale: 1 * _animation2.value,
                        child: Opacity(
                          opacity: 0.8,
                          child: Container(width: 25, height: 25, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white,),),
                        ),
                      )
                    );
                  }
                ),
                AnimatedBuilder(
                  animation: _animation3Controller,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(11, -53.5),
                      child: Transform.scale(
                        scale: 1 * _animation3.value,
                        child: Opacity(
                          opacity: 0.6,
                          child: Container(width: 36.5, height: 36.5, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white,),),
                        ),
                      )
                    );
                  }
                ),
                _showOriginal ? Image.asset('images/logo.png', width: SPLASH_LOGO_SIZE, fit: BoxFit.fitWidth,) : SizedBox(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}