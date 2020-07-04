import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_analytics/observer.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:laku/models/basic.dart';
import 'package:line_icons/line_icons.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:preload_page_view/preload_page_view.dart';
import 'package:provider/provider.dart';
import 'package:vibration/vibration.dart';
import 'components/menu.dart';
import 'pages/beranda.dart';
import 'pages/temukan.dart';
import 'pages/profil.dart';
import 'providers/person.dart';
import 'utils/constants.dart';
import 'utils/curves.dart';
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

  final _listActions = <IconLabel>[
    IconLabel(MdiIcons.filePlus, "Buat Iklan", value: 'WTS', color: Colors.blue),
    IconLabel(MdiIcons.bullhorn, "Broadcast", value: 'WTB', color: Colors.yellow),
  ];


  var _selectedIndex = 0;
  var _isWillExit = false;
  var _isPopNotif = false;

  _action(String action) async {
    print("TAP ACTION: $action");
    final results = await Navigator.of(context).pushNamed(ROUTE_PASANG, arguments: {'tipe': action}) as Map;
    print(" ... ROUTE PASANG result: $results");
  }

  _openPage(int index) {
    FocusScope.of(context).unfocus();
    setState(() { _selectedIndex = index; });
    if (screenPageController.page.round() != index) {
      print("page move: ${screenPageController.page.round()} -> $index");
      screenPageController.animateToPage(index, duration: Duration(milliseconds: 500), curve: Curves.ease);
    }
  }

  // _action(String action) async {
  //   switch (action) {
  //   case "shop":
  //     a.openMyShop();
  //     break;
  //   default:
  //     final results = await Navigator.of(context).pushNamed(ROUTE_PASANG, arguments: {'tipe': action ?? 'WTS'}) as Map;
  //     print(" ... ROUTE PASANG result: $results");
  //   }
  // }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Vibration.vibrate(duration: 200, amplitude: 1);
    });
  }

  @override
  Widget build(BuildContext context) {

    final _listPages = <Page>[
      Page(title: 'menu_home'.tr(), icon: LineIcons.home, content: Beranda(isOpen: _selectedIndex == 0,),),
      Page(title: 'menu_browse'.tr(), icon: LineIcons.search, content: Temukan(isOpen: _selectedIndex == 1,),), // favorit, featured ad, last viewed
      Page(title: 'menu_user'.tr(), icon: LineIcons.user, content: Profil(isOpen: _selectedIndex == 2,),),
    ];

    // final _listActions = <IconLabel>[
    //   IconLabel(MdiIcons.bullhornOutline, "Pasang", value: "WTS"),
    //   IconLabel(MdiIcons.magnify, "Cari", value: "WTB"),
    //   IconLabel(MdiIcons.storefrontOutline, "Kelola", value: "shop"),
    // ];

    return WillPopScope(
      onWillPop: () async {
        if (screenScaffoldKey.currentState.isEndDrawerOpen) return true;
        if (screenPageController.page.round() > 0) {
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
          controller: screenPageController,
          itemCount: _listPages.length,
          itemBuilder: (context, index) => _listPages[index].content,
          onPageChanged: _openPage,
        ),
        floatingActionButton: AnimatedSwitcher(
          duration: Duration(milliseconds: 1000),
          switchInCurve: Curves.easeOutBack,
          switchOutCurve: Curves.linear,
          // transitionBuilder: (Widget child, Animation<double> animation) => ScaleTransition(child: child, scale: animation,),
          transitionBuilder: (Widget child, Animation<double> animation) {
            final  offsetAnimation = Tween<Offset>(begin: Offset(1, 0), end: Offset(0, 0)).animate(animation);
            return SlideTransition(
              position: offsetAnimation,
              child: child,
            );
          },
          // child: _selectedIndex > 0 ? SizedBox() : FloatingActionButton(
          //   child: Padding(
          //     padding: EdgeInsets.all(8.0),
          //     child: Icon(MdiIcons.telescope, size: 32,),
          //   ),
          //   backgroundColor: THEME_COLOR_LIGHT,
          //   onPressed: a.openMap
          // ),
          child: _selectedIndex > 0 ? SizedBox() : UiFabCircular(
            LineIcons.plus,
            _listActions,
            _action,
            getOffset: (i) {
              double x = 0.0, y = 0.0;
              if (i == 1) {
                x = -25;
                y = 8;
              }
              return Offset(x, y);
            },
            getSize: (i) => 48.0 - 6 * i,
          ),
        ),
        bottomNavigationBar: Stack(
          alignment: Alignment.topCenter,
          children: <Widget>[
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(blurRadius: 20, color: Colors.grey[800].withOpacity(0.5))]
              ),
              padding: EdgeInsets.all(8.0),
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
              offset: Offset(35, -45),
              child: AnimatedOpacity(
                opacity: _isPopNotif ? 1 : 0,
                duration: Duration(milliseconds: 1000),
                child: UiTooltip(label: "2 Baru",),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class UiTooltip extends StatelessWidget {
  UiTooltip({Key key, this.label, this.color = Colors.red}) : super(key: key);
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: ShapeDecoration(
        color: color,
        shape: TooltipShapeBorder(arrowArc: 0.5),
        shadows: [BoxShadow(color: Colors.black26, blurRadius: 4.0, offset: Offset(2, 2))],
      ),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Text(label, style: TextStyle(color: Colors.white)),
      ),
    );
  }
}