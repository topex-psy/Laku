import 'dart:math';

import 'package:flutter/material.dart';
// import 'package:carousel_pro/carousel_pro.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:expandable/expandable.dart';
import 'package:flutter_swiper_plus/flutter_swiper_plus.dart';
import 'package:line_icons/line_icons.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import '../extensions/widget.dart';
import '../plugins/image_gallery_viewer.dart';
import '../utils/api.dart';
import '../utils/constants.dart';
import '../utils/models.dart' show MenuModel, ListingModel;
import '../utils/widgets.dart';
import '../utils/variables.dart';

const MAX_DESCRIPTION_LENGTH = 150;

class ListingPage extends StatefulWidget {
  const ListingPage(this.args, {Key? key}) : super(key: key);
  final Map<String, dynamic> args;

  @override
  _ListingPageState createState() => _ListingPageState();
}

class _ListingPageState extends State<ListingPage> with TickerProviderStateMixin {
  final _scrollController = ScrollController();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _refreshController = RefreshController(initialRefresh: false);

  bool get isShrink => _scrollController.hasClients && _scrollController.offset > (200 - kToolbarHeight);
  // Color _titleColor = HSLColor.fromAHSL(1, 1, 1, 0).toColor();
  var _titleOpacity = 0.0;
  late ListingModel _item;

  _getAllData() async {
    final putListingResult = await ApiProvider().api('listing', method: "get", withLog: true, getParams: { 'id': _item.id.toString() });
    if (putListingResult.isSuccess) {
      _refreshController.refreshCompleted();
      setState(() {
        _item = ListingModel.fromJson(putListingResult.data.first);
      });
    } else {
      _refreshController.refreshFailed();
    }
  }

  _scrollListener() {
    if ((_scrollController.offset % 10).floor() > 0) return;
    if (!isShrink) {
      setState(() {
        var opacity = min(1, _scrollController.offset / (200 - kToolbarHeight)).toDouble();
        // _titleColor = HSLColor.fromAHSL(1, 1, 1, opacity).toColor();
        _titleOpacity = opacity;
      });
    }
  }

  _action(String action) async {
    print("TAP ACTION: $action");
    switch (action) {
      case 'favorit':
        final favoriteResult = await ApiProvider().api("favorite", data: {
          "id": _item.id,
          "type": _item.isFavorite ? 'del' : 'add'
        });
        if (favoriteResult.isSuccess) {
          if (_item.isFavorite) {
            h.showFlashBar("Favorit Dihapus!", "Iklan ini berhasil dihapus dari daftar favorit!", actionLabel: "Undo", action: () => _action('favorit'));
          } else {
            h.showFlashbarSuccess("Favorit Ditambahkan!", "Iklan ini berhasil ditambahkan ke daftar favorit!");
          }
          setState(() {
            _item.toggleFav();
          });
          u.loadNotif();
        }
        break;
      case 'edit':
        final editResult = await Navigator.pushNamed(context, ROUTE_CREATE, arguments: {
          "item": _item,
        }) as Map?;
        print("editResult: $editResult");
        reInitContext(context);
        if (editResult?.containsKey('isSubmit') ?? false) {
          _getAllData();
        }
        break;
      case 'edit_shop':
        break;
      case 'open_shop':
        break;
      case 'delete':
        if (await h.showConfirmDialog('action_confirm'.tr(), title: 'action_delete_listing'.tr()) ?? false) {
          // TODO hapus iklan
        }
        break;
      case 'deactivate':
        if (await h.showConfirmDialog('action_confirm'.tr(), title: 'action_deacivate'.tr()) ?? false) {
          // TODO nonaktif
        }
        break;
      case 'chat':
        break;
      case 'telepon':
        break;
      case 'report':
        break;
    }
  }

  @override
  void initState() {
    _item = widget.args['item'];
    _scrollController.addListener(_scrollListener);
    super.initState();
    WidgetsBinding.instance?.addPostFrameCallback((_) {
      // params: https://firebase.google.com/docs/reference/android/com/google/firebase/analytics/FirebaseAnalytics.Param#LOCATION_ID
      firebaseAnalytics.logViewItem(
        itemId: _item.id.toString(),
        itemName: _item.title,
        itemCategory: _item.category ?? "other",
        itemLocationId: _item.latLng,
        price: _item.price,
        // quantity: 6,
        currency: 'IDR',
        // value: 67.8,
        // flightNumber: 'test flight number',
        // numberOfPassengers: 3,
        // numberOfRooms: 1,
        // numberOfNights: 2,
        // origin: 'test origin',
        // destination: 'test destination',
        startDate: _item.validFrom?.toIso8601String(),
        endDate: _item.validUntil?.toIso8601String(),
        // searchTerm: 'test search term',
        // travelClass: 'test travel class',
      );
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
                iconTheme: const IconThemeData(color: Colors.white),
                leading: IconButton(
                  icon: const Icon(Icons.chevron_left, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                backgroundColor: APP_UI_COLOR_MAIN,
                expandedHeight: 300.0,
                floating: true,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: false,
                  title: Text(_item.title, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.white)).withOpacity(_titleOpacity),
                  background: SizedBox(
                    height: 300.0,
                    width: MediaQuery.of(context).size.width,
                    child: Stack(
                      children: <Widget>[
                        Positioned.fill(
                          child: Swiper(
                            itemBuilder: (BuildContext context, int index) {
                              final pic = _item.images[index];
                              final heroTag = "listing_${_item.id}";
                              return GestureDetector(
                                onTap: () {
                                  final galleryItems = _item.images.map((image) => ImageGalleryItem(src: image, heroTag: heroTag)).toList();
                                  Navigator.push(context, MaterialPageRoute(
                                    builder: (context) => ImageGalleryViewer(
                                      galleryItems: galleryItems,
                                      backgroundDecoration: const BoxDecoration(color: Colors.black,),
                                      initialIndex: index,
                                      scrollDirection: Axis.horizontal,
                                    ),
                                  ));
                                },
                                child: Hero(
                                  tag: "${heroTag}_$index",
                                  child: FadeInImage.assetNetwork(
                                    placeholder: SETUP_IMAGE_NONE,
                                    image: pic,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              );
                            },
                            indicatorLayout: PageIndicatorLayout.COLOR,
                            autoplay: true,
                            itemCount: _item.images.length,
                            pagination: const SwiperPagination(),
                            control: const SwiperControl(),
                          ),
                          // child: Carousel(
                          //   images: _item.images.asMap().map((index, pic) {
                          //     final heroTag = "listing_${_item.id}";
                          //     return MapEntry(index, GestureDetector(
                          //       onTap: () {
                          //         final galleryItems = _item.images.map((image) => ImageGalleryItem(src: image, heroTag: heroTag)).toList();
                          //         Navigator.push(context, MaterialPageRoute(
                          //           builder: (context) => ImageGalleryViewer(
                          //             galleryItems: galleryItems,
                          //             backgroundDecoration: const BoxDecoration(color: Colors.black,),
                          //             initialIndex: index,
                          //             scrollDirection: Axis.horizontal,
                          //           ),
                          //         ));
                          //       },
                          //       child: Hero(
                          //         tag: "${heroTag}_$index",
                          //         child: FadeInImage.assetNetwork(
                          //           placeholder: DEFAULT_NONE_PIC_ASSET,
                          //           image: pic,
                          //           fit: BoxFit.cover,
                          //         ),
                          //       ),
                          //     ));
                          //   }).values.toList(),
                          //   autoplay: true,
                          //   autoplayDuration: const Duration(milliseconds: 8000),
                          //   animationDuration: const Duration(milliseconds: 800),
                          //   showIndicator: _item.images.length > 1,
                          //   dotSize: 5.0,
                          //   dotSpacing: 16.0,
                          //   dotBgColor: Colors.white,
                          //   dotColor: APP_UI_COLOR_MAIN,
                          //   dotIncreasedColor: APP_UI_COLOR_LIGHT,
                          // ),
                        ),
                        Align(
                          alignment: Alignment.bottomRight,
                          child: Padding(
                            padding: const EdgeInsets.all(30.0),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Text("${f.formatNumber(_item.viewCount)}x", style: const TextStyle(fontSize: 13, color: Colors.grey)),
                                const SizedBox(width: 4,),
                                const Icon(Icons.visibility, color: APP_UI_COLOR_MAIN, size: 18,),
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
          body: SmartRefresher(
            enablePullDown: true,
            enablePullUp: false,
            header: const WaterDropMaterialHeader(color: APP_UI_COLOR_MAIN, backgroundColor: Colors.white),
            controller: _refreshController,
            onRefresh: _getAllData,
            child: SingleChildScrollView(child: Column(children: <Widget>[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.only(left: 20, top: 20, bottom: 20),
                color: Colors.white,
                child: Column(
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(child: Text(_item.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20))),
                        const SizedBox(width: 8,),
                        (_item.deliveryInfo??"").isEmpty ? const SizedBox() : SizedBox(
                          width: 40,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              const Icon(LineIcons.truck, color: Colors.teal),
                              const SizedBox(height: 2,),
                              Text(_item.deliveryInfo!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12),)
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
                        //       Text(f.distanceLabel(_item.jarakMeter), textAlign: TextAlign.center, style: const TextStyle(fontSize: 12),)
                        //     ],
                        //   ),
                        // ),
                        SizedBox(
                          width: 40,
                          child: Stack(
                            alignment: Alignment.topCenter,
                            children: <Widget>[
                              Transform.translate(
                                offset: const Offset(0, -8.5),
                                child: Material(
                                  color: Colors.transparent,
                                  shape: const CircleBorder(),
                                  clipBehavior: Clip.antiAlias,
                                  child: IconButton(icon: Icon(_item.isFavorite ? Icons.favorite : Icons.favorite_outlined), color: Colors.pink, onPressed: () => _action('favorit'),)
                                ),
                              ),
                              Transform.translate(
                                offset: const Offset(0, 29.5),
                                child: Text(f.formatNumber(_item.favoriteCount), textAlign: TextAlign.center, style: const TextStyle(fontSize: 12),),
                              )
                            ],
                          ),
                        ),
                        const SizedBox(width: 12,)
                      ],
                    ),
                    const SizedBox(height: 16,),
                    Row(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                      Expanded(
                        child: Column(
                          children: <Widget>[
                            Row(
                              children: <Widget>[
                                const Text("Kategori:"),
                                const SizedBox(width: 4,),
                                Expanded(child: Text(_item.category ?? tr("select.other"), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),)),
                              ],
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 2.0),
                              child: Row(
                                children: <Widget>[
                                  const Text("Kondisi:"),
                                  const SizedBox(width: 4,),
                                  Text(tr('item_condition.${_item.isNew ? 'new' : 'used'}'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),),
                                  const SizedBox(width: 4,),
                                  _item.isNew ? const SizedBox() : const Icon(Icons.error, color: Colors.grey, size: 18,)
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 2.0),
                              child: Row(
                                children: const <Widget>[
                                  Text("Stok:"),
                                  SizedBox(width: 4,),
                                  Expanded(child: Text("Tersedia", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20,),
                      Expanded(flex: 0, child: _item.price == 0 ? const SizedBox() : Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Container(
                              padding: const EdgeInsets.only(right: 20),
                              decoration: BoxDecoration(
                                color: Colors.redAccent[400],
                              ),
                              child: Row(
                                children: <Widget>[
                                  Transform.translate(
                                    offset: const Offset(-3, 0),
                                    child: Transform.rotate(
                                      angle: 90 * pi / 180,
                                      child: const Icon(Icons.play_arrow, color: Colors.white, size: 28,),
                                    ),
                                  ),
                                  const SizedBox(width: 6,),
                                  Text(f.formatPriceAbbr(_item.price, singkat: true), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.white)),
                                ],
                              ),
                            ),
                            _item.isNegotiable ? Padding(
                              padding: const EdgeInsets.only(top: 8, right: 20),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const <Widget>[
                                  Text("Bisa nego"),
                                  SizedBox(width: 2,),
                                  Icon(Icons.check_circle, size: 20, color: Colors.green,)
                                ],
                              ),
                            ) : const SizedBox()
                          ],
                        ),
                      ),)
                    ],),
                  ],
                ),
              ),
              const SizedBox(height: 12,),

              MySection(title: "Detail Produk", titleSpacing: 16, children: <Widget>[
                ExpandableNotifier(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expandable(
                        collapsed: Text(_item.description, softWrap: true, maxLines: 5, overflow: TextOverflow.ellipsis,),
                        expanded: Text(_item.description, softWrap: true,),
                      ),
                      Builder(
                        builder: (context) {
                          final expandController = ExpandableController.of(context);
                          final isExpanded = expandController?.expanded ?? false;
                          return FlatButton(
                            padding: EdgeInsets.zero,
                            highlightColor: Colors.transparent,
                            splashColor: Colors.transparent,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Text(
                                  isExpanded ? "Lebih Ringkas" : "Selengkapnya",
                                  style: const TextStyle(color: APP_UI_COLOR_MAIN),
                                ),
                                const SizedBox(width: 4,),
                                Icon(isExpanded ? LineIcons.chevronUp : LineIcons.chevronDown, color: APP_UI_COLOR_MAIN)
                              ],
                            ),
                            onPressed: expandController?.toggle,
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
              //                     style: TextStyle(color: APP_UI_COLOR_MAIN),
              //                   ),
              //                   SizedBox(width: 4,),
              //                   Icon(_expandController.expanded ? MdiIcons.chevronUp : MdiIcons.chevronDown, color: APP_UI_COLOR_MAIN)
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
                padding: const EdgeInsets.only(left: 20, top: 20, bottom: 20, right: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    GestureDetector(
                      onTap: () => _action('open_shop'),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                        MyAvatar(_item.shop?.image ?? _item.owner.image, size: 48, strokeWidth: 0),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                          Text(_item.shop?.name ?? _item.owner.name, style: const TextStyle(fontWeight: FontWeight.bold),),
                          const SizedBox(height: 4,),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: <Widget>[
                              Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
                                const Icon(Icons.favorite_outline, size: 20, color: Colors.pink,),
                                const SizedBox(width: 6,),
                                Text("${f.formatNumber(_item.shop?.favoriteCount ?? _item.owner.favoriteCount!)} favorit"),
                              ],),
                              Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
                                const Icon(Icons.file_present_outlined, size: 20, color: Colors.grey,),
                                const SizedBox(width: 6,),
                                Text("${f.formatNumber(_item.shop?.listingCount ?? _item.owner.listingCount!)} iklan"),
                              ],),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(children: <Widget>[
                            const Icon(Icons.circle, size: 20, color: Colors.grey,),
                            const SizedBox(width: 6,),
                            Expanded(child: Text(f.formatTimeago(_item.owner.lastActive), style: const TextStyle(fontSize: 12))),
                          ],),
                        ],),),
                        const SizedBox(width: 8),
                        _item.isMine ? IconButton(
                          padding: EdgeInsets.zero,
                          icon: const Icon(Icons.edit),
                          color: Colors.grey,
                          tooltip: "Edit",
                          onPressed: () => _action('edit_shop'),
                        ) : SizedBox(
                          width: 40,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              const Icon(Icons.place, color: Colors.grey),
                              const SizedBox(height: 2,),
                              Text(f.formatDistance(_item.distanceMeter), textAlign: TextAlign.center, style: const TextStyle(fontSize: 12),)
                            ],
                          ),
                        ),
                      ],),
                    ),
                    const SizedBox(height: 12,),
                    _item.isMine ? Container(
                      padding: const EdgeInsets.only(left: 60),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                        // Text("Peminat dapat menghubungi di:"),
                        // SizedBox(height: 8),
                        Row(
                          children: <Widget>[
                            const Icon(Icons.phone_android, size: 20, color: Colors.grey,),
                            const SizedBox(width: 6,),
                            const Text("Telepon:"),
                            const SizedBox(width: 6,),
                            Expanded(child: Text("$APP_PHONE_CODE${_item.owner.phone}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),),),
                          ],
                        )
                      ],),
                    ) : Row(children: <Widget>[
                      const SizedBox(width: 60,),
                      Expanded(child: MyButton("Telepon", color: Colors.green, icon: LineIcons.phone, onPressed: () => _action('telepon'),)),
                      const SizedBox(width: 8,),
                      Expanded(child: MyButton("Chat", color: Colors.blue, icon: LineIcons.comment, onPressed: () => _action('chat'),)),
                      const SizedBox(width: 8,),
                    ],)
                  ],
                ),
              ),
              const SizedBox(height: 20,),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                const SizedBox(width: 20,),
                const Expanded(child: Text("$APP_NAME hanya menampilkan informasi apa adanya sesuai data dari pengiklan. Harap selalu berhati-hati ketika bertransaksi.", style: TextStyle(fontSize: 12, color: Colors.grey))),
                SizedBox(width: 80, child: _item.isMine ? const SizedBox() : FlatButton(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(8),
                    bottomLeft: Radius.circular(8),
                  )),
                  onPressed: () => _action('report'),
                  child: Column(children: const <Widget>[
                    Icon(Icons.comment_outlined, color: Colors.grey, size: 20,),
                    SizedBox(height: 4,),
                    Text("Laporkan", maxLines: 1, style: TextStyle(fontSize: 11, color: Colors.blueGrey),),
                  ],),
                ),)
              ],),
              const SizedBox(height: 40,),
            ])),
          ),
        ),
      ),
      floatingActionButton: _item.isMine ? MyFabCircular(
        Icons.edit,
        [
          MenuModel("Edit", 'edit', icon: Icons.edit_attributes_outlined, onPressed: () => _action('edit')),
          MenuModel("Nonaktifkan", 'deactivate', icon: Icons.close, onPressed: () => _action('deactivate')),
          MenuModel("Hapus", 'delete', icon: Icons.delete_outline, onPressed: () => _action('delete')),
        ],
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