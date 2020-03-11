import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:line_icons/line_icons.dart';
import 'package:preload_page_view/preload_page_view.dart';
import 'package:provider/provider.dart';
import 'pages/akun.dart';
import 'pages/beranda.dart';
import 'pages/favorit.dart';
import 'pages/temukan.dart';
import 'providers/settings.dart';
import 'services/firestore_service.dart';
import 'utils/helpers.dart';
import 'tambah.dart';

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
  int _selectedIndex = 0;
  PreloadPageController _pageController;
  final _firestore = FirestoreService();
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
    final _settings = Provider.of<SettingsProvider>(context);
    return Scaffold(
      resizeToAvoidBottomInset: true,
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
            // print(results);
            _firestore.addReport({
              'iklanTerpasang': 8,
              'pesanMasuk': 2,
              'iklan': 29,
              'pengguna': 8,
              'pencari': 1,
            });
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
    );
  }
}