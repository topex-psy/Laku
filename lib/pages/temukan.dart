import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:debounce_throttle/debounce_throttle.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:laku/utils/widgets.dart';
import 'package:line_icons/line_icons.dart';
import '../models/iklan.dart';
import '../utils/api.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../utils/mixins.dart';

const ITEM_PER_PAGE = 12;
const ITEM_PER_ROW = 2;

class Temukan extends StatefulWidget {
  @override
  _TemukanState createState() => _TemukanState();
}

class _TemukanState extends State<Temukan> with MainPageStateMixin, TickerProviderStateMixin {

  final _scrollController = ScrollController();
  final _searchDebouncer = Debouncer<String>(Duration(milliseconds: 1000));
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();

  var _listItem = <IklanModel>[];
  var _listItemFiltered = <IklanModel>[];
  var _page = 1;
  var _total = 0;
  var _isGettingData = false;
  var _isToolbarVisible = true;
  var _lastKeyword = 'none';
  var _lastScrollPixel = 0.0;

  AnimationController _animationController;
  Animation _animation;

  @override
  void onPageVisible() {
    print(" -> onPageVisible TEMUKAN");
  }

  @override
  void onPageInvisible() {
    print(" -> onPageInvisible TEMUKAN");
  }

  @override
  void initState() {
    _animationController = AnimationController(duration: Duration(milliseconds: 500), vsync: this);
    _animation = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.ease
    ));
    _searchController.addListener(() {
      var keyword = _searchController.text ?? '';
      setState(() {
        _listItemFiltered = keyword.isNotEmpty
          ? _listItem.where((item) => item.judul.toLowerCase().contains(keyword.toLowerCase())).toList()
          : _listItem;
      });
      _searchDebouncer.value = keyword;
    });
    _searchDebouncer.values.listen((keyword) {
      _getAllData();
    });
    _scrollController.addListener(() {
      var maxScroll = _scrollController.position.maxScrollExtent;
      var currentScroll = _scrollController.position.pixels;
      if (currentScroll > maxScroll - 100) {
        var limit = _page * ITEM_PER_PAGE;
        print(" ... load more item: $limit < $_total");
        if (limit < _total) { // load more
          _page++;
          _getAllData();
        }
      }
      if (currentScroll > 70) {
        if (_lastScrollPixel > currentScroll) _showToolbar(); else _hideToolbar();
      } else {
        _showToolbar();
      }
      _lastScrollPixel = currentScroll;
    });
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getAllData();
    });
  }

  _showToolbar() {
    if (!_isToolbarVisible) {
      _isToolbarVisible = true;
      _animationController.reverse();
    }
  }

  _hideToolbar() {
    if (_isToolbarVisible) {
      _isToolbarVisible = false;
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  _getAllData() async {
    if (_isGettingData) return;
    var keyword = _searchController.text ?? '';
    var limit = _page * ITEM_PER_PAGE;
    print(" ==> GET TEMUKAN DATA .................. $keyword ($limit)");
    setState(() {
      _isGettingData = true;
    });
    var listingApi = await api('listing', data: {
      'uid': userSession.uid,
      'mode': 'near',
      'limit': limit,
      'keyword': keyword
    });
    setState(() {
      _isGettingData = false;
    });
    if (listingApi.isSuccess) {
      if (_lastKeyword == listingApi.meta['KEYWORD']) return;
      _lastKeyword = listingApi.meta['KEYWORD'];
      setState(() {
        _listItem = listingApi.result.map((res) => IklanModel.fromJson(res)).toList();
        _listItemFiltered = _listItem;
        _total = listingApi.meta['TOTAL_SEARCH'];
      });
    }
  }

  Widget _buildListingItem(int index) {
    var item = _listItemFiltered[index];
    return Card(
      color: Colors.grey[300],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
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
          ),
          InkWell(
            splashColor: Colors.grey.withOpacity(0.2),
            highlightColor: Colors.grey.withOpacity(0.2),
            onTap: () {
              print("tap iklan: ${item.id}");
            },
            child: Container()
          ),
        ],
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    var _toolbarHeight = THEME_INPUT_HEIGHT + 32;
    return SafeArea(
      child: Stack(
        alignment: Alignment.topCenter,
        children: <Widget>[

          Container(
            child: StaggeredGridView.countBuilder(
              controller: _scrollController,
              padding: EdgeInsets.only(left: 15, right: 15, bottom: 15, top: _toolbarHeight),
              crossAxisCount: ITEM_PER_ROW, // TODO responsive based on resolution
              itemCount: _listItemFiltered.length + 1, // add loader
              itemBuilder: (context, index) {
                var isLast = index == _listItemFiltered.length;
                // loader
                if (isLast) return Padding(
                  padding: EdgeInsets.only(top: 8.0),
                  child: Center(child: AnimatedOpacity(
                    duration: Duration(milliseconds: 1000),
                    child: SpinKitChasingDots(color: THEME_COLOR, size: 50,),
                    opacity: _isGettingData ? 1 : 0,
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
              mainAxisSpacing: 8.0,
              crossAxisSpacing: 8.0,
            ),
          ),

          AnimatedBuilder(
            animation: _animationController, builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, -_toolbarHeight * _animation.value),
                child: Container(
                  height: _toolbarHeight,
                  child: Material(
                    color: THEME_BACKGROUND,
                    elevation: 0,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        Expanded(child: UiInput('prompt_search_listing'.tr(), margin: EdgeInsets.only(left: 15, top: 15), showLabel: false, icon: LineIcons.search, type: UiInputType.SEARCH, controller: _searchController, focusNode: _searchFocusNode,)),
                        SizedBox(width: 8,),
                        IconButton(
                          padding: EdgeInsets.zero,
                          icon: Icon(Icons.sort),
                          color: Colors.grey[850],
                          tooltip: 'prompt_sort'.tr(),
                          onPressed: () {},
                        ),
                        SizedBox(width: 8,),
                      ],
                    ),
                  ),
                ),
              );
            }
          ),
        ],
      ),
    );
  }
}