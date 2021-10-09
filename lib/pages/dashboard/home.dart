import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:line_icons/line_icons.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import '../../utils/constants.dart';
import '../../utils/curves.dart';
import '../../utils/models.dart';
import '../../utils/providers.dart';
import '../../utils/variables.dart';
import '../../utils/widgets.dart';

const SECTION_MARGIN = 26.0;
enum UserNotifType {
  listing,
  user,
  seeker,
  listingPosted,
  listingFavorites,
  broadcastActive,
  inbox,
}

class HomePage extends StatefulWidget {
  const HomePage({
    Key? key,
    this.isOpen = false,
    required this.onUpdatePosition
  }) : super(key: key);
  final bool isOpen;
  final void Function(Position) onUpdatePosition;

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  final _refreshController = RefreshController(initialRefresh: false);
  final _scrollController = ScrollController();
  late AnimationController _spinController;
  late AnimationController _headerOffsetAnimationController;
  late AnimationController _headerOpacityAnimationController;
  late Animation<Offset> _headerOffsetAnimation;
  late Animation<double> _headerOpacityAnimation;

  var _isLoading = true;

  @override
  void initState() {
    _headerOffsetAnimationController = AnimationController(vsync: this, duration: const Duration(seconds: 0));
    _headerOffsetAnimation = Tween(begin: const Offset(0.0, 0.0), end: const Offset(0.0, -100.0)).animate(_headerOffsetAnimationController);
    _headerOpacityAnimationController = AnimationController(vsync: this, duration: const Duration(seconds: 0));
    _headerOpacityAnimation = Tween(begin: 1.0, end: 0.0).animate(_headerOpacityAnimationController);
    _spinController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..forward();
    super.initState();
    WidgetsBinding.instance?.addPostFrameCallback((_) {
      _getAllData();
    });
  }

  @override
  void dispose() {
    _headerOffsetAnimationController.dispose();
    _headerOpacityAnimationController.dispose();
    _refreshController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  _getAllData() async {
    if (!mounted) return;
    _spinController.forward();
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    settings.setSettings(isGettingAddress: true);
    final position = await l.myPosition();
    print("current position: $position");
    widget.onUpdatePosition(position);

    print("... GETTING MY ADDRESS (${position.latitude}, ${position.longitude})");
    var address = settings.address;
    // PlatformException (PlatformException(IO_ERROR, A network error occurred trying to lookup the supplied coordinates (latitude: -7.928526, longitude: 112.640717)., null, null))
    try {
      print("... GET ADDRESS");
      final addresses = await placemarkFromCoordinates(position.latitude, position.longitude);
      if (addresses.isNotEmpty) {
        final addressTemp = addresses.first;
        if (
          (addressTemp.subAdministrativeArea ?? "").isNotEmpty &&
          (addressTemp.country ?? "").isNotEmpty
        ) {
          address = addressTemp;
        }
        print(
          "... GET ADDRESS result"
          "\n name: ${addressTemp.name}"
          "\n address: ${addressTemp.street}"
          "\n streetName: ${addressTemp.thoroughfare}"
          "\n streetNo: ${addressTemp.subThoroughfare}"
          "\n kelurahan: ${addressTemp.subLocality}"
          "\n kecamatan: ${addressTemp.locality}"
          "\n city: ${addressTemp.subAdministrativeArea}"
          "\n zip: ${addressTemp.postalCode}"
          "\n province: ${addressTemp.administrativeArea}"
          "\n countryName: ${addressTemp.country}"
          "\n countryCode: ${addressTemp.isoCountryCode}"
        );
      } else {
        print("... GET ADDRESS empty");
      }
      _spinController.reset();
    } catch(e) {
      print("... GET ADDRESS error: $e");
    }
    settings.setSettings(isGettingAddress: false, address: address);
    if (mounted && _isLoading) {
      setState(() {
        _isLoading = false;
      });
    }
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
        const Color(0xff4af699),
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
        const Color(0xffeba434),
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
        touchCallback: (touchEvent, touchResponse) {},
        handleBuiltInTouches: true,
      ),
      gridData: FlGridData(show: false,),
      titlesData: FlTitlesData(
        bottomTitles: SideTitles(
          showTitles: true,
          reservedSize: 22,
          getTextStyles: (context, axis) => const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13,),
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
          getTextStyles: (context, axis) => const TextStyle(color: Colors.white70, fontSize: 12,),
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
        rightTitles: SideTitles(showTitles: false),
        topTitles: SideTitles(showTitles: false),
      ),
      borderData: FlBorderData(
        show: true,
        border: const Border(bottom: BorderSide(color: Colors.white54, width: 1,),),
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
    return Stack(
      children: [
        AnimatedBuilder(
          animation: _headerOffsetAnimationController,
          builder: (context, child) {
            return Transform.translate(
              offset: _headerOffsetAnimation.value,
              child: SizedBox(width: double.infinity, height: 500.0, child: CustomPaint(painter: CurvePainter(color: APP_UI_COLOR_MAIN,),),),
            );
          }
        ),
        Positioned.fill(
          child: SafeArea(
            child: NotificationListener<ScrollNotification>(
              onNotification: (scrollNotification) {
                if (scrollNotification.metrics.axis == Axis.vertical && scrollNotification is ScrollUpdateNotification) {
                  _headerOffsetAnimationController.animateTo(_scrollController.offset / 200);
                  _headerOpacityAnimationController.animateTo((_scrollController.offset - 210) / 40);
                  return true;
                }
                if (scrollNotification is ScrollStartNotification) {
                } else if (scrollNotification is ScrollUpdateNotification) {
                } else if (scrollNotification is ScrollEndNotification) {
                }
                return true;
              },
              child: NestedScrollView(
                controller: _scrollController,
                headerSliverBuilder: (context, innerBoxIsScrolled) {
                  return <Widget>[
                    SliverAppBar(
                      iconTheme: const IconThemeData(color: Colors.white),
                      leading: Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: IconButton(
                          icon: const Icon(Icons.sort, color: Colors.white),
                          onPressed: () => screenScaffoldKey.currentState?.openEndDrawer(),
                        ),
                      ),
                      actions: [
                        IconButton(icon: const Icon(LineIcons.bell, color: Colors.white,), tooltip: 'menu_notifications'.tr(), onPressed: () {
                          // TODO show popup notification (broadcast berakhir, news, etc)
                        },),
                        IconButton(icon: const Icon(LineIcons.envelope, color: Colors.white,), tooltip: 'menu_inbox'.tr(), onPressed: () {
                          // TODO open inbox
                        }),
                        const SizedBox(width: 8,)
                      ],
                      backgroundColor: APP_UI_COLOR_MAIN,
                      expandedHeight: kToolbarHeight,
                      floating: false,
                      pinned: false,
                    ),
                    SliverPersistentHeader(
                      delegate: MyMainHeader(
                        Column(
                          children: [
                            AnimatedBuilder(
                              animation: _headerOpacityAnimationController,
                              builder: (context, child) {
                                return Opacity(
                                  opacity: _headerOpacityAnimation.value,
                                  child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: <Widget>[
                                    const SizedBox(width: 10,),
                                    const Icon(LineIcons.mapMarker, color: Colors.white, size: 50,),
                                    const SizedBox(width: 12,),
                                    Expanded(
                                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
                                        Text('current_location'.tr(), style: const TextStyle(color: Colors.white)),
                                        const SizedBox(height: 2,),
                                        Consumer<SettingsProvider>(
                                          builder: (context, settings, child) {
                                            if (settings.isGettingAddress || settings.address == null) {
                                              return const SizedBox(
                                                width: 50.0,
                                                height: 45.0,
                                                child: SpinKitThreeBounce(color: Colors.white, size: 30.0,),
                                              );
                                            }
                                            return GestureDetector(
                                              onTap: () async {
                                                await Navigator.of(context).pushNamed(ROUTE_MAP);
                                                reInitContext(context);
                                              },
                                              child: SizedBox(
                                                height: 45.0,
                                                child: RichText(text: TextSpan(
                                                  style: Theme.of(context).textTheme.bodyText1,
                                                  children: <TextSpan>[
                                                    TextSpan(text: '${settings.address!.subAdministrativeArea},\n', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white)),
                                                    TextSpan(text: settings.address!.country, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),)
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
                                      shape: const CircleBorder(),
                                      clipBehavior: Clip.antiAlias,
                                      child: IconButton(
                                        highlightColor: Colors.white24,
                                        splashColor: Colors.white24,
                                        padding: const EdgeInsets.all(15),
                                        onPressed: _getAllData,
                                        icon: RotationTransition(
                                          turns: Tween(begin: 0.0, end: 1.0).animate(_spinController),
                                          child: const Icon(LineIcons.syncIcon, color: Colors.white,),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10,),
                                  ],),
                                );
                              }
                            ),
                            Expanded(child: LayoutBuilder(
                              builder: (context, constraints) {
                                return constraints.maxHeight < 80 ? const SizedBox() : Container(
                                  padding: const EdgeInsets.only(top: 10),
                                  width: double.infinity,
                                  height: constraints.maxHeight,
                                  child: Opacity(
                                    opacity: min(1, (constraints.maxHeight - 80) / 100),
                                    child: LineChart(
                                      _getLineChartData(),
                                      swapAnimationDuration: const Duration(milliseconds: 500),
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
                      header: const WaterDropMaterialHeader(color: Colors.white, backgroundColor: APP_UI_COLOR_MAIN),
                      controller: _refreshController,
                      onRefresh: _getAllData,
                      child: SingleChildScrollView(
                        child: AnimatedOpacity(
                          opacity: _isLoading ? 0 : 1,
                          duration: const Duration(milliseconds: 1000),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[

                                  Center(child: Text('current_items'.tr(), textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.teal[200]),),),
                                  const SizedBox(height: 12,),
                                  const CardList(UserNotifType.listingPosted),
                                  const CardList(UserNotifType.broadcastActive),
                                  const CardList(UserNotifType.listingFavorites),
                                  const CardList(UserNotifType.inbox),

                                  const SizedBox(height: SECTION_MARGIN,),

                                  Center(child: Text('current_things'.tr(), textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.teal[200]),),),
                                  const SizedBox(height: 12,),
                                  Wrap(spacing: 8, runSpacing: 8, runAlignment: WrapAlignment.center, children: const <Widget>[
                                    CardBox(UserNotifType.listing),
                                    CardBox(UserNotifType.user),
                                    CardBox(UserNotifType.seeker),
                                  ],),

                                  const SizedBox(height: SECTION_MARGIN,),

                                ],),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),),
                    _isLoading ? Positioned.fill(child: SafeArea(
                      child: AbsorbPointer(
                        child: Center(
                          child: SpinKitChasingDots(
                            color: Colors.teal[300],
                            size: 100,
                          ),
                        ),
                      ),
                    ),) : const SizedBox()
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
  const CardBox(this.notif, {Key? key}) : super(key: key);
  final UserNotifType notif;

  @override
  _CardBoxState createState() => _CardBoxState();
}

class _CardBoxState extends State<CardBox> {
  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final size = (MediaQuery.of(context).size.width - 38) / 2;
    late MenuModel menu;
    int? total;

    switch (widget.notif) {
      case UserNotifType.listing:
        total = settings.notif?.listing;
        menu = MenuModel(
          'notif.listing'.plural(total??1),
          widget.notif,
          total: total,
          icon: LineIcons.mapMarker,
          color: Colors.blue,
          onPressed: () {
            settings.setSettings(isViewFavorites: false);
            u.navigatePage(tabBrowse);
          },
        );
        break;
      case UserNotifType.user:
        total = settings.notif?.user;
        menu = MenuModel(
          'notif.user'.plural(total??1),
          widget.notif,
          total: total,
          icon: LineIcons.users,
          color: Colors.green,
          onPressed: () {
            // TODO list shop near
          },
        );
        break;
      case UserNotifType.seeker:
      default:
        total = settings.notif?.seeker;
        menu = MenuModel(
          'notif.seeker'.plural(total??1),
          widget.notif,
          total: total,
          icon: LineIcons.binoculars,
          color: Colors.orange,
          onPressed: () {
            // TODO list iklan WTB near (card swiper)
          },
        );
        break;
    }

    if ((total??0) == 0 && widget.notif != UserNotifType.listing) return const SizedBox();

    return SizedBox(
      width: size,
      height: size,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(APP_UI_CARD_RADIUS)),
        elevation: APP_UI_CARD_ELEVATION,
        color: menu.color,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: menu.onPressed,
          child: Stack(
            alignment: Alignment.topRight,
            children: [
              Icon(menu.icon, color: Colors.white30, size: 80,),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: FractionalOffset.topLeft,
                    end: FractionalOffset.bottomCenter,
                    colors: [
                      Colors.white.withOpacity(0.0),
                      Colors.white.withOpacity(0.1),
                    ],
                    stops: const [
                      0.0,
                      1.0,
                    ]
                  ),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
                  // TODO check spinkit size
                  total == null ? const SpinKitRipple(color: Colors.white70, size: 50,) : Text(f.formatNumber(total), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 28, color: Colors.white),),
                  Text(menu.label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.white),),
                  const SizedBox(height: 14,),
                  Row(children: <Widget>[
                    Expanded(child: Text('action_more'.tr(), style: const TextStyle(fontSize: 12, color: Colors.white70),)),
                    const SizedBox(width: 8,),
                    const Icon(LineIcons.chevronCircleRight, color: Colors.white70, size: 15,)
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
  const CardList(this.notif, {Key? key}) : super(key: key);
  final UserNotifType notif;

  @override
  _CardListState createState() => _CardListState();
}

class _CardListState extends State<CardList> {
  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    late MenuModel menu;
    int? total;

    switch (widget.notif) {
      case UserNotifType.listingFavorites:
        total = settings.notif?.listingFavorites;
        menu = MenuModel(
          'notif.listing_favorites'.plural(total??1),
          widget.notif,
          total: total,
          icon: LineIcons.shoppingCart,
          color: Colors.pink[300]!,
          additionalValue: "Cek",
          onPressed: () {
            settings.setSettings(isViewFavorites: true);
            u.navigatePage(tabBrowse);
          },
        );
        break;
      case UserNotifType.listingPosted:
        total = settings.notif?.listingPosted;
        menu = MenuModel(
          'notif.listing_posted'.plural(total??1),
          widget.notif,
          total: total,
          icon: total == 0 ? LineIcons.plusCircle : LineIcons.dropbox,
          color: Colors.pink[300]!,
          additionalValue: total == 0 ? "Buat" : "Kelola",
          onPressed: () {
            u.openMyListings();
          },
        );
        break;
      case UserNotifType.broadcastActive:
        total = settings.notif?.broadcastActive;
        menu = MenuModel(
          'notif.broadcast_active'.plural(total??1),
          widget.notif,
          total: total,
          icon: LineIcons.binoculars,
          color: Colors.pink[300]!,
          additionalValue: 'action_view'.tr(),
          onPressed: () {
            // TODO buka kelola pencarian
          },
        );
        break;
      case UserNotifType.inbox:
      default:
        total = settings.notif?.inbox;
        menu = MenuModel(
          'notif.inbox'.tr(),
          widget.notif,
          total: total,
          icon: LineIcons.inbox,
          color: Colors.orange[300]!,
          additionalValue: 'action_check'.tr(),
          onPressed: () {
            // TODO buka kelola pesan
          },
        );
        break;
    }

    total ??= 0;
    if (total == 0 && widget.notif != UserNotifType.listingPosted) return const SizedBox();
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(APP_UI_CARD_RADIUS)),
      elevation: APP_UI_CARD_ELEVATION,
      shadowColor: Colors.grey[300],
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(children: <Widget>[
          const SizedBox(width: 8,),
          Text(f.formatNumber(total), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),),
          const SizedBox(width: 8,),
          Expanded(child: Text(menu.label)),
          MyButton(
            menu.additionalValue,
            size: MyButtonSize.SMALLER,
            color: menu.color,
            icon: menu.icon,
            iconRight: true,
            onPressed: menu.onPressed,
          ),
        ],),
      ),
    );
  }
}

class MyMainHeader extends SliverPersistentHeaderDelegate {
  MyMainHeader(this._widget);
  final Widget _widget;

  @override
  double get minExtent => 105.0;
  @override
  double get maxExtent => 265.0;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: _widget,
    );
  }

  @override
  bool shouldRebuild(MyMainHeader oldDelegate) {
    return false;
  }
}