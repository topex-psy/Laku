import 'dart:async';

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
  var _isGranted = false;
  var _isGPSOn = true;
  var _isLoading = true;
  Timer _timer;

  var _isGettingLocation = false;
  Address _address;

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
      _scrollController.addListener(() {
        print("_scrollController.offset = ${_scrollController.offset}");
        // Provider.of<SettingsProvider>(context, listen: false).scrollPosition = _scrollController.offset;
      });
      // TODO load gps status
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

    if (_isGettingLocation) return;
    setState(() {
      _isGettingLocation = true;
    });
    _spinController.forward();

    print("... GETTING MY LOCATION");
    var address = _address;
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
    setState(() {
      _address = address;
      _isGettingLocation = false;
    });
  }

  _getAllData() {
    print(" ==> GET ALL DATA ..................");
    var notification = Provider.of<NotificationsProvider>(context, listen: false);
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

  @override
  Widget build(BuildContext context) {
    // var _scrollPosition = _scrollController.offset;
    final imageWidth = MediaQuery.of(context).size.width * 0.69;

    return !_isGranted ? Container(
      padding: EdgeInsets.all(THEME_PADDING),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Image.asset('images/onboarding/2.png', width: imageWidth,),
          SizedBox(height: 20,),
          Text("Harap izinkan aplikasi untuk mengakses lokasi Anda saat ini.", textAlign: TextAlign.center,),
          SizedBox(height: 20,),
          UiButton("Izinkan", height: style.heightButtonL, color: Colors.teal[300], textStyle: style.textButtonL, icon: LineIcons.check_circle, iconSize: 20, iconRight: true, onPressed: _getMyLocation,),
        ],
      ),
    ) : Container(
      child: Stack(
        alignment: Alignment.topCenter,
        children: <Widget>[
          // Selector<SettingsProvider, double>(
          //   selector: (buildContext, settings) => settings.scrollPosition,
          //   builder: (context, scrollPosition, child) {
          //     return Container(width: double.infinity, height: 320.0, child: CustomPaint(painter: CurvePainter(color: THEME_COLOR,),),);
          //   }
          // ),
          Container(width: double.infinity, height: 320.0, child: CustomPaint(painter: CurvePainter(color: THEME_COLOR,),),),
          Positioned.fill(child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                  child: Row(children: <Widget>[
                    IconButton(icon: Icon(Icons.sort, color: Colors.white,), onPressed: () {
                      screenScaffoldKey.currentState.openEndDrawer();
                    },),
                    Spacer(),
                    IconButton(icon: Icon(LineIcons.bell_o, color: Colors.white,), onPressed: () {},),
                    IconButton(icon: Icon(LineIcons.certificate, color: Colors.white,), onPressed: () {},),
                  ],),
                ),

                Expanded(child: SmartRefresher(
                  enablePullDown: true,
                  enablePullUp: false,
                  header: WaterDropMaterialHeader(color: Colors.white, backgroundColor: THEME_COLOR,),
                  controller: _refreshController,
                  onRefresh: _getAllData,
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                      Row(children: <Widget>[
                        Icon(LineIcons.map_marker, color: _isGPSOn ? Colors.white : Colors.white54, size: 50,),
                        SizedBox(width: 12,),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                            Text("Kamu berada di:", style: style.textWhite),
                            _isGettingLocation || _address == null ? Container(
                              width: 50.0,
                              height: 46.0,
                              child: SpinKitThreeBounce(
                                color: Colors.white,
                                size: 30.0,
                              ),
                            )
                            : GestureDetector(
                              onTap: () async {
                                final results = await Navigator.of(context).pushNamed(ROUTE_PETA, arguments: { 'address': _address, 'radius': 10000 }) as Map;
                                print(results);
                                // TODO set latest selected radius
                              },
                              child: Container(
                                height: 46.0,
                                child: RichText(text: TextSpan(
                                  style: Theme.of(context).textTheme.bodyText1,
                                  children: <TextSpan>[
                                    TextSpan(text: '${_address.subAdminArea},\n', style: style.textHeadlineWhite),
                                    TextSpan(text: _address.countryName, style: style.textTitleWhite,)
                                  ],
                                ),),
                              ),
                            ),
                          ],),
                        ),
                        // SizedBox(width: 12,),
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
                      ],),

                      SizedBox(height: SECTION_MARGIN,),

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

                      // Text("Ingin jangkauan lebih luas?", style: style.textLabel),
                      // SizedBox(height: 12,),
                      // UiButton("Upgrade akunmu", width: 200, color: Colors.teal[300], textStyle: style.textButton, icon: LineIcons.certificate, iconRight: true, onPressed: () {
                      //   // TODO upgrade akun
                      // }),

                      // SizedBox(height: SECTION_MARGIN,),
                    ],),
                  ),
                ),),
              ],
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