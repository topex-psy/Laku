import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:line_icons/line_icons.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import '../models/iklan.dart';
import '../utils/api.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../utils/styles.dart' as style;

class Temukan extends StatefulWidget {
  @override
  _TemukanState createState() => _TemukanState();
}

class _TemukanState extends State<Temukan> {
  final _refreshController = RefreshController(initialRefresh: false);
  static const ITEM_PER_PAGE = 12;
  var _listItem = <IklanModel>[];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getAllData();
    });
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  _getAllData() async {
    var listingApi = await api('listing', data: { 'uid': userSession.uid, 'mode': 'near' });
    if (listingApi.isSuccess) {
      setState(() {
        _listItem = listingApi.result.map((res) => IklanModel.fromJson(res)).toList();
      });
      _refreshController.refreshCompleted();
    } else {
      _refreshController.refreshFailed();
    }
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
                  itemCount: _listItem.length > ITEM_PER_PAGE ? ITEM_PER_PAGE : _listItem.length,
                  itemBuilder: (context, index) {
                    var item = _listItem[index];
                    return Material(
                      color: Colors.grey[300],
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () {},
                        child: Stack(
                          alignment: Alignment.bottomLeft,
                          children: <Widget>[
                            Semantics(
                              label: "Listing item",
                              value: item.judul,
                              image: true,
                              child: FadeInImage.assetNetwork(
                                placeholder: SETUP_NONE_IMAGE,
                                image: item.foto.first.foto,
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
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
                            SingleChildScrollView(
                              padding: EdgeInsets.all(10),
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: <Widget>[
                                Text(item.judul, style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                Text(item.judulLapak, style: TextStyle(color: Colors.white, fontSize: 11)),
                                // Text(f.distanceLabel(item.jarakMeter), style: TextStyle(color: Colors.white, fontSize: 11)),
                              ],),
                            )
                          ],
                        ),
                      )
                    );
                  },
                  staggeredTileBuilder: (index) => StaggeredTile.count(1, _listItem[index].tier > 1 ? 2 : 1),
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