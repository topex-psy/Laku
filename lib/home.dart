import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_analytics/observer.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:line_icons/line_icons.dart';
import 'package:preload_page_view/preload_page_view.dart';
import 'package:provider/provider.dart';
import 'components/menu.dart';
import 'pages/beranda.dart';
import 'pages/temukan.dart';
import 'providers/person.dart';
import 'utils/constants.dart';
import 'utils/helpers.dart';
import 'utils/styles.dart' as style;
import 'utils/widgets.dart';

class Page {
  Page({@required this.title, @required this.icon, @required this.content});
  String title;
  IconData icon;
  Widget content;
}

class Home extends StatefulWidget {
  Home({Key key, @required this.analytics, @required this.observer}) : super(key: key);
  final FirebaseAnalytics analytics;
  final FirebaseAnalyticsObserver observer;

  @override
  _HomeState createState() => _HomeState(analytics, observer);
}

class _HomeState extends State<Home> {
  _HomeState(this.analytics, this.observer);
  final FirebaseAnalytics analytics;
  final FirebaseAnalyticsObserver observer;

  final _pageController = PreloadPageController();
  final _listPages = <Page>[
    Page(title: 'menu_home'.tr(), icon: LineIcons.home, content: Beranda()),
    Page(title: 'menu_browse'.tr(), icon: LineIcons.search, content: Temukan()), // favorit, featured ad, last viewed
  ];

  var _selectedIndex = 0;
  var _isWillExit = false;

  @override
  void initState() {
    super.initState();
  }
  
  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  _openPage(int index) {
    FocusScope.of(context).unfocus();
    setState(() { _selectedIndex = index; });
    if (_pageController.page.round() != index) {
      print("page move: ${_pageController.page.round()} -> $index");
      _pageController.animateToPage(index, duration: Duration(milliseconds: 500), curve: Curves.ease);
    }
  }

  _createAd() async {
    final results = await Navigator.of(context).pushNamed(ROUTE_PASANG, arguments: {'tipe': _selectedIndex}) as Map;
    print(" ... ROUTE PASANG result: $results");
    if (results != null && results.containsKey('isSubmit')) {

    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (screenScaffoldKey.currentState.isEndDrawerOpen) return true;
        if (_pageController.page.round() > 0) {
          _openPage(0);
          return false;
        }
        if (_isWillExit) return SystemChannels.platform.invokeMethod<bool>('SystemNavigator.pop');
        h.showToast('prompt_exit'.tr());
        _isWillExit = true;
        Future.delayed(Duration(milliseconds: 2000), () { _isWillExit = false; });
        return false;
      },
      child: Scaffold(
        key: screenScaffoldKey,
        resizeToAvoidBottomInset: true,
        drawerEdgeDragWidth: 20,
        endDrawer: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Container(
              width: MediaQuery.of(context).size.width * 0.69,
              decoration: BoxDecoration(
                boxShadow: [BoxShadow(color: Colors.black45, blurRadius: 25)],
                borderRadius: BorderRadius.only(topLeft: Radius.circular(20), bottomLeft: Radius.circular(20),),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.only(topLeft: Radius.circular(20), bottomLeft: Radius.circular(20),),
                child: Drawer(semanticLabel: "Menu panel", child: Column(children: <Widget>[
                  Material(
                    color: THEME_COLOR,
                    child: InkWell(
                      splashColor: Colors.white10,
                      highlightColor: Colors.white10,
                      onTap: a.openProfile,
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Row(children: <Widget>[
                          Selector<PersonProvider, String>(
                            selector: (buildContext, person) => person.foto,
                            builder: (context, foto, child) => UiAvatar(foto, size: 70,),
                          ),
                          SizedBox(width: 12,),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                            Selector<PersonProvider, String>(
                              selector: (buildContext, person) => person.namaDepan,
                              builder: (context, namaDepan, child) => Text("${'prompt_hello'.tr()}, ${namaDepan}!", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),),
                            ),
                            SizedBox(height: 2),
                            Selector<PersonProvider, String>(
                              selector: (buildContext, person) => person.email,
                              builder: (context, email, child) => Text(email, style: style.textWhite,),
                            ),
                          ],),)
                        ],),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(10),
                    child: MenuNavContent(),
                  ),
                ],),),
              ),
            ),
          ),
        ),
        body: PreloadPageView.builder(
          preloadPagesCount: 2,
          controller: _pageController,
          itemCount: _listPages.length,
          itemBuilder: (context, index) => _listPages[index].content,
          onPageChanged: _openPage,
        ),
        // floatingActionButton: AnimatedSwitcher(
        //   duration: Duration(milliseconds: 500),
        //   switchInCurve: Curves.easeInBack,
        //   switchOutCurve: Curves.easeOutBack,
        //   transitionBuilder: (Widget child, Animation<double> animation) => ScaleTransition(child: child, scale: animation,),
        //   child: _selectedIndex > 1 ? SizedBox() : FloatingActionButton(
        //     onPressed: _createAd,
        //     backgroundColor: Colors.teal[400],
        //     tooltip: 'menu_create'.tr(),
        //     child: Icon(LineIcons.plus),
        //   ).pulseIt(pulse: false),
        // ),
        bottomNavigationBar: Stack(
          alignment: Alignment.bottomCenter,
          children: <Widget>[
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(blurRadius: 20, color: Colors.grey[800].withOpacity(0.5))]
              ),
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: GNav(
                gap: 8,
                iconSize: 24,
                activeColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 18, vertical: 5),
                duration: Duration(milliseconds: 500),
                tabBackgroundColor: Theme.of(context).accentColor,
                tabs: _listPages.map((page) => GButton(icon: page.icon, text: page.title)).toList(),
                selectedIndex: _selectedIndex,
                onTabChange: (index) => _openPage(index),
              ),
            ),
            Transform.translate(
              offset: Offset(0, -18),
              child: Transform.scale(
                scale: 1.4,
                child: Container(
                  decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white60),
                  child: FloatingActionButton(
                    mini: true,
                    elevation: 0,
                    onPressed: _createAd,
                    backgroundColor: Colors.teal[400],
                    tooltip: 'menu_create'.tr(),
                    child: Icon(LineIcons.plus),
                  ),
                ),
              )
            ),
          ],
        ),
      ),
    );
  }
}