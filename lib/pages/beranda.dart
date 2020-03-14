import 'dart:async';

import 'package:flutter/material.dart';
import 'package:laku/providers/settings.dart';
import 'package:line_icons/line_icons.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import '../extensions/widget.dart';
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

class _BerandaState extends State<Beranda> with MainPageStateMixin {
  final _refreshController = RefreshController(initialRefresh: false);
  final _scrollController = ScrollController();
  var _isGPSOn = true;
  var _isLoading = true;
  Timer _timer;

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
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.addListener(() {
        print("_scrollController.offset = ${_scrollController.offset}");
        Provider.of<SettingsProvider>(context, listen: false).scrollPosition = _scrollController.offset;
      });
      // TODO load gps status
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
    return Container(
      child: Stack(
        alignment: Alignment.topCenter,
        children: <Widget>[
          Selector<SettingsProvider, double>(
            selector: (buildContext, settings) => settings.scrollPosition,
            builder: (context, scrollPosition, child) {
              return Container(width: double.infinity, height: 320.0, child: CustomPaint(painter: CurvePainter(color: THEME_COLOR,),),);
            }
          ),
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
                    Expanded(child: Container(),),
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
                      SizedBox(height: 10,),
                      Row(children: <Widget>[
                        Icon(LineIcons.map_marker, color: _isGPSOn ? Colors.white : Colors.white54, size: 50,),
                        SizedBox(width: 12,),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                            Text("Kamu berada di:", style: style.textWhite),
                            GestureDetector(
                              onTap: () {
                                h.showAlert(title: "Radius Anda", showButton: false, body: Column(crossAxisAlignment: CrossAxisAlignment.center, children: <Widget>[
                                  Text("Radius Anda saat ini adalah:", textAlign: TextAlign.center,),
                                  SizedBox(height: 12,),
                                  Text("5 KM", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 40,),),
                                  SizedBox(height: 12,),
                                  Text("Artinya, barang-barang Anda hanya bisa ditemukan oleh pengguna yang berada di radius tersebut.", textAlign: TextAlign.center, style: TextStyle(fontSize: 12),),
                                  SizedBox(height: 15,),
                                  SizedBox(height: style.heightButton, child: UiButton(color: Colors.blue, label: "Upgrade Akun", icon: LineIcons.user_plus, onPressed: () {
                                    // TODO upgrade akun
                                  }))
                                ],));
                              },
                              child: Text("Malang, Indonesia", style: style.textHeadlineWhite),
                            ),
                          ],),
                        ),
                        SizedBox(width: 12,),
                        IconButton(icon: Icon(LineIcons.refresh, color: Colors.white,), onPressed: () {
                          // TODO reload location
                        },),
                      ],),

                      SizedBox(height: SECTION_MARGIN,),

                      Text("Kamu punya:", style: style.textLabelWhite),
                      SizedBox(height: 8,),
                      CardList('iklanTerpasang'),
                      CardList('pencarianTerpasang'),
                      CardList('pesanMasuk'),

                      SizedBox(height: SECTION_MARGIN,),

                      Text("Di sekitarmu ada:", style: style.textLabel),
                      SizedBox(height: 12,),
                      Wrap(spacing: 8, runSpacing: 8, runAlignment: WrapAlignment.center, children: <Widget>[
                        CardBox('iklan'),
                        CardBox('pengguna'),
                        CardBox('pencari'),
                      ],),

                      SizedBox(height: SECTION_MARGIN,),

                      Text("Ingin jangkauan lebih luas?", style: style.textLabel),
                      SizedBox(height: 12,),
                      SizedBox(width: 200, height: style.heightButton, child: UiButton(label: "Upgrade akunmu", color: Colors.teal[300], textStyle: style.textButton, icon: LineIcons.certificate, iconRight: true, onPressed: () {
                        // TODO upgrade akun
                      }),),

                      SizedBox(height: SECTION_MARGIN,),
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
    var size = (h.screenSize.width - 38) / 2;
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
          child: Container(
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
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
              Row(children: <Widget>[
                Icon(icon, color: Colors.white, size: 18,),
                // Container(
                //   width: 30,
                //   height: 30,
                //   decoration: BoxDecoration(
                //     border: Border.all(
                //       color: Colors.white54,
                //       width: 1.0,
                //     ),
                //     borderRadius: BorderRadius.circular(50),
                //   ),
                //   child: Center(child: Icon(icon, color: Colors.white, size: 18,))
                // ),
                Expanded(child: Container(),),
                SizedBox(width: 8,),
                Icon(LineIcons.arrow_up, color: Colors.white, size: 12,),
                SizedBox(width: 4,),
                Text("0.5", style: style.textWhiteS,)
              ]),
              SizedBox(height: 8,),
              Text(f.formatNumber(angka) ?? '-', style: style.textHeadlineXLWhite,),
              Text(label, style: style.textTitleWhite,),
              SizedBox(height: 14,),
              Row(children: <Widget>[
                Expanded(child: Text("Selengkapnya", style: style.textWhite70S,)),
                SizedBox(width: 8,),
                Icon(LineIcons.chevron_circle_right, color: Colors.white70, size: 12,)
              ],)
            ],),
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
    var buttonShimmer = false;
    switch (widget.notif) {
      case 'iklanTerpasang':
        angka = notification.iklanTerpasang;
        label = "Iklan terpasang";
        buttonLabel = angka == 0 ? "Buat" : "Kelola";
        buttonWidth = angka == 0 ? 96 : 100;
        buttonIcon = angka == 0 ? LineIcons.plus_circle : LineIcons.dropbox;
        // buttonShimmer = angka == 0;
        buka = () {
          // TODO buka kelola iklan
        };
        break;
      case 'pencarianTerpasang':
        angka = notification.pencarianTerpasang;
        label = "Pencarian terpasang";
        buttonLabel = "Lihat";
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
          Text(f.formatNumber(angka) ?? '-', style: style.textHeadline,),
          SizedBox(width: 8,),
          Expanded(child: Text(label)),
          SizedBox(width: buttonWidth, height: style.heightButton, child: UiButton(label: buttonLabel, color: Colors.teal[300], textStyle: style.textButton, icon: buttonIcon, iconRight: true, onPressed: buka).shimmerIt(buttonShimmer, 1.0),),
        ],),
      ),
    );
  }
}