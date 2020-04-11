import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:line_icons/line_icons.dart';
import '../utils/styles.dart' as style;

class Iklan {
  Iklan({this.judul, this.pic, this.x, this.y});
  String judul;
  String pic;
  int x;
  int y;

  @override
  String toString() => "Iklan ($x/$y)";
}

class Temukan extends StatefulWidget {
  @override
  _TemukanState createState() => _TemukanState();
}

class _TemukanState extends State<Temukan> {
  static const ITEM_PER_PAGE = 12;
  var _listItem = <Iklan>[];

  @override
  void initState() {
    for (var i = 0; i < ITEM_PER_PAGE; i++) {
      _listItem.add(Iklan(
        judul: 'Test Produk',
        pic: 'https://webimg.secondhandapp.com/w-i-mgl/5db94ce263dfa4255608294a',
        x: 1 + Random().nextInt(2),
        y: 1 + Random().nextInt(2)
      ));
    }
    print("_listItem = $_listItem");
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: OrientationBuilder(builder: (context, orientation) {
        var _isPortrait = orientation == Orientation.portrait;
        return Container(
          padding: EdgeInsets.all(10),
          child: Column(
            children: <Widget>[
              Row(children: <Widget>[
                Icon(LineIcons.map_marker),
                SizedBox(width: 4,),
                Expanded(child: Text("25 Iklan di dekat Anda", style: style.textLabel),),
                SizedBox(width: 12,),
                IconButton(icon: Icon(LineIcons.search), tooltip: "Cari", onPressed: () {},),
                IconButton(icon: Icon(Icons.sort), tooltip: "Urutkan", onPressed: () {},),
              ],),

              // Container(
              //   decoration: BoxDecoration(color: Colors.white, boxShadow: [
              //     BoxShadow(blurRadius: 20, color: Colors.grey[800].withOpacity(1.0))
              //   ]),
              //   child: Row(children: <Widget>[
              //     SizedBox(width: 8,),
              //     Icon(LineIcons.map_marker),
              //     SizedBox(width: 4,),
              //     Expanded(child: Text("25 Produk di dekat Anda", style: style.textLabel),),
              //     IconButton(icon: Icon(LineIcons.search), tooltip: "Cari", onPressed: () {},),
              //     IconButton(icon: Icon(Icons.sort), tooltip: "Urutkan", onPressed: () {},),
              //   ],),
              // ),

              Expanded(
                child: StaggeredGridView.countBuilder(
                  padding: EdgeInsets.all(4),
                  crossAxisCount: _isPortrait ? 3 : 5,
                  itemCount: ITEM_PER_PAGE,
                  itemBuilder: (context, index) {
                    var item = _listItem[index];
                    return Material(
                      color: Colors.grey[300],
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () {},
                        child: Stack(
                          alignment: Alignment.bottomRight,
                          children: <Widget>[
                            Semantics(
                              label: "Foto produk",
                              value: item.judul,
                              image: true,
                              child: Image.asset('images/none.png', height: double.infinity, width: double.infinity, fit: BoxFit.cover,),
                            ),
                            // FadeInImage(
                            //   height: double.infinity,
                            //   width: double.infinity,
                            //   placeholder: AssetImage('images/none.png'),
                            //   image: NetworkImage(item.pic),
                            //   fit: BoxFit.cover,
                            // ),
                            Container(width: double.infinity, height: MediaQuery.of(context).size.width / 6, decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: FractionalOffset.topCenter,
                                end: FractionalOffset.bottomCenter,
                                colors: [
                                  Colors.black.withOpacity(0.0),
                                  Colors.black.withOpacity(1.0),
                                ],
                                stops: [
                                  0.0,
                                  1.0,
                                ]
                              ),
                            ),),
                            Padding(
                              padding: EdgeInsets.all(10),
                              child: Column(crossAxisAlignment: CrossAxisAlignment.end, mainAxisSize: MainAxisSize.min, children: <Widget>[
                                Text("Rp 2.000.000", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                Text("2.0 km", style: TextStyle(color: Colors.white, fontSize: 11)),
                              ],),
                            )
                          ],
                        ),
                      )
                    );
                  },
                  staggeredTileBuilder: (index) {
                    var item = _listItem[index];
                    return StaggeredTile.count(1, item.y);
                  },
                  mainAxisSpacing: 4.0,
                  crossAxisSpacing: 4.0,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}