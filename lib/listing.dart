import 'dart:math';

import 'package:fab_circular_menu/fab_circular_menu.dart';
import 'package:flutter/material.dart';
// import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_pro/carousel_pro.dart';
import 'package:line_icons/line_icons.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'extensions/widget.dart';
import 'models/basic.dart';
import 'models/iklan.dart';
import 'utils/constants.dart';
import 'utils/helpers.dart';
import 'utils/styles.dart' as style;

class Listing extends StatefulWidget {
  Listing(this.args, {Key key}) : super(key: key);
  final Map args;

  @override
  _ListingState createState() => _ListingState();
}

class _ListingState extends State<Listing> with TickerProviderStateMixin {
  var _tabs = <String>['Detail', 'Lokasi', 'Pelapak'];
  ScrollController _scrollController;
  TabController _tabController;

  final _listActions = <IconLabel>[
    IconLabel(MdiIcons.phone, "Telepon"),
    IconLabel(MdiIcons.handshake, "COD"),
    IconLabel(MdiIcons.message, "Chat"),
  ];

  bool get isShrink => _scrollController.hasClients && _scrollController.offset > (200 - kToolbarHeight);
  // Color _titleColor = HSLColor.fromAHSL(1, 1, 1, 0).toColor();
  double _titleOpacity = 0.0;

  _scrollListener() {
    if ((_scrollController.offset % 10).floor() > 0) return;
    if (!isShrink) {
      setState(() {
        var opacity = min(1, _scrollController.offset / (200 - kToolbarHeight));
        // _titleColor = HSLColor.fromAHSL(1, 1, 1, opacity).toColor();
        _titleOpacity = opacity;
      });
    }
  }

  _action(String action) {
    // TODO chat, telepon
  }

  @override
  void initState() {
    _tabController = TabController(vsync: this, length: _tabs.length, initialIndex: 0);
    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final IklanModel _item = widget.args['item'];
    return Scaffold(
      body: SafeArea(
        child: DefaultTabController(
          length: _tabs.length,
          child: NestedScrollView(
            controller: _scrollController,
            headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
              return <Widget>[
                SliverAppBar(
                  iconTheme: IconThemeData(color: Colors.white),
                  leading: IconButton(
                    icon: Icon(MdiIcons.chevronLeft, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  backgroundColor: THEME_COLOR,
                  expandedHeight: 200.0,
                  floating: true,
                  pinned: false,
                  flexibleSpace: FlexibleSpaceBar(
                    centerTitle: false,
                    title: Text(_item.judul, overflow: TextOverflow.ellipsis, style: style.textTitleWhite).withOpacity(_titleOpacity),
                    background: Stack(children: <Widget>[
                      Positioned.fill(child: SizedBox(
                        height: 150.0,
                        width: MediaQuery.of(context).size.width,
                        child: Carousel(
                          images: _item.foto.map((pic) => GestureDetector(
                            onTap: () => h.viewImage(_item.foto, page: _item.foto.indexOf(pic)),
                            child: FadeInImage.assetNetwork(
                              placeholder: IMAGE_DEFAULT_NONE,
                              image: pic.foto,
                              fit: BoxFit.cover,
                            ),
                          ),).toList(),
                          dotSize: 8.0,
                          dotSpacing: 20.0,
                          dotBgColor: Colors.transparent,
                        )
                      ),),
                      Positioned.fill(child: IgnorePointer(child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          gradient: LinearGradient(
                            begin: FractionalOffset.bottomCenter,
                            end: FractionalOffset.topCenter,
                            colors: [
                              Colors.white.withOpacity(1.0),
                              Colors.white.withOpacity(0.0),
                            ],
                            stops: [
                              0.0,
                              0.65,
                            ]
                          ),
                        ),
                      ),),),
                    ],),
                  ),
                ),
                SliverPersistentHeader(
                  delegate: _SliverAppBarDelegate(
                    TabBar(
                      indicatorWeight: 2,
                      indicatorColor: THEME_COLOR,
                      controller: _tabController,
                      labelColor: Colors.black87,
                      unselectedLabelColor: Colors.grey,
                      tabs: _tabs.map((label) => Tab(text: label)).toList(),
                    ),
                  ),
                  pinned: true,
                ),
              ];
            },
            body: Container(
              child: TabBarView(
                controller: _tabController,
                children: <Widget>[
                  // tab 1: detail iklan
                  SingleChildScrollView(padding: EdgeInsets.all(THEME_PADDING), child: Column(children: <Widget>[
                    Text(_item.judul, style: style.textHeadline),
                    SizedBox(height: 8,),
                    Row(children: <Widget>[
                      Text("Kategori:"),
                      SizedBox(width: 4,),
                      Expanded(child: Text(_item.kategori, style: style.textLabel,),),
                    ],),
                    SizedBox(height: 16,),
                    Text(_item.deskripsi, style: style.textMuted),
                  ])),
                  // tab 2: peta
                  SingleChildScrollView(padding: EdgeInsets.all(THEME_PADDING), child: Column(children: <Widget>[

                  ])),
                  // tab 3: profil lapak
                  SingleChildScrollView(padding: EdgeInsets.all(THEME_PADDING), child: Column(children: <Widget>[

                  ])),
                ]
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FabCircularMenu(
        fabOpenIcon: Icon(MdiIcons.message, color: Colors.white,),
        fabCloseIcon: Icon(LineIcons.close, color: Colors.white,),
        fabOpenColor: Colors.red[400],
        fabCloseColor: Colors.teal[400],
        ringColor: Colors.white.withOpacity(.9),
        ringWidth: 100,
        ringDiameter: 300,
        children: _listActions.asMap().map((i, action) {
          return MapEntry(i, Material(
            shape: CircleBorder(),
            color: Colors.teal.withOpacity(.3),
            clipBehavior: Clip.antiAlias,
            child: IconButton(
              padding: EdgeInsets.all(20),
              icon: Icon(action.icon),
              iconSize: 32.0 - 4 * i,
              color: THEME_COLOR,
              tooltip: action.label,
              onPressed: () {
                _action(action.value);
              }
            ),
          ));
        }).values.toList(),
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);
  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Material(
      elevation: 5,
      color: Colors.white,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}