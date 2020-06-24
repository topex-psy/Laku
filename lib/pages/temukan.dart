import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:line_icons/line_icons.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import '../models/iklan.dart';
import '../utils/api.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../utils/styles.dart' as style;

const ITEM_PER_PAGE = 12;

class Temukan extends StatefulWidget {
  @override
  _TemukanState createState() => _TemukanState();
}

class _TemukanState extends State<Temukan> {
  final _refreshController = RefreshController(initialRefresh: false);
  final _scrollController = ScrollController();
  var _listItem = <IklanModel>[];
  var _page = 1;
  var _keyword = '';
  var _totalAll = 0;

  @override
  void initState() {
    _scrollController.addListener(() {
      double maxScroll = _scrollController.position.maxScrollExtent;
      double currentScroll = _scrollController.position.pixels;
      double delta = 200.0;
      if (maxScroll - currentScroll <= delta) { // load more
        if (_totalAll == _listItem.length) return;
        setState(() { _page++; });
        _getAllData();
      }
    });
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
    print(" ==> GET ALL DATA .................. $_page");
    var listingApi = await api('listing', data: {
      'uid': userSession.uid,
      'mode': 'near',
      'limit': _page * ITEM_PER_PAGE,
      'keyword': _keyword
    });
    if (listingApi.isSuccess) {
      setState(() {
        _listItem = listingApi.result.map((res) => IklanModel.fromJson(res)).toList();
        _totalAll = listingApi.totalAll;
      });
      _refreshController.refreshCompleted();
    } else {
      _refreshController.refreshFailed();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: EdgeInsets.all(10),
        child: Column(
          children: <Widget>[
            Row(children: <Widget>[
              Icon(LineIcons.map_marker),
              SizedBox(width: 4,),
              Expanded(child: Text("${f.formatNumber(_totalAll)} Iklan di dekat Anda", style: style.textLabel),),
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
              child: SmartRefresher(
                enablePullDown: true,
                enablePullUp: false,
                header: WaterDropMaterialHeader(color: Colors.white, backgroundColor: THEME_COLOR),
                controller: _refreshController,
                onRefresh: _getAllData,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  child: StaggeredGridView.countBuilder(
                    physics: NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.all(4),
                    crossAxisCount: 3,
                    // itemCount: min(_listItem.length, ITEM_PER_PAGE * _page),
                    itemCount: _listItem.length,
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}