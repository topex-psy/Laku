// import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:geocoder/geocoder.dart';
import 'package:geolocator/geolocator.dart';
import 'package:line_icons/line_icons.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import '../providers/settings.dart';
import '../utils/api.dart';
import '../utils/constants.dart';
import '../utils/curves.dart';
import '../utils/helpers.dart';
import '../utils/styles.dart' as style;
import '../utils/widgets.dart';

const SECTION_MARGIN = 26.0;
// const TIMER_INTERVAL_SECONDS = 10;

class Beranda extends StatefulWidget {
  Beranda({Key key, this.isOpen = false}) : super(key: key);
  final bool isOpen;

  @override
  _BerandaState createState() => _BerandaState();
}

class _BerandaState extends State<Beranda> with TickerProviderStateMixin {
  final _refreshController = RefreshController(initialRefresh: false);
  final _scrollController = ScrollController();
  AnimationController _spinController;
  var _isGranted = false;
  var _isLoading = true;
  // Timer _timer;

  AnimationController _headerOffsetAnimationController;
  AnimationController _headerOpacityAnimationController;
  Animation<Offset> _headerOffsetAnimation;
  Animation<double> _headerOpacityAnimation;

  // @override
  // void didUpdateWidget(Beranda oldWidget) {
  //   super.didUpdateWidget(oldWidget);
  //   WidgetsBinding.instance.addPostFrameCallback((_) {
  //     if (!oldWidget.isOpen && widget.isOpen) _runTimer();
  //     if (oldWidget.isOpen && !widget.isOpen) _timer?.cancel();
  //   });
  // }

  @override
  void initState() {
    _headerOffsetAnimationController = AnimationController(vsync: this, duration: Duration(seconds: 0));
    _headerOffsetAnimation = Tween(begin: Offset(0.0, 0.0), end: Offset(0.0, -100.0)).animate(_headerOffsetAnimationController);
    _headerOpacityAnimationController = AnimationController(vsync: this, duration: Duration(seconds: 0));
    _headerOpacityAnimation = Tween(begin: 1.0, end: 0.0).animate(_headerOpacityAnimationController);
    _spinController = AnimationController(
      duration: Duration(milliseconds: 500),
      vsync: this,
    );
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getMyLocation();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _headerOffsetAnimationController.dispose();
    _headerOpacityAnimationController.dispose();
    _refreshController.dispose();
    // _timer.cancel();
    super.dispose();
  }

  // _runTimer() {
  //   print("RUN TIMEEEEEEEEEEEEEEEEER");
  //   _getAllData();
  //   _timer = Timer.periodic(Duration(seconds: TIMER_INTERVAL_SECONDS), (timer) => _getAllData());
  // }

  // _revokeTimer() {
  //   _timer?.cancel();
  //   _runTimer();
  // }

  _getMyLocation() async {
    var isGranted = await Permission.location.request().isGranted;
    if (_isGranted != isGranted) setState(() {
      _isGranted = isGranted;
    });
    if (!isGranted) return;

    final settings = Provider.of<SettingsProvider>(context, listen: false);
    if (settings.isGettingLocation) return;
    settings.setSettings(isGettingLocation: true);
    // _timer?.cancel();
    _spinController.forward();

    print("... GETTING MY LOCATION");
    var address = settings.address;
    // try {
      var position = await Geolocator().getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      var coordinates = Coordinates(position.latitude, position.longitude);
      print("... GETTING MY LOCATION result: $coordinates");
      api('user', type: 'post', sub1: 'location', data: {
        'uid': userSession.uid,
        'lat': coordinates.latitude,
        'lng': coordinates.longitude,
      }).then((locationUpdateApi) {
        // if (locationUpdateApi.isSuccess) _runTimer();
        _getAllData();
      });

      var addresses = <Address>[];

      try {
        addresses = await Geocoder.local.findAddressesFromCoordinates(coordinates);
      } on PlatformException catch(e) {
        // device no support geocoding, try online
        print(e);
        addresses = await Geocoder.google(APP_GOOGLE_MAP_KEY, language: APP_LOCALE).findAddressesFromCoordinates(coordinates);
      }

      if (addresses.isNotEmpty) {
        address = addresses.first;
        print(
          "... GET ADDRESS result"
          "\n name: ${address.featureName}"
          "\n address: ${address.addressLine}"
          "\n streetName: ${address.thoroughfare}"
          "\n streetNo: ${address.subThoroughfare}"
          "\n kelurahan: ${address.subLocality}"
          "\n kecamatan: ${address.locality}"
          "\n city: ${address.subAdminArea}"
          "\n zip: ${address.postalCode}"
          "\n province: ${address.adminArea}"
          "\n countryName: ${address.countryName}"
          "\n countryCode: ${address.countryCode}"
        );
      }


    // } catch(e) {
    //   print("... GETTING MY LOCATION error: $e");
    // }
    // finally {
      _spinController.reset();
      settings.setSettings(address: address, isGettingLocation: false);
    // }
  }

  _getAllData() async {
    if (!mounted) return;
    print(" ==> GET ALL DATA ..................");
    if (await a.loadNotif()) {
      _refreshController.refreshCompleted();
    } else {
      _refreshController.refreshFailed();
    }
    if (mounted && _isLoading) setState(() {
      _isLoading = false;
    });
  }

  List<LineChartBarData> _getLineChartBarData() {
    final LineChartBarData lineChartBarData1 = LineChartBarData(
      spots: [
        FlSpot(1, 1),
        FlSpot(3, 1.5),
        FlSpot(5, 1.4),
        FlSpot(7, 3.4),
        FlSpot(10, 2),
        FlSpot(12, 2.2),
        FlSpot(13, 1.8),
      ],
      isCurved: true,
      colors: [
        Color(0xff4af699),
      ],
      barWidth: 6,
      isStrokeCapRound: true,
      dotData: FlDotData(show: false,),
      belowBarData: BarAreaData(show: false,),
    );
    final LineChartBarData lineChartBarData2 = LineChartBarData(
      spots: [
        FlSpot(1, 1),
        FlSpot(3, 2.8),
        FlSpot(7, 1.2),
        FlSpot(10, 2.8),
        FlSpot(12, 2.6),
        FlSpot(13, 3.9),
      ],
      isCurved: true,
      colors: [
        Color(0xffeba434),
      ],
      barWidth: 5,
      isStrokeCapRound: true,
      dotData: FlDotData(show: true,),
      belowBarData: BarAreaData(show: false,),
    );
    final LineChartBarData lineChartBarData3 = LineChartBarData(
      spots: [
        FlSpot(1, 2.8),
        FlSpot(3, 1.9),
        FlSpot(6, 3),
        FlSpot(10, 1.3),
        FlSpot(13, 2.5),
      ],
      isCurved: true,
      colors: const [
        Color(0xff27b6fc),
      ],
      barWidth: 7,
      isStrokeCapRound: true,
      dotData: FlDotData(show: false,),
      belowBarData: BarAreaData(show: false,),
    );
    return [
      lineChartBarData1,
      lineChartBarData2,
      lineChartBarData3,
    ];
  }

  LineChartData _getLineChartData() {
    return LineChartData(
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(tooltipBgColor: Colors.teal[900],),
        touchCallback: (LineTouchResponse touchResponse) {},
        handleBuiltInTouches: true,
      ),
      gridData: FlGridData(show: false,),
      titlesData: FlTitlesData(
        bottomTitles: SideTitles(
          showTitles: true,
          reservedSize: 22,
          textStyle: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13,),
          margin: 6,
          getTitles: (value) {
            switch (value.toInt()) {
              case 2:
                return 'SEPT';
              case 7:
                return 'OCT';
              case 12:
                return 'DEC';
            }
            return '';
          },
        ),
        leftTitles: SideTitles(
          showTitles: true,
          textStyle: TextStyle(color: Colors.white70, fontSize: 12,),
          getTitles: (value) {
            switch (value.toInt()) {
              case 1:
                return '10';
              case 2:
                return '20';
              case 3:
                return '30';
              case 4:
                return '50';
            }
            return '';
          },
          margin: 4,
          reservedSize: 40,
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border(bottom: BorderSide(color: Colors.white54, width: 1,),),
      ),
      minX: 0,
      maxX: 14,
      maxY: 4,
      minY: 0,
      lineBarsData: _getLineChartBarData(),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isGranted) return Container(
      padding: EdgeInsets.all(THEME_PADDING),
      child: UiPlaceholder(
        label: "Harap izinkan aplikasi untuk mengakses lokasi Anda saat ini.",
        actionLabel: "Izinkan",
        action: _getMyLocation,
      )
    );

    return Stack(
      children: [
        AnimatedBuilder(
          animation: _headerOffsetAnimationController,
          builder: (context, child) {
            return Transform.translate(
              offset: _headerOffsetAnimation.value,
              child: Container(width: double.infinity, height: 500.0, child: CustomPaint(painter: CurvePainter(color: THEME_COLOR,),),),
            );
          }
        ),
        Positioned.fill(
          child: SafeArea(
            child: NotificationListener<ScrollNotification>(
              onNotification: (scrollNotification) {
                if (scrollNotification.metrics.axis == Axis.vertical && scrollNotification is ScrollUpdateNotification) {
                  // print("scrollNotification metrics: ${scrollNotification.metrics.pixels} / ${_scrollController.offset}");
                  _headerOffsetAnimationController.animateTo(_scrollController.offset / 200);
                  _headerOpacityAnimationController.animateTo((_scrollController.offset - 210) / 40);
                  return true;
                }
                if (scrollNotification is ScrollStartNotification) {
                  // if (_isChartButton && !_isChartExpand) setState(() {
                  //   _isChartButton = false;
                  // });
                } else if (scrollNotification is ScrollUpdateNotification) {
                } else if (scrollNotification is ScrollEndNotification) {
                  // if (!_isChartButton && _scrollController.offset <= kToolbarHeight) setState(() {
                  //   _isChartButton = true;
                  // });
                }
                return true;
              },
              child: NestedScrollView(
                controller: _scrollController,
                headerSliverBuilder: (context, innerBoxIsScrolled) {
                  return <Widget>[
                    SliverAppBar(
                      iconTheme: IconThemeData(color: Colors.white),
                      leading: Padding(
                        padding: EdgeInsets.only(left: 8.0),
                        child: IconButton(
                          icon: Icon(Icons.sort, color: Colors.white),
                          onPressed: () => screenScaffoldKey.currentState.openEndDrawer(),
                        ),
                      ),
                      actions: [
                        IconButton(icon: Icon(LineIcons.bell_o, color: Colors.white,), tooltip: 'Notifikasi', onPressed: () async {
                          // TODO show popup notification (broadcast berakhir, news, etc)
                        },),
                        IconButton(icon: Icon(LineIcons.user, color: Colors.white,), tooltip: 'Profil Saya', onPressed: () async {
                          a.openProfile();
                        },),
                        // IconButton(icon: Icon(LineIcons.bell_o, color: Colors.white,), tooltip: 'Notifikasi', onPressed: () async {
                        //   final results = await Navigator.of(context).pushNamed(ROUTE_DATA, arguments: {'tipe': 'user_notif'}) as Map;
                        //   print(results);
                        // },),
                        SizedBox(width: 8,)
                      ],
                      backgroundColor: THEME_COLOR,
                      expandedHeight: kToolbarHeight,
                      floating: false,
                      pinned: false,
                    ),
                    SliverPersistentHeader(
                      delegate: UiMainHeader(
                        Column(
                          children: [
                            AnimatedBuilder(
                              animation: _headerOpacityAnimationController,
                              builder: (context, child) {
                                return Opacity(
                                  opacity: _headerOpacityAnimation.value,
                                  child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: <Widget>[
                                    SizedBox(width: 10,),
                                    Icon(LineIcons.map_marker, color: Colors.white, size: 50,),
                                    SizedBox(width: 12,),
                                    Expanded(
                                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
                                        Text('prompt_current_location'.tr(), style: style.textWhite),
                                        Consumer<SettingsProvider>(
                                          builder: (context, settings, child) {
                                            return settings.isGettingLocation || settings.address == null ? Container(
                                              width: 50.0,
                                              height: 46.0,
                                              child: SpinKitThreeBounce(color: Colors.white, size: 30.0,),
                                            ) : GestureDetector(
                                              onTap: a.openMap,
                                              child: Container(
                                                height: 46.0,
                                                child: RichText(text: TextSpan(
                                                  style: Theme.of(context).textTheme.bodyText1,
                                                  children: <TextSpan>[
                                                    TextSpan(text: '${settings.address.subAdminArea},\n', style: style.textHeadlineWhite),
                                                    TextSpan(text: settings.address.countryName, style: style.textTitleWhite,)
                                                  ],
                                                ),),
                                              ),
                                            );
                                          }
                                        ),
                                      ],),
                                    ),
                                    Material(
                                      color: Colors.transparent,
                                      shape: CircleBorder(),
                                      clipBehavior: Clip.antiAlias,
                                      child: IconButton(
                                        highlightColor: Colors.white24,
                                        splashColor: Colors.white24,
                                        padding: EdgeInsets.all(15),
                                        onPressed: _getMyLocation,
                                        icon: RotationTransition(
                                          turns: Tween(begin: 0.0, end: 1.0).animate(_spinController),
                                          child: Icon(LineIcons.refresh, color: Colors.white,),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 10,),
                                  ],),
                                );
                              }
                            ),
                            Expanded(child: LayoutBuilder(
                              builder: (context, constraints) {
                                return constraints.maxHeight < 56 ? SizedBox() : Container(
                                  padding: EdgeInsets.only(top: 10),
                                  width: double.infinity,
                                  height: constraints.maxHeight,
                                  child: Opacity(
                                    opacity: min(1, (constraints.maxHeight - 56) / 100),
                                    child: LineChart(
                                      _getLineChartData(),
                                      swapAnimationDuration: Duration(milliseconds: 500),
                                    ),
                                  ),
                                );
                              },
                            ),)
                          ],
                        ),
                      ),
                      pinned: true,
                    ),
                  ];
                },
                body: Stack(
                  alignment: Alignment.topCenter,
                  children: <Widget>[
                    Positioned.fill(child: SmartRefresher(
                      enablePullDown: true,
                      enablePullUp: false,
                      header: WaterDropMaterialHeader(color: Colors.white, backgroundColor: THEME_COLOR),
                      controller: _refreshController,
                      onRefresh: _getAllData,
                      child: SingleChildScrollView(
                        child: AnimatedOpacity(
                          opacity: _isLoading ? 0 : 1,
                          duration: Duration(milliseconds: 1000),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[

                                  // AnimatedSize(
                                  //   duration: Duration(milliseconds: 800),
                                  //   curve: Curves.easeOut,
                                  //   vsync: this,
                                  //   child: _isChartExpand ? Padding(
                                  //     padding: EdgeInsets.only(bottom: 12),
                                  //     child: Container(
                                  //       width: double.infinity,
                                  //       height: 150,
                                  //       child: LineChart(
                                  //         _getLineChartData(),
                                  //         swapAnimationDuration: Duration(milliseconds: 500),
                                  //       ),
                                  //     ),
                                  //   ) : Container(width: double.infinity,),
                                  // ),

                                  // Center(
                                  //   child: Padding(
                                  //     padding: EdgeInsets.only(bottom: SECTION_MARGIN),
                                  //     child: AnimatedOpacity(
                                  //       opacity: _isChartButton ? 1 : 0,
                                  //       duration: Duration(milliseconds: 400),
                                  //       child: UiButton(
                                  //         _isChartExpand ? "Hide chart" : "Show chart",
                                  //         icon: _isChartExpand ? LineIcons.chevron_circle_up : LineIcons.chevron_circle_down,
                                  //         width: 118,
                                  //         height: 30,
                                  //         textStyle: style.textWhiteS,
                                  //         color: Colors.teal[300],
                                  //         onPressed: () {
                                  //           setState(() {
                                  //             _isChartExpand = !_isChartExpand;
                                  //           });
                                  //         },
                                  //       ),
                                  //     ),
                                  //   ),
                                  // ),

                                  Center(child: Text('prompt_current_items'.tr(), textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.teal[200]),),),
                                  SizedBox(height: 12,),
                                  CardList('iklanTerpasang'),
                                  CardList('broadcastAktif'),
                                  CardList('iklanFavorit'),
                                  CardList('pesanMasuk'),

                                  SizedBox(height: SECTION_MARGIN,),

                                  Center(child: Text("Di sekitarmu ada:", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.teal[200]),),),
                                  SizedBox(height: 12,),
                                  Wrap(spacing: 8, runSpacing: 8, runAlignment: WrapAlignment.center, children: <Widget>[
                                    CardBox('iklan'),
                                    CardBox('pengguna'),
                                    CardBox('pencari'),
                                  ],),

                                  SizedBox(height: SECTION_MARGIN,),

                                ],),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),),
                    _isLoading ? Positioned.fill(child: SafeArea(
                      child: AbsorbPointer(
                        child: Container(
                          child: Center(
                            child: SpinKitChasingDots(
                              color: Colors.teal[300],
                              size: 100,
                            ),
                          ),
                        ),
                      ),
                    ),) : SizedBox()
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class CardBox extends StatefulWidget {
  CardBox(this.notif, {Key key}) : super(key: key);
  final String notif;

  @override
  _CardBoxState createState() => _CardBoxState();
}

class _CardBoxState extends State<CardBox> {
  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    var size = (MediaQuery.of(context).size.width - 38) / 2;
    int notif;
    VoidCallback action;
    Color color;
    IconData icon;
    String label;

    switch (widget.notif) {
      case 'iklan':
        notif = settings.notif?.iklan;
        color = Colors.blue;
        icon = LineIcons.map_marker;
        label = 'menu_listing'.plural(notif ?? 1);
        action = () {
          settings.setSettings(isViewFavorites: false);
          a.navigatePage(1);
        };
        break;
      case 'pengguna':
        notif = settings.notif?.pengguna;
        color = Colors.green;
        icon = LineIcons.users;
        label = 'menu_user'.plural(notif ?? 1);
        action = () {
          // TODO list shop near
        };
        break;
      case 'pencari':
        notif = settings.notif?.pencari;
        color = Colors.orange;
        icon = LineIcons.binoculars;
        label = 'menu_seeker'.plural(notif ?? 1);
        action = () {
          // TODO list iklan WTB near
        };
        break;
    }
    if ((notif ?? 0) == 0 && widget.notif != 'iklan') return SizedBox();
    return SizedBox(
      width: size,
      height: size,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(THEME_CARD_RADIUS)),
        elevation: THEME_CARD_ELEVATION,
        color: color,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: action,
          child: Stack(
            alignment: Alignment.topRight,
            children: [
              Icon(icon, color: Colors.white30, size: 80,),
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: FractionalOffset.topLeft,
                    end: FractionalOffset.bottomCenter,
                    colors: [
                      Colors.white.withOpacity(0.0),
                      Colors.white.withOpacity(0.1),
                    ],
                    stops: [
                      0.0,
                      1.0,
                    ]
                  ),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
                  // TODO check spinkit size
                  notif == null ? SpinKitRipple(color: Colors.white70, size: 50,) : Text(f.formatNumber(notif), style: style.textHeadlineXLWhite,),
                  Text(label, style: style.textTitleWhite,),
                  SizedBox(height: 14,),
                  Row(children: <Widget>[
                    Expanded(child: Text('prompt_more'.tr(), style: style.textWhite70S,)),
                    SizedBox(width: 8,),
                    Icon(LineIcons.chevron_circle_right, color: Colors.white70, size: 15,)
                  ],)
                ],),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CardList extends StatefulWidget {
  CardList(this.notif, {Key key}) : super(key: key);
  final String notif;

  @override
  _CardListState createState() => _CardListState();
}

class _CardListState extends State<CardList> {
  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    int notif;
    VoidCallback action;
    String buttonLabel, label;
    IconData buttonIcon;
    double buttonWidth;
    Color buttonColor = Colors.teal[300];
    switch (widget.notif) {
      case 'iklanFavorit':
        notif = settings.notif?.iklanFavorit;
        label = "Iklan favorit";
        buttonColor = Colors.pink[300];
        buttonLabel = "Cek";
        buttonWidth = 90;
        buttonIcon = LineIcons.shopping_cart;
        action = () {
          settings.setSettings(isViewFavorites: true);
          a.navigatePage(1);
        };
        break;
      case 'iklanTerpasang':
        notif = settings.notif?.iklanTerpasang;
        label = "Iklan terpasang";
        buttonLabel = notif == 0 ? "Buat" : "Kelola";
        buttonWidth = notif == 0 ? 98 : 110;
        buttonIcon = notif == 0 ? LineIcons.plus_circle : LineIcons.dropbox;
        action = () {
          a.openMyShop();
        };
        break;
      case 'broadcastAktif':
        notif = settings.notif?.broadcastAktif;
        label = "Broadcast aktif";
        buttonLabel = "Lihat";
        buttonWidth = 100;
        buttonIcon = LineIcons.binoculars;
        action = () {
          // TODO buka kelola pencarian
        };
        break;
      case 'pesanMasuk':
        notif = settings.notif?.pesanMasuk;
        label = "Pesan masuk";
        buttonColor = Colors.orange[300];
        buttonLabel = "Cek";
        buttonWidth = 90;
        buttonIcon = LineIcons.inbox;
        action = () {
          // TODO buka kelola pesan
        };
        break;
    }
    notif ??= 0;
    return notif == 0 && widget.notif != 'iklanTerpasang' ? SizedBox() : Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(THEME_CARD_RADIUS)),
      elevation: THEME_CARD_ELEVATION,
      shadowColor: Colors.grey[300],
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Row(children: <Widget>[
          SizedBox(width: 8,),
          Text(f.formatNumber(notif) ?? '0', style: style.textHeadline,),
          SizedBox(width: 8,),
          Expanded(child: Text(label)),
          UiButton(
            buttonLabel,
            width: buttonWidth,
            color: buttonColor,
            textStyle: style.textButton,
            icon: buttonIcon,
            iconRight: true,
            onPressed: action
          ),
        ],),
      ),
    );
  }
}

class UiMainHeader extends SliverPersistentHeaderDelegate {
  UiMainHeader(this._widget);
  final Widget _widget;

  @override
  double get minExtent => 104.0;
  @override
  double get maxExtent => 264.0;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      child: Padding(
        padding: EdgeInsets.only(top: 20, bottom: 20),
        child: _widget,
      )
    );
  }

  @override
  bool shouldRebuild(UiMainHeader oldDelegate) {
    return false;
  }
}