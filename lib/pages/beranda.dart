import 'dart:async';
import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:geocoder/geocoder.dart';
import 'package:geolocator/geolocator.dart';
import 'package:line_icons/line_icons.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
// import '../extensions/widget.dart';
import '../providers/notifications.dart';
// import '../providers/person.dart';
import '../providers/settings.dart';
import '../utils/constants.dart';
import '../utils/curves.dart';
import '../utils/helpers.dart';
import '../utils/mixins.dart';
import '../utils/styles.dart' as style;
import '../utils/widgets.dart';

const SECTION_MARGIN = 26.0;
const TIMER_INTERVAL_SECONDS = 10;

class Beranda extends StatefulWidget {
  @override
  _BerandaState createState() => _BerandaState();
}

class _BerandaState extends State<Beranda> with MainPageStateMixin, TickerProviderStateMixin {
  final _refreshController = RefreshController(initialRefresh: false);
  final _scrollController = ScrollController();
  AnimationController _spinController;
  var _isFabButton = false;
  var _isGranted = false;
  var _isLoading = true;
  Timer _timer;

  // var _isChartExpand = false;
  // var _isChartButton = true;

  @override
  void onPageVisible() {
    _runTimer();
  }

  @override
  void onPageInvisible() {
    _timer.cancel();
  }

  @override
  void initState() {
    _spinController = AnimationController(
      duration: Duration(milliseconds: 500),
      vsync: this,
    );
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _getMyLocation();
      _runTimer();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _timer.cancel();
    super.dispose();
  }

  _runTimer() {
    _getAllData();
    _timer = Timer.periodic(Duration(seconds: TIMER_INTERVAL_SECONDS), (timer) => _getAllData());
  }

  _getMyLocation() async {
    var isGranted = await Permission.location.request().isGranted;
    if (_isGranted != isGranted) setState(() {
      _isGranted = isGranted;
    });
    if (!isGranted) return;

    final settings = Provider.of<SettingsProvider>(context, listen: false);
    if (settings.isGettingLocation) return;
    settings.setSettings(isGettingLocation: true);
    _spinController.forward();

    print("... GETTING MY LOCATION");
    var address = settings.address;
    try {
      var position = await Geolocator().getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      var coordinates = Coordinates(position.latitude, position.longitude);
      print("... GETTING MY LOCATION result: $coordinates");

      var addresses = await Geocoder.local.findAddressesFromCoordinates(coordinates);
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

    } catch(e) {
      print("... GETTING MY LOCATION error: $e");
    }
    _spinController.reset();
    settings.setSettings(address: address, isGettingLocation: false);
  }

  _getAllData() {
    // print(" ==> GET ALL DATA ..................");
    final notification = Provider.of<NotificationsProvider>(context, listen: false);
    Future.delayed(Duration(milliseconds: 2000), () {
      _refreshController.refreshCompleted();
      // TODO on error
      // _refreshController.refreshFailed();
      notification.setNotif(
        iklanTerpasang: 5,
        pencarianTerpasang: 0,
        pesanMasuk: 2,
        iklan: 29,
        pengguna: 8,
        pencari: 1,
      );
      if (mounted) setState(() {
        _isLoading = false;
      });
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
      barWidth: 7,
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
      barWidth: 6,
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
      barWidth: 8,
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
          textStyle: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 16,),
          margin: 10,
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
                return '1m';
              case 2:
                return '2m';
              case 3:
                return '3m';
              case 4:
                return '5m';
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
    final _mediaQuery = MediaQuery.of(context);

    return !_isGranted ? Container(
      padding: EdgeInsets.all(THEME_PADDING),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Image.asset('images/onboarding/2.png', width: _mediaQuery.size.width * .69,),
          SizedBox(height: 20,),
          Text("Harap izinkan aplikasi untuk mengakses lokasi Anda saat ini.", textAlign: TextAlign.center,),
          SizedBox(height: 20,),
          UiButton("Izinkan", height: style.heightButtonL, color: Colors.teal[300], textStyle: style.textButtonL, icon: LineIcons.check_circle, iconSize: 20, iconRight: true, onPressed: _getMyLocation,),
        ],
      ),
    ) : SafeArea(
      child: NotificationListener<ScrollNotification>(
        onNotification: (scrollNotification) {
          if (scrollNotification is ScrollStartNotification) {
            // if (_isChartButton && !_isChartExpand) setState(() {
            //   _isChartButton = false;
            // });
            if (_isFabButton) setState(() {
              _isFabButton = false;
            });
          } else if (scrollNotification is ScrollUpdateNotification) {
          } else if (scrollNotification is ScrollEndNotification) {
            // if (!_isChartButton && _scrollController.offset <= kToolbarHeight) setState(() {
            //   _isChartButton = true;
            // });
            if (!_isFabButton && _scrollController.offset > kToolbarHeight) setState(() {
              _isFabButton = true;
            });
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
                  IconButton(icon: Icon(LineIcons.bell_o, color: Colors.white,), onPressed: () {},),
                  IconButton(icon: Icon(LineIcons.certificate, color: Colors.white,), onPressed: () {},),
                  SizedBox(width: 8,)
                ],
                backgroundColor: THEME_COLOR,
                expandedHeight: kToolbarHeight,
                floating: false,
                pinned: false,
              ),
              SliverPersistentHeader(
                delegate: _SliverAppBarDelegate(
                  Column(
                    children: [
                      Row(crossAxisAlignment: CrossAxisAlignment.center, children: <Widget>[
                        SizedBox(width: 10,),
                        Icon(LineIcons.map_marker, color: Colors.white, size: 50,),
                        SizedBox(width: 12,),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
                            Text("Kamu berada di:", style: style.textWhite),
                            Consumer<SettingsProvider>(
                              builder: (context, settings, child) {
                                return settings.isGettingLocation || settings.address == null ? Container(
                                  width: 50.0,
                                  height: 46.0,
                                  child: SpinKitThreeBounce(color: Colors.white, size: 30.0,),
                                ) : GestureDetector(
                                  onTap: () async {
                                    final results = await Navigator.of(context).pushNamed(ROUTE_PETA) as Map;
                                    print(results);
                                    // TODO set latest selected radius
                                  },
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
              Container(width: double.infinity, height: 300.0, child: CustomPaint(painter: CurvePainter(color: THEME_COLOR,),),),
              Positioned.fill(child: SmartRefresher(
                enablePullDown: true,
                enablePullUp: false,
                header: WaterDropMaterialHeader(color: Colors.white, backgroundColor: THEME_COLOR,),
                controller: _refreshController,
                onRefresh: _getAllData,
                child: SingleChildScrollView(
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

                          Center(child: Text("Kamu punya:", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.teal[200]),),),
                          SizedBox(height: 12,),
                          CardList('iklanTerpasang'),
                          CardList('pencarianTerpasang'),
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

                          // Container(
                          //   width: double.infinity,
                          //   height: 150,
                          //   child: LineChart(
                          //     _getLineChartData(),
                          //     swapAnimationDuration: Duration(milliseconds: 500),
                          //   ),
                          // ),

                          // SizedBox(height: 100,),

                        ],),
                      ),
                    ],
                  ),
                ),
              ),),
              _isLoading ? Positioned.fill(child: SafeArea(
                child: Container(
                  color: Colors.white,
                  child: Center(child: UiLoader(),),
                ),
              ),) : SizedBox()
            ],
          ),
        ),
      ),
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
    var notification = Provider.of<NotificationsProvider>(context);
    var size = (MediaQuery.of(context).size.width - 38) / 2;
    int angka;
    VoidCallback buka;
    Color color;
    IconData icon;
    String label;

    switch (widget.notif) {
      case 'iklan':
        angka = notification.iklan;
        color = Colors.blue;
        icon = LineIcons.map_marker;
        label = "Iklan";
        buka = () {};
        break;
      case 'pengguna':
        angka = notification.pengguna;
        color = Colors.green;
        icon = LineIcons.users;
        label = "Pengguna";
        buka = () {};
        break;
      case 'pencari':
        angka = notification.pencari;
        color = Colors.orange;
        icon = LineIcons.binoculars;
        label = "Pencari";
        buka = () {};
        break;
    }
    return angka == 0 && widget.notif != 'iklan' ? SizedBox() : SizedBox(
      width: size,
      height: size,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(THEME_CARD_RADIUS)),
        elevation: THEME_CARD_ELEVATION,
        color: color,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: buka,
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
                  Text(f.formatNumber(angka) ?? '-', style: style.textHeadlineXLWhite,),
                  Text(label, style: style.textTitleWhite,),
                  SizedBox(height: 14,),
                  Row(children: <Widget>[
                    Expanded(child: Text("Selengkapnya", style: style.textWhite70S,)),
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
    var notification = Provider.of<NotificationsProvider>(context);
    int angka;
    VoidCallback buka;
    String buttonLabel, label;
    IconData buttonIcon;
    double buttonWidth;
    switch (widget.notif) {
      case 'iklanTerpasang':
        angka = notification.iklanTerpasang;
        label = "Iklan terpasang";
        buttonLabel = angka == 0 ? "Buat" : "Kelola";
        buttonWidth = angka == 0 ? 96 : 110;
        buttonIcon = angka == 0 ? LineIcons.plus_circle : LineIcons.dropbox;
        buka = () {
          // TODO buka kelola iklan
        };
        break;
      case 'pencarianTerpasang':
        angka = notification.pencarianTerpasang;
        label = "Pencarian terpasang";
        buttonLabel = "Lihat";
        buttonWidth = 100;
        buttonIcon = LineIcons.binoculars;
        buka = () {
          // TODO buka kelola pencarian
        };
        break;
      case 'pesanMasuk':
        angka = notification.pesanMasuk;
        label = "Pesan masuk";
        buttonLabel = "Cek";
        buttonWidth = 90;
        buttonIcon = LineIcons.inbox;
        buka = () {
          // TODO buka kelola pesan
        };
        break;
    }
    return angka == 0 && widget.notif != 'iklanTerpasang' ? SizedBox() : Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(THEME_CARD_RADIUS)),
      elevation: THEME_CARD_ELEVATION,
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Row(children: <Widget>[
          SizedBox(width: 8,),
          Text(f.formatNumber(angka) ?? '0', style: style.textHeadline,),
          SizedBox(width: 8,),
          Expanded(child: Text(label)),
          UiButton(
            buttonLabel,
            width: buttonWidth,
            color: Colors.teal[300],
            textStyle: style.textButton,
            icon: buttonIcon,
            iconRight: true,
            onPressed: buka
          ),
        ],),
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._widget);
  final Widget _widget;

  @override
  double get minExtent => 104.0;
  @override
  double get maxExtent => 274.0;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    // double statusBarHeight = MediaQuery.of(context).padding.top;
    return Container(
      decoration: BoxDecoration(
        // border: Border.all(
        //   color: Colors.white,
        //   width: 1.0,
        // ),
        color: THEME_COLOR,
      ),
      child: Padding(
        padding: EdgeInsets.only(top: 20, bottom: 20),
        child: _widget,
      )
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}