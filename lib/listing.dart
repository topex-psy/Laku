import 'dart:math';

import 'package:fab_circular_menu/fab_circular_menu.dart';
import 'package:flutter/material.dart';
// import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_pro/carousel_pro.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:laku/utils/widgets.dart';
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
  var _tabs = <String>['Detail', 'Ulasan', 'Pelapak'];
  ScrollController _scrollController;
  TabController _tabController;

  final _scaffoldKey = GlobalKey<ScaffoldState>();
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

  _favorit() async {
    final IklanModel _item = widget.args['item'];
    if (await a.favListing(_item.id, _item.isFavorit ? 'del' : 'add')) {
      if (_item.isFavorit) {
        h.showFlashBar("Favorit Dihapus!", "Iklan ini berhasil dihapus dari daftar favorit!", actionLabel: "Undo", action: _favorit);
      } else {
        h.showFlashbarSuccess("Favorit Ditambahkan!", "Iklan ini berhasil ditambahkan ke daftar favorit!");
      }
      setState(() {
        _item.toggleFav();
      });
      a.loadNotif();
    }
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
      key: _scaffoldKey,
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
                          autoplay: true,
                          autoplayDuration: Duration(milliseconds: 8000),
                          animationDuration: Duration(milliseconds: 800),
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
                      tabs: _tabs.map((tab) => Tab(text: tab)).toList(),
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
                  SingleChildScrollView(padding: EdgeInsets.all(20), child: Column(children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(child: Text(_item.judul, style: style.textHeadline)),
                        SizedBox(width: 8,),
                        _item.layananAntar == null ? SizedBox() : Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Icon(LineIcons.truck, color: Colors.teal),
                            SizedBox(height: 2,),
                            Text(_item.layananAntar, textAlign: TextAlign.center, style: style.textS,)
                          ],
                        ),
                        Padding(
                          padding: EdgeInsets.only(bottom: 16.0),
                          child: IconButton(icon: Icon(_item.isFavorit ? LineIcons.heart : LineIcons.heart_o), color: Colors.pink, onPressed: _favorit,),
                        )
                      ],
                    ),
                    SizedBox(height: 16,),
                    Row(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                      Expanded(
                        child: Column(
                          children: <Widget>[
                            Row(
                              children: <Widget>[
                                Text("Kategori:"),
                                SizedBox(width: 4,),
                                Expanded(child: Text(_item.kategori, style: style.textLabel,)),
                              ],
                            ),
                            _item.kondisi == null ? SizedBox() : Padding(
                              padding: EdgeInsets.only(top: 2.0),
                              child: Row(
                                children: <Widget>[
                                  Text("Kondisi:"),
                                  SizedBox(width: 4,),
                                  Expanded(child: Text(_item.kondisi.tr(), style: style.textLabel,)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      _item.harga == 0 ? Container() : Padding(
                        padding: EdgeInsets.only(left: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Container(
                              padding: EdgeInsets.symmetric(vertical: 2, horizontal: 8),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(f.formatPrice(_item.harga), style: style.textWhiteB),
                            ),
                            _item.isNego ? Padding(
                              padding: EdgeInsets.only(top: 4),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  Text("Bisa nego"),
                                  SizedBox(width: 2,),
                                  Icon(LineIcons.check_circle, size: 20, color: Colors.green,)
                                ],
                              ),
                            ) : SizedBox()
                          ],
                        ),
                      ),
                    ],),
                    SizedBox(height: 16,),
                    Text(_item.deskripsi),
                  ])),
                  // tab 2: ulasan
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
          return MapEntry(i, Stack(
            alignment: Alignment.bottomCenter,
            children: <Widget>[
              Material(
                shape: CircleBorder(),
                color: Colors.teal.withOpacity(.3),
                clipBehavior: Clip.antiAlias,
                child: IconButton(
                  padding: EdgeInsets.only(left: 20, right: 20, bottom: 28, top: 12),
                  icon: Icon(action.icon),
                  iconSize: 32.0 - 4 * i,
                  color: THEME_COLOR,
                  tooltip: action.label,
                  onPressed: () {
                    _action(action.value);
                  }
                ),
              ),
              Padding(
                padding: EdgeInsets.only(bottom: 12.0),
                child: Text(action.label, textAlign: TextAlign.center, style: TextStyle(color: Colors.teal, fontSize: 12),),
              )
            ],
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