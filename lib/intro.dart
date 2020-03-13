import 'dart:async';

import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_analytics/observer.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:wakelock/wakelock.dart';
import 'components/intro/page_dragger.dart';
import 'components/intro/page_reveal.dart';
import 'components/intro/pager_indicator.dart';
import 'components/intro/pages.dart';
import 'utils/helpers.dart';
import 'login.dart';

const INTRO_PAGE_LENGTH = 3;

class Intro extends StatefulWidget {
  Intro({Key key, @required this.analytics, @required this.observer}) : super(key: key);
  final FirebaseAnalytics analytics;
  final FirebaseAnalyticsObserver observer;

  @override
  _IntroState createState() => _IntroState(analytics, observer);
}

class _IntroState extends State<Intro> with TickerProviderStateMixin {
  _IntroState(this.analytics, this.observer);
  final FirebaseAnalytics analytics;
  final FirebaseAnalyticsObserver observer;

  @override
  void initState() {
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
    initializeHelpers(context, "after init _IntroState");
    return WillPopScope(
      onWillPop: () async => Future<bool>.value(false),
      child: Scaffold(
        body: IntroPage(analytics: analytics, observer: observer),
      ),
    );
  }
}

class IntroPage extends StatefulWidget {
  IntroPage({Key key, @required this.analytics, @required this.observer}) : super(key: key);
  final FirebaseAnalytics analytics;
  final FirebaseAnalyticsObserver observer;

  @override
  _IntroPageState createState() => _IntroPageState(analytics, observer);
}

class _IntroPageState extends State<IntroPage> with TickerProviderStateMixin {
  StreamController<SlideUpdate> slideUpdateStream;
  AnimatedPageDragger animatedPageDragger;

  var _activeIndex = 0;
  var _slideDirection = SlideDirection.none;
  var _nextPageIndex = 0;
  var _slidePercent = 0.0;

  final FirebaseAnalytics analytics;
  final FirebaseAnalyticsObserver observer;

  _IntroPageState(this.analytics, this.observer) {
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
          animatedPageDragger.dispose();
          if (_activeIndex == INTRO_PAGE_LENGTH) {
            print(" -> wakelock: DISABLED");
            Wakelock.disable();
          } else {
            _slidePercent = 0.0;
          }
        }
      });
    });
  }

  @override
  void initState() {
    _activeIndex = isFirstRun ? 0 : INTRO_PAGE_LENGTH;
    _slidePercent = isFirstRun ? 0.0 : 1.0;
    _nextPageIndex = _activeIndex;
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
    });
  }

  @override
  Widget build(BuildContext context) {
    final imageWidth = h.screenSize.width * 0.69;
    final pages = [
      PageViewModel(
        color: Colors.purple[400],
        hero: SvgPicture.asset(
          'images/onboarding/1.svg',
          semanticsLabel: 'Intro 1',
          width: imageWidth,
        ),
        icon: LineIcons.tags,
        title: 'Banyak Barang',
        body: 'Apakah kamu sering buang duit untuk berbelanja barang-barang yang gak penting?',
      ),
      PageViewModel(
        color: Colors.green[400],
        hero: SvgPicture.asset(
          'images/onboarding/2.svg',
          semanticsLabel: 'Intro 2',
          width: imageWidth,
        ),
        icon: LineIcons.mobile_phone,
        title: 'Jangan Bingung',
        body: 'Beritahu orang-orang kalau kamu punya barang-barang itu. Mungkin saja mereka berminat.',
      ),
      PageViewModel(
        color: Colors.teal[400],
        hero: SvgPicture.asset(
          'images/onboarding/3.svg',
          semanticsLabel: 'Intro 3',
          width: imageWidth,
        ),
        icon: LineIcons.cloud,
        title: 'Sebarkan!',
        body: 'Pasang iklan apa saja seperti produk baru, bekas, bisnis, jasa, loker, kos-kosan. Semua bisa!',
      ),
    ];
    return Stack(
      children: [
        _activeIndex == pages.length ? Container() : GestureDetector(
          onTap: () {
            print("HALAMAN SLIDE: $_activeIndex");
            if (_activeIndex < pages.length) {
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
            }
          },
          child: Page(
            viewModel: pages[_activeIndex],
            percentVisible: 1.0,
          ),
        ),
        PageReveal(
          revealPercent: _slidePercent,
          child: _nextPageIndex == pages.length ? Login(
            analytics: analytics,
            observer: observer,
            arguments: {'noSplash': true},
          ) : Page(
            viewModel: pages[_nextPageIndex],
            percentVisible: _slidePercent,
          ),
        ),
        IgnorePointer(
          ignoring: _activeIndex == pages.length,
          child: Opacity(
            opacity: _activeIndex == pages.length ? 0.0 : (_nextPageIndex == pages.length ? 1.0 - _slidePercent : 1.0),
            child: PagerIndicator(
              viewModel: PagerIndicatorViewModel(
                pages,
                _activeIndex,
                _slideDirection,
                _slidePercent,
              ),
            ),
          ),
        ),
        IgnorePointer(
          ignoring: _activeIndex == pages.length,
          child: PageDragger(
            canDragLeftToRight: _activeIndex > 0 && _activeIndex < pages.length,
            canDragRightToLeft: _activeIndex < pages.length,
            slideUpdateStream: this.slideUpdateStream,
          ),
        ),
      ],
    );
  }
}