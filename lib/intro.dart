import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:line_icons/line_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock/wakelock.dart';
import 'components/intro/page_dragger.dart';
import 'components/intro/page_reveal.dart';
import 'components/intro/pager_indicator.dart';
import 'components/intro/pages.dart';
import 'utils/constants.dart';
import 'utils/helpers.dart';

class Intro extends StatefulWidget {
  @override
  _IntroState createState() => _IntroState();
}

class _IntroState extends State<Intro> with TickerProviderStateMixin {
  StreamController<SlideUpdate> slideUpdateStream;
  AnimatedPageDragger animatedPageDragger;

  var _activeIndex = 0;
  var _slideDirection = SlideDirection.none;
  var _nextPageIndex = 0;
  var _slidePercent = 0.0;
  var _isWillExit = false;

  _IntroState() {
    slideUpdateStream = StreamController<SlideUpdate>();
    slideUpdateStream.stream.listen((SlideUpdate event) {
      setState(() {
        if (event.updateType == UpdateType.dragging) {
          _slideDirection = event.direction;
          _slidePercent = event.slidePercent;

          if (_slideDirection == SlideDirection.leftToRight) {
            _nextPageIndex = _activeIndex - 1;
          } else if (_slideDirection == SlideDirection.rightToLeft) {
            _nextPageIndex = _activeIndex + 1;
          } else {
            _nextPageIndex = _activeIndex;
          }
        } else if (event.updateType == UpdateType.doneDragging) {
          if (_slidePercent > 0.333) {
            animatedPageDragger = AnimatedPageDragger(
              slideDirection: _slideDirection,
              transitionGoal: TransitionGoal.open,
              slidePercent: _slidePercent,
              slideUpdateStream: slideUpdateStream,
              vsync: this,
            );
          } else {
            animatedPageDragger = AnimatedPageDragger(
              slideDirection: _slideDirection,
              transitionGoal: TransitionGoal.close,
              slidePercent: _slidePercent,
              slideUpdateStream: slideUpdateStream,
              vsync: this,
            );
            _nextPageIndex = _activeIndex;
          }

          animatedPageDragger.run();
        } else if (event.updateType == UpdateType.animating) {
          _slideDirection = event.direction;
          _slidePercent = event.slidePercent;
        } else if (event.updateType == UpdateType.doneAnimating) {
          _activeIndex = _nextPageIndex;
          _slideDirection = SlideDirection.none;
          _slidePercent = 0.0;
          animatedPageDragger.dispose();
        }
      });
    });
  }

  @override
  void initState() {
    _activeIndex = 0;
    _slidePercent = 0.0;
    _nextPageIndex = _activeIndex;
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      FocusScope.of(context).requestFocus(FocusNode());
      setState(() {
        print(" -> wakelock: ENABLED");
        Wakelock.enable();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    h = UIHelper(context);
    a = UserHelper(context);
    f = FormatHelper();

    final imageWidth = MediaQuery.of(context).size.width * 0.69;
    final pages = [
      PageViewModel(
        color: Colors.purple[400],
        hero: Image.asset('images/onboarding/1.png', width: imageWidth,),
        icon: LineIcons.tags,
        title: 'Banyak Barang',
        body: 'Apakah kamu sering buang duit untuk berbelanja barang-barang yang gak penting?',
      ),
      PageViewModel(
        color: Colors.green[400],
        hero: Image.asset('images/onboarding/2.png', width: imageWidth,),
        icon: LineIcons.mobile_phone,
        title: 'Jangan Bingung',
        body: 'Beritahu orang-orang kalau kamu punya barang-barang itu. Mungkin mereka lebih butuh.',
      ),
      PageViewModel(
        color: Colors.teal[400],
        hero: Image.asset('images/onboarding/3.png', width: imageWidth,),
        icon: LineIcons.cloud,
        title: 'Jadi Duit!',
        body: 'Pasang iklan apa saja seperti produk baru, bekas, bisnis, jasa, loker, kos-kosan. Semua bisa!',
      ),
    ];
    return WillPopScope(
      onWillPop: () async {
        if (_activeIndex > 0) {
          setState(() {
            animatedPageDragger = AnimatedPageDragger(
              slideDirection: SlideDirection.leftToRight,
              transitionGoal: TransitionGoal.open,
              slidePercent: 0.0,
              slideUpdateStream: slideUpdateStream,
              vsync: this,
            );
            _nextPageIndex = _activeIndex - 1;
            animatedPageDragger.run();
          });
        } else {
          if (_isWillExit) return SystemChannels.platform.invokeMethod<bool>('SystemNavigator.pop');
          h.showToast("Ketuk sekali lagi untuk menutup aplikasi.");
          _isWillExit = true;
          Future.delayed(Duration(milliseconds: 2000), () { _isWillExit = false; });
        }
        return false;
      },
      child: Scaffold(
        body: Stack(
          children: [
            _activeIndex == pages.length ? Container() : GestureDetector(
              onTap: () {
                print("HALAMAN SLIDE: $_activeIndex");
                if (_activeIndex < pages.length - 1) {
                  setState(() {
                    animatedPageDragger = AnimatedPageDragger(
                      slideDirection: SlideDirection.rightToLeft,
                      transitionGoal: TransitionGoal.open,
                      slidePercent: 0.0,
                      slideUpdateStream: slideUpdateStream,
                      vsync: this,
                    );
                    _nextPageIndex = _activeIndex + 1;
                    animatedPageDragger.run();
                  });
                } else {
                  if (isFirstRun) SharedPreferences.getInstance().then((prefs) {
                    prefs.setBool('isFirstRun', false);
                    isFirstRun = false;
                  });
                  setState(() {
                    print(" -> wakelock: DISABLED");
                    Wakelock.disable();
                  });
                  Navigator.of(context).pushNamedAndRemoveUntil(ROUTE_LOGIN, (route) => false);
                }
              },
              child: OnboardingPage(
                viewModel: pages[_activeIndex],
                percentVisible: 1.0,
              ),
            ),
            PageReveal(
              revealPercent: _slidePercent,
              child: OnboardingPage(
                viewModel: pages[_nextPageIndex],
                percentVisible: _slidePercent,
              ),
            ),
            PagerIndicator(
              viewModel: PagerIndicatorViewModel(
                pages,
                _activeIndex,
                _slideDirection,
                _slidePercent,
              ),
            ),
            PageDragger(
              canDragLeftToRight: _activeIndex > 0 && _activeIndex < pages.length,
              canDragRightToLeft: _activeIndex < pages.length - 1,
              slideUpdateStream: this.slideUpdateStream,
            ),
          ],
        ),
      ),
    );
  }
}