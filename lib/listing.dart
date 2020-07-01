import 'dart:math';

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_pro/carousel_pro.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'extensions/widget.dart';
import 'models/iklan.dart';
import 'utils/constants.dart';
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
                          images: _item.foto.map((pic) {
                            return NetworkImage(pic.foto);
                          }).toList(),
                        )
                      ),),
                      // Positioned.fill(child: CachedNetworkImage(
                      //   imageUrl: Uri.encodeFull('https://img.freepik.com/free-vector/abstract-colorful-flow-shapes-background_23-2148258092.jpg?size=626&ext=jpg'),
                      //   placeholder: (context, url) => Container(child: Center(child: SizedBox(width: 100, height: 100, child: Padding(padding: EdgeInsets.all(50), child: CircularProgressIndicator())))),
                      //   errorWidget: (context, url, error) => Container(child: Center(child: SizedBox(width: 100, height: 100, child: Icon(Icons.error, color: Colors.grey,)))),
                      //   fit: BoxFit.cover,
                      // ),),
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