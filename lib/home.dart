import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:line_icons/line_icons.dart';
import 'package:preload_page_view/preload_page_view.dart';
import 'package:provider/provider.dart';
import 'components/menu.dart';
import 'pages/akun.dart';
import 'pages/beranda.dart';
import 'pages/favorit.dart';
import 'pages/temukan.dart';
import 'providers/person.dart';
import 'utils/constants.dart';
import 'utils/helpers.dart';
import 'utils/widgets.dart';

class Page {
  Page({@required this.title, @required this.icon, @required this.content});
  String title;
  IconData icon;
  Widget content;
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  var _selectedIndex = 0;
  var _isWillExit = false;
  PreloadPageController _pageController;
  final _pages = <Page>[
    Page(title: 'Beranda', icon: LineIcons.home, content: Beranda()),
    Page(title: 'Temukan', icon: LineIcons.search, content: Temukan()),
    Page(title: 'Favorit', icon: LineIcons.heart_o, content: Favorit()),
    Page(title: 'Akun', icon: LineIcons.user, content: Akun()),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PreloadPageController();
  }
  
  @override
  void dispose() {
    _pageController.dispose();
    timer.cancel();
    super.dispose();
  }

  _openPage(int index) {
    setState(() {
      _selectedIndex = index;
    });
    if (_pageController.page.round() != index) {
      print("page move: ${_pageController.page.round()} -> $index");
      _pageController.animateToPage(index, duration: Duration(milliseconds: 500), curve: Curves.ease);
    }
  }

  @override
  Widget build(BuildContext context) {
    initializeHelpers(context, "after init _HomeState");
    return WillPopScope(
      onWillPop: () async {
        if (screenScaffoldKey.currentState.isEndDrawerOpen) return true;
        // TODO pake provider.value
        if (!Provider.of<PersonProvider>(context, listen: false).isSignedIn) return true;
        if (_isWillExit) return SystemChannels.platform.invokeMethod<bool>('SystemNavigator.pop');
        h.showToast("Ketuk sekali lagi untuk menutup aplikasi.");
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
              child: ClipRRect(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                ),
                child: SizedBox(
                  width: h.screenSize.width * 0.69,
                  child: Drawer(semanticLabel: "Menu samping", child: Column(children: <Widget>[
                    Container(
                      color: THEME_COLOR,
                      width: double.infinity,
                      padding: EdgeInsets.all(20),
                      child: Row(children: <Widget>[
                        Selector<PersonProvider, String>(
                          selector: (buildContext, person) => person.foto,
                          builder: (context, foto, child) {
                            var fotoDefault = Image.asset("images/anon.png", width: 100, height: 100, fit: BoxFit.cover);
                            return UiAvatar(
                              strokeWidth: 3,
                              image: foto == null ? fotoDefault : CachedNetworkImage(
                                imageUrl: Uri.encodeFull(foto),
                                placeholder: (context, url) => SizedBox(width: 100, height: 100, child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator())),
                                errorWidget: (context, url, error) => fotoDefault,
                                width: 69, height: 69,
                                fit: BoxFit.cover,
                              ),
                              // onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => Profil())),
                              onPressed: () => Navigator.of(context).pushNamed(ROUTE_PROFIL),
                            );
                          },
                        ),
                        SizedBox(width: 12,),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                          Selector<PersonProvider, String>(
                            selector: (buildContext, person) => person.namaDepan,
                            builder: (context, namaDepan, child) => Text("Halo, ${namaDepan}!", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),),
                          ),
                        ],),)
                      ],),
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
          itemCount: _pages.length,
          itemBuilder: (context, index) => _pages[index].content,
          onPageChanged: (index) {
            _openPage(index);
          },
        ),
        floatingActionButton: AnimatedSwitcher(
          duration: Duration(milliseconds: 500),
          switchInCurve: Curves.easeInBack,
          switchOutCurve: Curves.easeOutBack,
          transitionBuilder: (Widget child, Animation<double> animation) => ScaleTransition(child: child, scale: animation,),
          child: _selectedIndex > 0 ? SizedBox() : FloatingActionButton(
            onPressed: () async {
              // Map results = await Navigator.of(context).push(MaterialPageRoute(builder: (_) => Tambah()));
              final results = await Navigator.of(context).pushNamed(ROUTE_TAMBAH);
              print(results);
            },
            tooltip: 'Tambah Barang',
            child: Icon(LineIcons.plus),
          ),
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(color: Colors.white, boxShadow: [
            BoxShadow(blurRadius: 20, color: Colors.grey[800].withOpacity(0.5))
          ]),
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: GNav(
                gap: 8,
                iconSize: 24,
                activeColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 18, vertical: 5),
                duration: Duration(milliseconds: 500),
                tabBackgroundColor: Theme.of(context).accentColor,
                tabs: _pages.map((page) => GButton(icon: page.icon, text: page.title)).toList(),
                selectedIndex: _selectedIndex,
                onTabChange: (index) {
                  _openPage(index);
                }
              ),
            ),
          ),
        ),
      ),
    );
  }
}