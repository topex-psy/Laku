import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:collection/collection.dart';
import 'package:debounce_throttle/debounce_throttle.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flip_card/flip_card.dart';
import 'package:line_icons/line_icons.dart';
import 'package:provider/provider.dart';
import '../../extensions/widget.dart';
import '../../utils/api.dart';
import '../../utils/constants.dart';
import '../../utils/models.dart';
import '../../utils/providers.dart';
import '../../utils/variables.dart';
import '../../utils/widgets.dart';

const ITEM_PER_PAGE = 12;
const ITEM_PER_ROW = 2;

class BrowsePage extends StatefulWidget {
  const BrowsePage({Key? key, this.isOpen = false}) : super(key: key);
  final bool isOpen;

  @override
  _BrowsePageState createState() => _BrowsePageState();
}

class _BrowsePageState extends State<BrowsePage> with TickerProviderStateMixin {

  final _scrollController = ScrollController();
  final _searchDebouncer = Debouncer<String>(const Duration(milliseconds: 1000), initialValue: '');
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();

  var _listItem = <ListingModel>[];
  var _listItemFiltered = <ListingModel>[];
  var _page = 1;
  var _total = 0;
  var _isGettingData = false;
  var _isToolbarVisible = true;
  var _lastParam = <String, dynamic>{};
  var _lastScrollPixel = 0.0;
  var _filterValues = <String, dynamic>{};

  late AnimationController _animationController;
  late Animation _animation;

  @override
  void initState() {
    _animationController = AnimationController(duration: const Duration(milliseconds: 500), vsync: this);
    _animation = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.ease
    ));
    _searchController.addListener(() {
      var keyword = _searchController.text;
      setState(() {
        _listItemFiltered = keyword.isNotEmpty
          ? _listItem.where((item) => item.title.toLowerCase().contains(keyword.toLowerCase())).toList()
          : _listItem;
      });
      _searchDebouncer.value = keyword;
    });
    _searchDebouncer.values.listen((keyword) => _getAllData());
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
        if (_lastScrollPixel > currentScroll) {
          _showToolbar();
        } else {
          _hideToolbar();
        }
      } else {
        _showToolbar();
      }
      _lastScrollPixel = currentScroll;
    });
    super.initState();
  }

  @override
  void didUpdateWidget(BrowsePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance?.addPostFrameCallback((_) {
      if (!oldWidget.isOpen && widget.isOpen) {
        _getAllData(true);
      }
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

  _getAllData([bool force = false]) async {
    if (_isGettingData) return;
    var keyword = _searchController.text;
    var limit = _page * ITEM_PER_PAGE;
    setState(() {
      _isGettingData = true;
    });
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final listingParams = <String, String>{
      'id': session!.id.toString(),
      'mode': settings.isViewFavorites ? 'fav' : 'near',
      'limit': limit.toString(),
      'keyword': keyword,
    };
    final listingResult = await ApiProvider(context).api('listing', method: "get", withLog: true, getParams: listingParams);
    setState(() {
      _isGettingData = false;
    });
    if (listingResult.isSuccess) {
      if (!force && const MapEquality().equals(_lastParam, listingParams)) return;
      _lastParam = listingParams;
      setState(() {
        _listItem = listingResult.data.map((res) => ListingModel.fromJson(res)).toList();
        _listItemFiltered = _listItem;
        _total = listingResult.totalAll;
      });
    }
  }

  Widget _buildListingItem(int index) {
    var item = _listItemFiltered[index];
    var card = Card(
      color: Colors.grey[300],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: Stack(
        alignment: Alignment.bottomLeft,
        children: <Widget>[
          Semantics(
            label: "Listing item",
            value: item.title,
            image: true,
            child: Hero(
              tag: "listing_${item.id}_0",
              child: FadeInImage.assetNetwork(
                placeholder: DEFAULT_NONE_PIC_ASSET,
                image: item.images.first,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ),
          item.isNear ? Container() : Container(color: Colors.grey.withOpacity(.5),),
          Container(width: double.infinity, height: MediaQuery.of(context).size.width / 6, decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: FractionalOffset.topCenter,
              end: FractionalOffset.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.0),
                Colors.black.withOpacity(1.0),
              ],
              stops: const [
                0.0,
                1.0,
              ]
            ),
          ),),
          SingleChildScrollView(
            padding: const EdgeInsets.all(10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: <Widget>[
              Text(item.title, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              Text(item.owner.name, style: const TextStyle(color: Colors.white, fontSize: 11)),
              Row(
                children: <Widget>[
                  const Icon(LineIcons.mapMarker, color: Colors.white, size: 13,),
                  const SizedBox(width: 4,),
                  Text(f!.formatDistance(item.distanceMeter), style: const TextStyle(color: Colors.white, fontSize: 11)),
                ],
              ),
            ],),
          ),
          InkWell(
            splashColor: Colors.grey.withOpacity(0.2),
            highlightColor: Colors.grey.withOpacity(0.2),
            onTap: () async {
              await Navigator.of(context).pushNamed(ROUTE_LISTING, arguments: {'item': item});
              reInitContext(context);
            },
            child: Container()
          ),
          Align(
            alignment: Alignment.topRight,
            child: IconButton(
              icon: Icon(item.isFavorite ? LineIcons.heart : LineIcons.heartAlt),
              color: item.isFavorite ? Colors.pink : Colors.white,
              iconSize: 24,
              // TODO translate
              tooltip: item.isFavorite ? "Hapus favorit" : "Tambahkan ke favorit",
              onPressed: () async {
                final favoriteResult = await ApiProvider(context).api("favorite", data: {
                  "id": item.id,
                  "type": item.isFavorite ? 'del' : 'add'
                });
                if (favoriteResult.isSuccess) {
                  final settings = Provider.of<SettingsProvider>(context, listen: false);
                  setState(() {
                    if (settings.isViewFavorites) {
                      _listItemFiltered.remove(item);
                    } else {
                      item.toggleFav();
                    }
                  });
                  u!.loadNotif();
                }
              },
            ),
          ),
        ],
      )
    );
    if (item.isForAdult) {
      return FlipCard(
        direction: FlipDirection.HORIZONTAL,
        front: Card(
          color: APP_UI_COLOR_MAIN,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(APP_UI_CARD_RADIUS)),
          clipBehavior: Clip.antiAlias,
          margin: EdgeInsets.zero,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const <Widget>[
              Icon(Icons.visibility_off, color: Colors.white),
              SizedBox(height: 8,),
              Text('18+', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.white),),
              Text('Tap untuk melihat', textAlign: TextAlign.center, style: TextStyle(color: Colors.white),),
            ],
          ),
        ),
        back: card,
      );
    }
    return card;
  }

  @override
  Widget build(BuildContext context) {
    const toolbarHeight = APP_UI_INPUT_HEIGHT + 20;
    return SafeArea(
      child: Stack(
        alignment: Alignment.topCenter,
        children: <Widget>[

          _listItemFiltered.isNotEmpty || _isGettingData ? Container() : MyPlaceholder(content: ContentModel(
            title: "Tidak Ada Iklan",
            description: "Tidak ada iklan yang sesuai.",
          ),),

          StaggeredGridView.countBuilder(
            controller: _scrollController,
            padding: const EdgeInsets.only(left: 15, right: 15, bottom: 15, top: toolbarHeight),
            crossAxisCount: ITEM_PER_ROW, // TODO responsive based on resolution
            itemCount: _listItemFiltered.length + 1, // add loader
            itemBuilder: (context, index) {
              var isLast = index == _listItemFiltered.length;
              if (isLast) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Center(child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 1000),
                    child: const SpinKitChasingDots(color: APP_UI_COLOR_MAIN, size: 50,),
                    opacity: _isGettingData ? 1 : 0,
                  ),),
                );
              }
              // item
              return _buildListingItem(index);
            },
            staggeredTileBuilder: (index) {
              var isLast = index == _listItemFiltered.length;
              return isLast
                ? const StaggeredTile.count(ITEM_PER_ROW, 1)
                // : StaggeredTile.count(1, _listItemFiltered[index].tier > 1 ? 2 : 1);
                : const StaggeredTile.count(1, 1);
            },
            mainAxisSpacing: 8.0,
            crossAxisSpacing: 8.0,
          ),

          AnimatedBuilder(
            animation: _animationController, builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, -toolbarHeight * _animation.value),
                child: Consumer<SettingsProvider>(
                  builder: (context, settings, child) {
                    return MySearchBar(
                      searchController: _searchController,
                      searchFocusNode: _searchFocusNode,
                      searchPlaceholder: tr(settings.isViewFavorites ? 'placeholder.search_favorites' : 'placeholder.search_listing'),
                      height: toolbarHeight,
                      dataType: 'listing',
                      filterValues: _filterValues,
                      onFilter: (values) {
                        setState(() {
                          _filterValues = values;
                        });
                      },
                      tool: Container(
                        decoration: BoxDecoration(
                          color: settings.isViewFavorites ? Colors.pink.withOpacity(.3) : Colors.transparent,
                          shape: BoxShape.circle
                        ),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: Icon(settings.isViewFavorites ? Icons.favorite : Icons.favorite_outline),
                          color: settings.isViewFavorites ? Colors.pink : Colors.grey[850],
                          tooltip: 'menu_favorites'.tr(),
                          onPressed: () {
                            settings.setSettings(isViewFavorites: !settings.isViewFavorites);
                            _getAllData();
                          },
                        )
                        .pulseIt(pulse: settings.isViewFavorites)
                        .withBadge(settings.notif?.listingFavorites),
                      ),
                    );
                  }
                )
              );
            }
          ),
        ],
      ),
    );
  }
}