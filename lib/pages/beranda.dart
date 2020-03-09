import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
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
                  Expanded(child: Text("Halo, Taufik", style: style.textLabel)),
                  SizedBox(width: 12,),
                  IconButton(icon: Icon(LineIcons.home), onPressed: () {
                    // TODO store setup
                  },)
                ],),
                Text("Barang Jualan Anda", style: style.textTitle,),
                SizedBox(height: 20,),
                Text("Anda belum menambahkan barang untuk dijual.", textAlign: TextAlign.start, style: style.textMuted,),
                SizedBox(height: 20,),
                Icon(LineIcons.meh_o, color: Colors.grey, size: 100,),
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