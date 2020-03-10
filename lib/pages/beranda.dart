import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../utils/styles.dart' as style;
import '../utils/widgets.dart';

class Beranda extends StatefulWidget {
  @override
  _BerandaState createState() => _BerandaState();
}

class _BerandaState extends State<Beranda> {

  @override
  void initState() {
    super.initState();
  }

  Widget _buildCard({
    Color color,
    @required IconData icon,
    @required int angka,
    @required String label,
  }) {
    var size = h.screenSize.width / 2 * 0.8;
    return SizedBox(
      width: size,
      height: size,
      child: Card(color: color ?? THEME_COLOR, child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
          Row(children: <Widget>[
            Expanded(child: Icon(icon, color: Colors.white,)),
            SizedBox(width: 8,),
            Icon(icon ?? LineIcons.arrow_up, color: Colors.white, size: 12,),
            Text("0.5", style: style.textWhiteS,)
          ]),
          SizedBox(height: 8,),
          Text("${f.formatNumber(angka)} $label", style: style.textHeadline,),
          SizedBox(height: 8,),
          Row(children: <Widget>[
            Expanded(child: Text("Selengkapnya", style: style.textWhiteS,)),
            SizedBox(width: 8,),
            Icon(LineIcons.chevron_circle_right, color: Colors.white, size: 12,)
          ],)
        ],),
      ),),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Stack(
        children: <Widget>[
          Positioned.fill(child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Row(children: <Widget>[
                  IconButton(icon: Icon(Icons.sort), onPressed: () {},),
                  Expanded(child: Container(),),
                  IconButton(icon: Icon(LineIcons.bell_o), onPressed: () {},),
                  IconButton(icon: Icon(LineIcons.certificate, color: THEME_COLOR,), onPressed: () {},),
                ],),

                SizedBox(height: 30,),

                Column(children: <Widget>[
                  Text("Di sekitarmu ada:", style: style.textMuted),
                  Text("${f.formatNumber(29)} Produk", style: style.textHeadline),
                ],),

                SizedBox(height: 30,),

                Text("Kamu punya:", style: style.textMuted),
                SizedBox(height: 8,),
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 4,
                  child: Row(children: <Widget>[
                    Text("${f.formatNumber(8)}", style: style.textHeadline),
                    SizedBox(width: 8,),
                    Expanded(child: Text("Produk terpasang")),
                    SizedBox(width: 100, height: style.heightButton, child: UiButton(label: "Kelola", color: Colors.teal[300], textStyle: style.textButton, icon: LineIcons.dropbox, iconRight: true, onPressed: () {
                      // TODO buka kelola iklan
                    }),),
                  ],),
                ),

                SizedBox(height: 30,),

                Text("Di sekitarmu ada:", style: style.textLabel),
                SizedBox(height: 12,),
                Wrap(spacing: 8, runSpacing: 8, runAlignment: WrapAlignment.center, children: <Widget>[
                  _buildCard(color: Colors.blue, angka: 29, icon: LineIcons.map_marker, label: "Produk"),
                  _buildCard(color: Colors.green, angka: 8, icon: LineIcons.users, label: "Pengguna"),
                ],),

                Text("Pesan masuk:", style: style.textLabel),
                SizedBox(height: 12,),

                Card(child: ListView.separated(
                  separatorBuilder: (context, index) => Divider(),
                  itemCount: 3,
                  itemBuilder: (context, index) {
                    return Container(
                      padding: EdgeInsets.all(20),
                      child: Row(children: <Widget>[
                        CircleAvatar(),
                        SizedBox(width: 8,),
                        Expanded(child: Column(children: <Widget>[
                          Row(children: <Widget>[
                            Text("Nama Orang", style: style.textLabel),
                            SizedBox(width: 12,),
                            Expanded(child: Text("2 hari lalu", style: style.textMutedS,),)
                          ],),
                          Text("Halo", style: style.textMuted),
                        ],),)
                      ],)
                    );
                  }
                ),)


                // Row(children: <Widget>[
                //   Expanded(child: Text("Halo, Taufik", style: style.textLabel)),
                //   SizedBox(width: 12,),
                //   IconButton(icon: Icon(LineIcons.home), onPressed: () {
                //     // TODO store setup
                //   },)
                // ],),
                
                // Text("Barang Jualan Anda", style: style.textTitle,),
                // SizedBox(height: 20,),
                // Text("Anda belum menambahkan barang untuk dijual.", textAlign: TextAlign.start, style: style.textMuted,),
                // SizedBox(height: 20,),
                // Icon(LineIcons.meh_o, color: Colors.grey, size: 100,),

              ],
            ),
          ),),
          Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: EdgeInsets.only(left: 12, bottom: 12),
              child: Material(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                color: Colors.teal.withOpacity(0.3),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
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
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    child: Text("Terdapat 29 pengguna di radius Anda.", style: TextStyle(fontSize: 11),),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}