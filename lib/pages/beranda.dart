import 'dart:async';

import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import '../models/report.dart';
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
      // TODO load gps status
      _runTimer();
    });
  }

  _runTimer() {
    _getAllData();
    _timer = Timer.periodic(Duration(seconds: TIMER_INTERVAL_SECONDS), (timer) {
      _getAllData();
    });
  }

  Widget _buildCardList({
    @required String label,
    @required String buttonLabel,
    @required IconData buttonIcon,
    @required String notif
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(THEME_CARD_RADIUS)),
      elevation: THEME_CARD_ELEVATION,
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Row(children: <Widget>[
          SizedBox(width: 8,),
          Consumer<ReportModel>(builder: (context, report, widget) {
            var angka;
            switch (notif) {
              case 'iklanTerpasang': angka = report.iklanTerpasang; break;
              case 'pesanMasuk': angka = report.pesanMasuk; break;
            }
            return Text(f.formatNumber(angka) ?? '-', style: style.textHeadline,);
          },),
          SizedBox(width: 8,),
          Expanded(child: Text(label)),
          SizedBox(width: 100, height: style.heightButton, child: UiButton(label: buttonLabel, color: Colors.teal[300], textStyle: style.textButton, icon: buttonIcon, iconRight: true, onPressed: () {
            // TODO buka kelola iklan
          }),),
        ],),
      ),
    );
  }
  
  Widget _buildCardBox({
    Color color,
    @required IconData icon,
    @required String notif,
    @required String label,
  }) {
    var size = (h.screenSize.width - 38) / 2;
    return SizedBox(
      width: size,
      height: size,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(THEME_CARD_RADIUS)),
        elevation: THEME_CARD_ELEVATION,
        color: color ?? THEME_COLOR,
        clipBehavior: Clip.antiAlias,
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
            Consumer<ReportModel>(builder: (context, report, widget) {
              var angka;
              switch (notif) {
                case 'iklan': angka = report.iklan; break;
                case 'pengguna': angka = report.pengguna; break;
                case 'pencari': angka = report.pencari; break;
              }
              return Text(f.formatNumber(angka) ?? '-', style: style.textHeadlineXLWhite,);
            },),
            Text("$label", style: style.textTitleWhite,),
            SizedBox(height: 14,),
            Row(children: <Widget>[
              Expanded(child: Text("Selengkapnya", style: style.textWhite70S,)),
              SizedBox(width: 8,),
              Icon(LineIcons.chevron_circle_right, color: Colors.white70, size: 12,)
            ],)
          ],),
        ),
      ),
    );
  }

  _getAllData() {
    print(" ==> GET ALL DATA ..................");
    Future.delayed(Duration(milliseconds: 2000), () {
      _refreshController.refreshCompleted();
      // TODO on error
      // _refreshController.refreshFailed();
      setState(() {
        _isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Stack(
        children: <Widget>[
          Positioned.fill(child: CustomPaint(painter: CurvePainter(
            color: THEME_COLOR,
          ),),),
          Positioned.fill(child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                  child: Row(children: <Widget>[
                    IconButton(icon: Icon(Icons.sort, color: Colors.white,), onPressed: () {},),
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
                      _buildCardList(label: "Iklan terpasang", notif: 'iklanTerpasang', buttonLabel: "Kelola", buttonIcon: LineIcons.dropbox),
                      _buildCardList(label: "Pesan masuk", notif: 'pesanMasuk', buttonLabel: "Cek", buttonIcon: LineIcons.inbox),

                      SizedBox(height: SECTION_MARGIN,),

                      Text("Di sekitarmu ada:", style: style.textLabel),
                      SizedBox(height: 12,),
                      Wrap(spacing: 8, runSpacing: 8, runAlignment: WrapAlignment.center, children: <Widget>[
                        _buildCardBox(color: Colors.blue, notif: 'iklan', icon: LineIcons.map_marker, label: "Iklan"),
                        _buildCardBox(color: Colors.green, notif: 'pengguna', icon: LineIcons.users, label: "Pengguna"),
                        _buildCardBox(color: Colors.orange, notif: 'pencari', icon: LineIcons.binoculars, label: "Pencari"),
                      ],),

                      SizedBox(height: SECTION_MARGIN,),

                      Text("Ingin jangkauan lebih luas?", style: style.textLabel),
                      SizedBox(height: 12,),

                      SizedBox(width: 200, height: style.heightButton, child: UiButton(label: "Upgrade akunmu", color: Colors.teal[300], textStyle: style.textButton, icon: LineIcons.certificate, iconRight: true, onPressed: () {
                        // TODO upgrade akun
                      }),),

                      SizedBox(height: SECTION_MARGIN,),

                      // Card(child: ListView.separated(
                      //   physics: NeverScrollableScrollPhysics(),
                      //   separatorBuilder: (context, index) => Divider(),
                      //   itemCount: 3,
                      //   itemBuilder: (context, index) {
                      //     return Container(
                      //       padding: EdgeInsets.all(20),
                      //       child: Row(children: <Widget>[
                      //         CircleAvatar(),
                      //         SizedBox(width: 8,),
                      //         Expanded(child: Column(children: <Widget>[
                      //           Row(children: <Widget>[
                      //             Text("Nama Orang", style: style.textLabel),
                      //             SizedBox(width: 12,),
                      //             Expanded(child: Text("2 hari lalu", style: style.textMutedS,),)
                      //           ],),
                      //           Text("Halo", style: style.textMuted),
                      //         ],),)
                      //       ],)
                      //     );
                      //   }
                      // ),)
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