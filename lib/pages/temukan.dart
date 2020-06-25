import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:debounce_throttle/debounce_throttle.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:laku/utils/widgets.dart';
import 'package:line_icons/line_icons.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import '../models/iklan.dart';
import '../utils/api.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
// import '../utils/styles.dart' as style;

const ITEM_PER_PAGE = 12;
const ITEM_PER_ROW = 2;

class Temukan extends StatefulWidget {
  @override
  _TemukanState createState() => _TemukanState();
}

class _TemukanState extends State<Temukan> {

  final _refreshController = RefreshController(initialRefresh: false);
  final _scrollController = ScrollController();
  final _searchDebouncer = Debouncer<String>(Duration(milliseconds: 1000));
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();

  var _listItem = <IklanModel>[];
  var _listItemFiltered = <IklanModel>[];
  // var _page = 1;
  var _totalAll = 0;
  var _isGettingData = true;

  @override
  void initState() {
    _searchController.addListener(() {
      var keyword = _searchController.text;
      setState(() {
        _listItemFiltered = _listItem.where((item) => item.judul.toLowerCase().contains(keyword.toLowerCase())).toList();
      });
      _searchDebouncer.value = keyword;
    });
    _searchDebouncer.values.listen((keyword) {
      _getAllData();
    });
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
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  _getAllData() async {
    var keyword = _searchController.text;
    print(" ==> GET ALL DATA .................. $keyword");
    setState(() {
      _isGettingData = true;
    });
    var listingApi = await api('listing', data: {
      'uid': userSession.uid,
      'mode': 'near',
      // 'limit': _page * ITEM_PER_PAGE,
      'keyword': keyword
    });
    setState(() {
      _isGettingData = false;
    });
    if (listingApi.isSuccess) {
      setState(() {
        _listItem = listingApi.result.map((res) => IklanModel.fromJson(res)).toList();
        _listItemFiltered = _listItem;
        _totalAll = listingApi.meta['TOTAL_ALL'];
      });
      _refreshController.refreshCompleted();
    } else {
      _refreshController.refreshFailed();
    }
  }

  Widget _buildListingItem(int index) {
    var item = _listItemFiltered[index];
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
                Row(
                  children: <Widget>[
                    Icon(LineIcons.map_marker, color: Colors.white, size: 13,),
                    SizedBox(width: 4,),
                    Text(f.distanceLabel(item.jarakMeter), style: TextStyle(color: Colors.white, fontSize: 11)),
                  ],
                ),
              ],),
            )
          ],
        ),
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: <Widget>[
          // Row(children: <Widget>[
          //   Icon(LineIcons.map_marker),
          //   SizedBox(width: 4,),
          //   Expanded(child: Text("${f.formatNumber(_totalAll)} Iklan di dekat Anda", style: style.textLabel),),
          //   SizedBox(width: 12,),
          //   IconButton(icon: Icon(LineIcons.search), tooltip: "Cari", onPressed: () {},),
          //   IconButton(icon: Icon(Icons.sort), tooltip: "Urutkan", onPressed: () {},),
          // ],),

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

          Padding(
            padding: EdgeInsets.only(left: 15, right: 15, top: 15, bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Expanded(child: UiInput('prompt_search_listing'.tr(), showLabel: false, icon: LineIcons.search, type: UiInputType.SEARCH, controller: _searchController, focusNode: _searchFocusNode,)),
                SizedBox(width: 8,),
                IconButton(icon: Icon(Icons.sort), color: Colors.grey[900], tooltip: 'prompt_sort'.tr(), onPressed: () {},),
              ],
            ),
          ),

          Expanded(
            child: StaggeredGridView.countBuilder(
              // physics: NeverScrollableScrollPhysics(),
              padding: EdgeInsets.all(15),
              crossAxisCount: ITEM_PER_ROW,
              itemCount: _listItemFiltered.length + 1, // add loader
              itemBuilder: (context, index) {
                var isLast = index == _listItemFiltered.length;
                // loader
                if (isLast) return Padding(
                  padding: EdgeInsets.only(top: 8.0),
                  child: Center(child: Opacity(
                    opacity: _isGettingData ? 1 : 0,
                    child: SpinKitChasingDots(color: Colors.white70, size: 50,),
                  ),),
                );
                // item
                return _buildListingItem(index);
              },
              staggeredTileBuilder: (index) {
                var isLast = index == _listItemFiltered.length;
                return isLast
                  ? StaggeredTile.count(ITEM_PER_ROW, 1)
                  : StaggeredTile.count(1, _listItemFiltered[index].tier > 1 ? 2 : 1);
              },
              mainAxisSpacing: 4.0,
              crossAxisSpacing: 4.0,
            ),
          ),
        ],
      ),
    );
  }
}