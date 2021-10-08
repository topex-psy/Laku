import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock/wakelock.dart';

import '../components/intro/page_dragger.dart';
import '../components/intro/page_reveal.dart';
import '../components/intro/pager_indicator.dart';
import '../components/intro/pages.dart';
import '../utils/variables.dart';

class IntroPage extends StatefulWidget {
  const IntroPage(this.args, {Key? key}) : super(key: key);
  final Map<String, dynamic> args;

  @override
  _IntroPageState createState() => _IntroPageState();
}

class _IntroPageState extends State<IntroPage> with TickerProviderStateMixin {

  StreamController<SlideUpdate> slideUpdateStream = StreamController<SlideUpdate>();
  AnimatedPageDragger? animatedPageDragger;

  var _activeIndex = 0;
  var _slideDirection = SlideDirection.none;
  var _nextPageIndex = 0;
  var _slidePercent = 0.0;

  _IntroPageState() {
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
          if (_slidePercent > 1 / 3) {
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

          animatedPageDragger?.run();
        } else if (event.updateType == UpdateType.animating) {
          _slideDirection = event.direction;
          _slidePercent = event.slidePercent;
        } else if (event.updateType == UpdateType.doneAnimating) {
          _activeIndex = _nextPageIndex;
          _slideDirection = SlideDirection.none;
          _slidePercent = 0.0;
          animatedPageDragger?.dispose();
        }
      });
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance?.addPostFrameCallback((_) async {
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    final _imageWidth = MediaQuery.of(context).size.width * 0.69;
    final _pages = [
      PageViewModel(
        color: Colors.purple[400]!,
        hero: Image.asset('assets/images/onboarding/1.png', width: _imageWidth,),
        icon: LineIcons.tags,
        title: 'Banyak Barang',
        body: 'Apa kamu punya banyak barang yang sudah tak terpakai dan bingung menyimpannya?',
      ),
      PageViewModel(
        color: Colors.green[400]!,
        hero: Image.asset('assets/images/onboarding/2.png', width: _imageWidth,),
        icon: LineIcons.mobilePhone,
        title: 'Jangan Bingung',
        body: 'Beritahu orang-orang kalau kamu punya barang-barang itu. Mungkin saja mereka butuh.',
      ),
      PageViewModel(
        color: Colors.teal[400]!,
        hero: Image.asset('assets/images/onboarding/3.png', width: _imageWidth,),
        icon: LineIcons.cloud,
        title: 'Jadikan Duit!',
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
            animatedPageDragger?.run();
          });
          return false;
        }
        return true;
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          child: Stack(
            children: [
              _activeIndex == _pages.length ? Container() : GestureDetector(
                onTap: () async {
                  if (_activeIndex < _pages.length - 1) {
                    setState(() {
                      animatedPageDragger = AnimatedPageDragger(
                        slideDirection: SlideDirection.rightToLeft,
                        transitionGoal: TransitionGoal.open,
                        slidePercent: 0.0,
                        slideUpdateStream: slideUpdateStream,
                        vsync: this,
                      );
                      _nextPageIndex = _activeIndex + 1;
                      animatedPageDragger?.run();
                    });
                  } else {
                    SharedPreferences prefs = await SharedPreferences.getInstance();
                    prefs.setBool('isFirstRun', false);
                    isFirstRun = false;
                    Wakelock.disable();
                    Navigator.of(context).pop();
                  }
                },
                child: OnboardingPage(
                  viewModel: _pages[_activeIndex],
                  percentVisible: 1.0,
                ),
              ),
              PageReveal(
                revealPercent: _slidePercent,
                child: OnboardingPage(
                  viewModel: _pages[_nextPageIndex],
                  percentVisible: _slidePercent,
                ),
              ),
              PagerIndicator(
                viewModel: PagerIndicatorViewModel(
                  _pages,
                  _activeIndex,
                  _slideDirection,
                  _slidePercent,
                ),
              ),
              PageDragger(
                canDragLeftToRight: _activeIndex > 0 && _activeIndex < _pages.length,
                canDragRightToLeft: _activeIndex < _pages.length - 1,
                slideUpdateStream: slideUpdateStream,
              ),
            ],
          ),
        ),
      ),
    );
  }
}