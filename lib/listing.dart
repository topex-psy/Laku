import 'dart:math';

import 'package:flutter/material.dart';
import 'package:carousel_pro/carousel_pro.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:expandable/expandable.dart';
import 'package:line_icons/line_icons.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'extensions/widget.dart';
import 'models/basic.dart';
import 'models/iklan.dart';
import 'utils/api.dart';
import 'utils/constants.dart';
import 'utils/helpers.dart';
import 'utils/styles.dart' as style;
import 'utils/widgets.dart';

const MAX_DESCRIPTION_LENGTH = 150;

class Listing extends StatefulWidget {
  Listing(this.args, {Key key}) : super(key: key);
  final Map args;

  @override
  _ListingState createState() => _ListingState();
}

class _ListingState extends State<Listing> with TickerProviderStateMixin {
  ScrollController _scrollController;
  IklanModel _item;

  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _listActions = <IconLabel>[
    IconLabel(MdiIcons.fileEditOutline, "Edit", value: 'edit', color: Colors.blue),
    IconLabel(MdiIcons.close, "Set Kosong", value: 'kosong', color: Colors.yellow),
    IconLabel(MdiIcons.deleteOutline, "Hapus", value: 'hapus', color: Colors.red),
  ];
  final _refreshController = RefreshController(initialRefresh: false);

  bool get isShrink => _scrollController.hasClients && _scrollController.offset > (200 - kToolbarHeight);
  // Color _titleColor = HSLColor.fromAHSL(1, 1, 1, 0).toColor();
  var _titleOpacity = 0.0;

  _updateData() async {
    var listingApi = await api('listing', data: { 'uid': userSession.uid, 'id': _item.id });
    if (listingApi.isSuccess) {
      _refreshController.refreshCompleted();
      setState(() {
        _item = IklanModel.fromJson(listingApi.result.first);
      });
    } else {
      _refreshController.refreshFailed();
    }
  }

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

  _action(String action) async {
    print("TAP ACTION: $action");
    switch (action) {
      case 'favorit':
        if (await a.favListing(_item.id, _item.isFavorit ? 'del' : 'add')) {
          if (_item.isFavorit) {
            h.showFlashBar("Favorit Dihapus!", "Iklan ini berhasil dihapus dari daftar favorit!", actionLabel: "Undo", action: () => _action('favorit'));
          } else {
            h.showFlashbarSuccess("Favorit Ditambahkan!", "Iklan ini berhasil ditambahkan ke daftar favorit!");
          }
          setState(() {
            _item.toggleFav();
          });
          a.loadNotif();
        }
        break;
      case 'edit':
        final pasang = await a.openListingForm(edit: _item) as Map;
        if (pasang != null && pasang.containsKey('isSubmit')) {
          _updateData();
        }
        break;
      case 'edit_shop':
        break;
      case 'open_shop':
        break;
      case 'hapus':
        if (await h.showConfirm("Hapus Iklan", "Apakah Anda yakin ingin menghapus iklan ini?") ?? false) {

        }
        break;
      case 'kosong':
        if (await h.showConfirm("Set Kosong", "Apakah Anda yakin stok produk ini telah habis?") ?? false) {

        }
        break;
      case 'chat':
        break;
      case 'telepon':
        // _item.telepon
        break;
      case 'report':
        break;
    }
  }

  @override
  void initState() {
    _item = widget.args['item'];
    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _refreshController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      body: SafeArea(
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
                expandedHeight: 300.0,
                floating: true,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: false,
                  title: Text(_item.judul, overflow: TextOverflow.ellipsis, style: style.textTitleWhite).withOpacity(_titleOpacity),
                  background: SizedBox(
                    height: 300.0,
                    width: MediaQuery.of(context).size.width,
                    child: Stack(
                      children: <Widget>[
                        Positioned.fill(
                          child: Carousel(
                            images: _item.foto.map((pic) {
                              var index = _item.foto.indexOf(pic);
                              var tag = "listing_${_item.id}";
                              return GestureDetector(
                                onTap: () => h.viewImage(_item.foto, page: index, heroTag: tag),
                                child: Hero(
                                  tag: "${tag}_$index",
                                  child: FadeInImage.assetNetwork(
                                    placeholder: IMAGE_DEFAULT_NONE,
                                    image: pic.foto,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              );
                            }).toList(),
                            autoplay: true,
                            autoplayDuration: Duration(milliseconds: 8000),
                            animationDuration: Duration(milliseconds: 800),
                            showIndicator: _item.foto.length > 1,
                            dotSize: 5.0,
                            dotSpacing: 16.0,
                            dotBgColor: Colors.white,
                            dotColor: THEME_COLOR,
                            dotIncreasedColor: THEME_COLOR_LIGHT
                          ),
                        ),
                        Align(
                          alignment: Alignment.bottomRight,
                          child: Padding(
                            padding: EdgeInsets.all(THEME_PADDING),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Text("${f.formatNumber(_item.jumlahKlik)}x", style: style.textMutedM),
                                SizedBox(width: 4,),
                                Icon(MdiIcons.eyeOutline, color: THEME_COLOR, size: 18,),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  ),
                ),
              ),
            ];
          },
          body: Container(
            child: SmartRefresher(
              enablePullDown: true,
              enablePullUp: false,
              header: WaterDropMaterialHeader(color: THEME_COLOR, backgroundColor: Colors.white),
              controller: _refreshController,
              onRefresh: _updateData,
              child: SingleChildScrollView(child: Column(children: <Widget>[
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.only(left: 20, top: 20, bottom: 20),
                  color: Colors.white,
                  child: Column(
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(child: Text(_item.judul, style: style.textHeadline)),
                          SizedBox(width: 8,),
                          _item.layananAntar == null ? SizedBox() : Container(
                            width: 40,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Icon(LineIcons.truck, color: Colors.teal),
                                SizedBox(height: 2,),
                                Text(_item.layananAntar, textAlign: TextAlign.center, style: style.textS,)
                              ],
                            ),
                          ),
                          // Container(
                          //   width: 40,
                          //   child: Column(
                          //     crossAxisAlignment: CrossAxisAlignment.center,
                          //     mainAxisSize: MainAxisSize.min,
                          //     children: <Widget>[
                          //       Icon(LineIcons.map_marker, color: Colors.grey),
                          //       SizedBox(height: 2,),
                          //       Text(f.distanceLabel(_item.jarakMeter), textAlign: TextAlign.center, style: style.textS,)
                          //     ],
                          //   ),
                          // ),
                          Container(
                            width: 40,
                            child: Stack(
                              alignment: Alignment.topCenter,
                              children: <Widget>[
                                Transform.translate(
                                  offset: Offset(0, -8.5),
                                  child: Material(
                                    color: Colors.transparent,
                                    shape: CircleBorder(),
                                    clipBehavior: Clip.antiAlias,
                                    child: IconButton(icon: Icon(_item.isFavorit ? LineIcons.heart : LineIcons.heart_o), color: Colors.pink, onPressed: () => _action('favorit'),)
                                  ),
                                ),
                                Transform.translate(
                                  offset: Offset(0, 29.5),
                                  child: Text(f.formatNumber(_item.jumlahFavorit), textAlign: TextAlign.center, style: style.textS,),
                                )
                              ],
                            ),
                          ),
                          SizedBox(width: 12,)
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
                                    Text(_item.kondisi.tr(), style: style.textLabel,),
                                    SizedBox(width: 4,),
                                    _item.kondisi == 'used' ? Icon(MdiIcons.alertCircle, color: Colors.grey, size: 18,) : SizedBox()
                                  ],
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.only(top: 2.0),
                                child: Row(
                                  children: <Widget>[
                                    Text("Stok:"),
                                    SizedBox(width: 4,),
                                    Expanded(child: Text("Tersedia", style: style.textLabel,)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 20,),
                        Expanded(flex: 0, child: _item.harga == 0 ? SizedBox() : Padding(
                          padding: EdgeInsets.only(left: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Container(
                                padding: EdgeInsets.only(right: 20),
                                decoration: BoxDecoration(
                                  color: Colors.redAccent[400],
                                ),
                                child: Row(
                                  children: <Widget>[
                                    Transform.translate(
                                      offset: Offset(-3, 0),
                                      child: Transform.rotate(
                                        angle: 90 * pi / 180,
                                        child: Icon(MdiIcons.triangle, color: Colors.white, size: 28,),
                                      ),
                                    ),
                                    SizedBox(width: 6,),
                                    Text(f.formatPrice2(_item.harga, singkat: true), style: style.textTitleWhite),
                                  ],
                                ),
                              ),
                              _item.isNego ? Padding(
                                padding: EdgeInsets.only(top: 8, right: 20),
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
                        ),)
                      ],),
                    ],
                  ),
                ),
                SizedBox(height: 12,),

                UiSection(title: "Detail Produk", titleSpacing: 16, children: <Widget>[
                  ExpandableNotifier(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expandable(
                          collapsed: Text(_item.deskripsi, softWrap: true, maxLines: 5, overflow: TextOverflow.ellipsis,),
                          expanded: Text(_item.deskripsi, softWrap: true,),
                        ),
                        Builder(
                          builder: (context) {
                            var _expandController = ExpandableController.of(context);
                            return FlatButton(
                              padding: EdgeInsets.zero,
                              highlightColor: Colors.transparent,
                              splashColor: Colors.transparent,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  Text(
                                    _expandController.expanded ? "Lebih Ringkas" : "Selengkapnya",
                                    style: TextStyle(color: THEME_COLOR),
                                  ),
                                  SizedBox(width: 4,),
                                  Icon(_expandController.expanded ? MdiIcons.chevronUp : MdiIcons.chevronDown, color: THEME_COLOR)
                                ],
                              ),
                              onPressed: _expandController.toggle,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],),

                // Container(
                //   width: double.infinity,
                //   color: Colors.white,
                //   padding: EdgeInsets.all(20),
                //   child: ExpandableNotifier(
                //     child: Column(
                //       crossAxisAlignment: CrossAxisAlignment.start,
                //       children: <Widget>[
                //         Text("Detail Produk", style: style.textTitle,),
                //         SizedBox(height: 16,),
                //         Expandable(
                //           collapsed: Text(_item.deskripsi, softWrap: true, maxLines: 5, overflow: TextOverflow.ellipsis,),
                //           expanded: Text(_item.deskripsi, softWrap: true,),
                //         ),
                //         Builder(
                //           builder: (context) {
                //             var _expandController = ExpandableController.of(context);
                //             return FlatButton(
                //               padding: EdgeInsets.zero,
                //               highlightColor: Colors.transparent,
                //               splashColor: Colors.transparent,
                //               child: Row(
                //                 mainAxisSize: MainAxisSize.min,
                //                 children: <Widget>[
                //                   Text(
                //                     _expandController.expanded ? "Lebih Ringkas" : "Selengkapnya",
                //                     style: TextStyle(color: THEME_COLOR),
                //                   ),
                //                   SizedBox(width: 4,),
                //                   Icon(_expandController.expanded ? MdiIcons.chevronUp : MdiIcons.chevronDown, color: THEME_COLOR)
                //                 ],
                //               ),
                //               onPressed: () {
                //                 _expandController.toggle();
                //               },
                //             );
                //           },
                //         ),
                //       ],
                //     ),
                //   ),
                // ),
                // SizedBox(height: 12,),
                Container(
                  width: double.infinity,
                  color: Colors.white,
                  padding: EdgeInsets.only(left: 20, top: 20, bottom: 20, right: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      FlatButton(
                        padding: EdgeInsets.zero,
                        splashColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                        onPressed: () => _action('open_shop'),
                        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                          UiAvatar(_item.fotoLapak, size: 48, strokeWidth: 0),
                          SizedBox(width: 12),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                            Text(_item.judulLapak, style: style.textB,),
                            SizedBox(height: 4,),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: <Widget>[
                                Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
                                  Icon(LineIcons.heart_o, size: 20, color: Colors.pink,),
                                  SizedBox(width: 6,),
                                  Text("${f.formatNumber(_item.jumlahFavoritLapak)} favorit"),
                                ],),
                                Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
                                  Icon(LineIcons.files_o, size: 20, color: Colors.grey,),
                                  SizedBox(width: 6,),
                                  Text("${f.formatNumber(_item.jumlahIklan)} iklan"),
                                ],),
                              ],
                            ),
                            SizedBox(height: 4),
                            Row(
                              children: <Widget>[
                                Icon(MdiIcons.circleMedium, size: 20, color: Colors.grey,),
                                SizedBox(width: 6,),
                                Expanded(child: Text(f.formatTimeago(_item.pengiklanLastActive), style: style.textS)),
                              ],
                            )
                          ],),),
                          SizedBox(width: 8),
                          _item.isMine
                          ? IconButton(
                            padding: EdgeInsets.zero,
                            icon: Icon(MdiIcons.pencil),
                            color: Colors.grey,
                            tooltip: "Edit",
                            onPressed: () => _action('edit_shop'),
                          )
                          : Container(
                            width: 40,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Icon(LineIcons.map_marker, color: Colors.grey),
                                SizedBox(height: 2,),
                                Text(f.distanceLabel(_item.jarakMeter), textAlign: TextAlign.center, style: style.textS,)
                              ],
                            ),
                          ),
                        ],),
                      ),
                      SizedBox(height: 12,),
                      _item.isMine ? Container(
                        padding: EdgeInsets.only(left: 60),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                            // Text("Peminat dapat menghubungi di:"),
                            // SizedBox(height: 8),
                            Row(
                              children: <Widget>[
                                Icon(LineIcons.mobile_phone, size: 20, color: Colors.grey,),
                                SizedBox(width: 6,),
                                Text("Telepon:"),
                                SizedBox(width: 6,),
                                Expanded(child: Text("$APP_COUNTRY_CODE${_item.telepon}", style: style.textCaption,),),
                              ],
                            )
                          ],),
                        ) : Row(children: <Widget>[
                        SizedBox(width: 60,),
                        Expanded(child: UiButton("Telepon", height: style.heightButtonL, color: Colors.green, icon: LineIcons.phone, textStyle: style.textButton, onPressed: () => _action('telepon'),)),
                        SizedBox(width: 8,),
                        Expanded(child: UiButton("Chat", height: style.heightButtonL, color: Colors.blue, icon: LineIcons.comment, textStyle: style.textButton, onPressed: () => _action('chat'),)),
                        SizedBox(width: 8,),
                      ],)
                    ],
                  ),
                ),
                SizedBox(height: 20,),
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                  SizedBox(width: 20,),
                  Expanded(child: Text("$APP_NAME hanya menampilkan informasi apa adanya sesuai data dari pengiklan. Harap selalu berhati-hati ketika bertransaksi.", style: style.textMutedS)),
                  Container(width: 80, child: _item.isMine ? SizedBox() : FlatButton(
                    padding: EdgeInsets.symmetric(vertical: 4, horizontal: 0),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(8),
                      bottomLeft: Radius.circular(8),
                    )),
                    onPressed: () => _action('report'),
                    child: Column(children: <Widget>[
                      Icon(MdiIcons.commentAlertOutline, color: Colors.grey, size: 20,),
                      SizedBox(height: 4,),
                      Text("Laporkan", maxLines: 1, style: TextStyle(fontSize: 11, color: Colors.blueGrey),),
                    ],),
                  ))
                ],),
                SizedBox(height: 40,),
              ])),
            ),
          ),
        ),
      ),
      floatingActionButton: _item.isMine ? UiFabCircular(
        MdiIcons.pencil,
        _listActions,
        _action,
        getOffset: (i) {
          double x = 0.0, y = 0.0;
          if (i == 0) {
            x = -5;
            y = 0;
          } else if (i == 1) {
            x = 1;
            y = -5;
          } else if (i == 2) {
            x = 5;
            y = 0;
          }
          return Offset(x, y);
        },
        getSize: (i) => 32.0 - 6 * i,
      ) : null
    );
  }
}