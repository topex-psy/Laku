import 'package:flutter/material.dart';
import 'package:debounce_throttle/debounce_throttle.dart';
import 'package:line_icons/line_icons.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'models/basic.dart';
import 'models/iklan.dart';
import 'models/toko.dart';
import 'models/user.dart';
import 'utils/api.dart';
import 'utils/constants.dart';
import 'utils/helpers.dart';
import 'utils/styles.dart' as style;
import 'utils/widgets.dart';

class DataList extends StatefulWidget {
  DataList(this.args, {Key key}) : super(key: key);
  final Map args;

  @override
  _DataListState createState() => _DataListState();
}

class _DataListState extends State<DataList> {
  final _refreshController = RefreshController(initialRefresh: true);
  final _searchDebouncer = Debouncer<String>(Duration(milliseconds: 1000));
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();

  var _listData = [];
  var _listLokasi = <TokoModel>[];
  var _filterValues = <String, dynamic>{};
  var _isLoaded = false;
  UserTierModel _tier;
  bool _isMyShopList;
  TokoModel _lokasi;

  @override
  void initState() {
    _isMyShopList = widget.args['tipe'] == 'shop' && widget.args['mode'] == 'mine';
    _searchController.addListener(() => _searchDebouncer.value = _searchController.text ?? '');
    _searchDebouncer.values.listen((keyword) => _getAllData());
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      var tierApi = await api('user_tier', data: {'uid': userSession.uid});
      var tier = UserTierModel.fromJson(tierApi.result.first);
      setState(() {
        _tier = tier;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  IconLabel _getTitle() {
    switch (widget.args['tipe']) {
      case 'listing':
        return IconLabel(LineIcons.list, "Iklan Saya");
      case 'shop':
      default:
        return IconLabel(LineIcons.map, "Lokasi Saya");
    }
  }

  _getAllData() async {
    var dataApi = await api(widget.args['tipe'], data: { 'uid': userSession.uid, ...widget.args });
    _refreshController.refreshCompleted();
    setState(() {
      _listData = dataApi.result.map((res) {
        switch (widget.args['tipe']) {
          case 'listing':
            return IklanModel.fromJson(res);
          case 'shop':
          default:
            return TokoModel.fromJson(res);
        }
      }).toList();
      _isLoaded = true;
    });
  }

  _action(String action, [int id]) async {
    print("TAP ACTION: $action $id");
    switch (action) {
      case 'create':
        if (_isMyShopList && _listData.length == _tier.maxShop) {
          h.showAlert(body: Column(
            children: <Widget>[
              Text('Batas Lokasi Tercapai', style: style.textTitle,),
              SizedBox(height: 6),
              Text("Upgrade akun Anda untuk dapat menambahkan lebih banyak lagi lokasi usaha!", style: style.textMutedM,),
              SizedBox(height: 16),
              UiButton("Upgrade Akun", width: 200, height: style.heightButtonL, color: Colors.teal[300], icon: LineIcons.certificate, textStyle: style.textButton, iconRight: true, onPressed: () {
                // TODO upgrade akun
              },),
            ],
          ));
          break;
        }
        break;
      case 'listing':
        final results = await Navigator.of(context).pushNamed(ROUTE_DATA, arguments: {'tipe': 'listing', 'shop': id}) as Map;
        print(results);
        break;
      case 'favorit':
        break;
    }
  }

  Widget _buildItem(context, index) {
    switch (widget.args['tipe']) {
      case 'listing':
        IklanModel _data = _listData[index];
        return Material(
          color: Colors.white,
          child: InkWell(
            highlightColor: Colors.transparent,
            splashColor: Colors.transparent,
            onTap: () => a.openListing(_data),
            child: Padding(
              padding: EdgeInsets.only(left: 20, top: 20, bottom: 20, right: 8),
              child: Row(children: <Widget>[
                Hero(
                  tag: "listing_${_data.id}_0",
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: FadeInImage.assetNetwork(
                      placeholder: IMAGE_DEFAULT_NONE,
                      image: _data.foto.first.foto,
                      fit: BoxFit.cover,
                      width: 80,
                      height: 80,
                    ),
                  ),
                ),
                SizedBox(width: 20,),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(_data.judul, style: style.textCaption,),
                    SizedBox(height: 2),
                    h.html("Kategori: <strong>${_data.kategori}</strong>"),
                    // SizedBox(height: 2),
                    // Text(_data.deskripsi),
                  ],
                )),
                // SizedBox(width: 8,),
                // IconButton(
                //   highlightColor: Colors.red[200].withOpacity(.5),
                //   splashColor: Colors.red[200].withOpacity(.5),
                //   icon: Icon(LineIcons.trash),
                //   color: Colors.grey,
                //   onPressed: () {
                //     print(" -> TAP delete");
                //   }
                // ),
              ],),
            ),
          ),
        );
      case 'shop':
      default:
        TokoModel _data = _listData[index];
        return Container(
          color: Colors.white,
          padding: EdgeInsets.all(20),
          child: Row(children: <Widget>[
            Icon(MdiIcons.storefrontOutline, size: 50, color: THEME_COLOR,),
            SizedBox(width: 20,),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(_data.judul, style: style.textLabel,),
                SizedBox(height: 2),
                Text(_data.alamat),
                SizedBox(height: 10),
                Wrap(spacing: 8, runSpacing: 8, children: <Widget>[
                  UiFlatButton(LineIcons.files_o, "${f.formatNumber(_data.jumlahIklan)} iklan", () => _action('listing', _data.id)),
                  UiFlatButton(LineIcons.heart_o, "${f.formatNumber(_data.jumlahFavorit)} favorit", () => _action('favorit', _data.id)),
                ],),
              ],
            ))
          ],),
        );
    }
  }

  Widget get _actionButton {
    return _tier == null || (_isMyShopList && _tier.tier == 0) ? SizedBox() : Container(
      height: double.infinity,
      width: 60,
      child: RaisedButton(
        elevation: 0,
        child: Icon(LineIcons.plus, size: 30,),
        color: Colors.teal,
        textColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        onPressed: () => _action('create'),
      ),
    );
  }

  Widget get _searchBar {
    switch (widget.args['tipe']) {
      case 'listing': // TODO harusnya kalo mode 'mine' aja
        return SizedBox(
          height: THEME_INPUT_HEIGHT + 32,
          child: Material(
            color: THEME_COLOR,
            elevation: 0,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                SizedBox(width: 15,),
                Expanded(
                  child: UiSelect(
                    placeholder: "Pilih lokasi",
                    simple: true,
                    isDense: true,
                    listMenu: _listLokasi,
                    initialValue: _lokasi,
                    onSelect: (val) {
                      setState(() { _lokasi = val; });
                    },
                  ),
                ),
                SizedBox(width: 8,),
                IconButton(
                  padding: EdgeInsets.zero,
                  icon: Icon(Icons.sort),
                  color: Colors.white,
                  // tooltip: 'prompt_sort'.tr(),
                  onPressed: () {},
                ),
                // widget.tool ?? SizedBox(),
                SizedBox(width: 8,),
              ],
            ),
          ),
        );
      case 'shop':
      default:
        return _tier != null && _tier.tier > 0 ? UiSearchBar(
          searchController: _searchController,
          searchFocusNode: _searchFocusNode,
          backgroundColor: THEME_COLOR,
          actionColor: Colors.white,
          dataType: widget.args['tipe'],
          filterValues: _filterValues,
          onFilter: (values) {
            setState(() {
              _filterValues = values;
            });
          },
        ) : SizedBox();
    }
  }

  @override
  Widget build(BuildContext context) {
    final _title = _getTitle();
    return Scaffold(
      body: SafeArea(child: Column(children: <Widget>[
        UiAppBar(_title.label, icon: _title.icon, tool: _actionButton,),
        _searchBar,
        // UiSearchBar(
        //   searchController: _searchController,
        //   searchFocusNode: _searchFocusNode,
        //   backgroundColor: THEME_COLOR,
        //   actionColor: Colors.white
        // ),
        Expanded(
          child: SmartRefresher(
            enablePullDown: true,
            enablePullUp: false,
            header: WaterDropMaterialHeader(color: Colors.white, backgroundColor: THEME_COLOR),
            controller: _refreshController,
            onRefresh: _getAllData,
            child: _isLoaded && _listData.length == 0 ? UiPlaceholder(label: "Tidak ada data yang sesuai.") : ListView.separated(
              separatorBuilder: (context, index) => Container(color: Colors.grey, height: 1,),
              itemCount: _listData.length,
              itemBuilder: _buildItem,
            ),
          ),
        ),
        _isMyShopList ? AnimatedSwitcher(
          duration: Duration(milliseconds: 500),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.linear,
          // transitionBuilder: (Widget child, Animation<double> animation) => ScaleTransition(child: child, scale: animation,),
          transitionBuilder: (Widget child, Animation<double> animation) {
            final  offsetAnimation = Tween<Offset>(begin: Offset(0, 1), end: Offset(0, 0)).animate(animation);
            return SlideTransition(
              position: offsetAnimation,
              child: child,
            );
          },
          child: _tier != null && _tier.tier == 0 && _listData.isNotEmpty ? Container(
            width: double.infinity,
            height: 180,
            padding: EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)]
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text('Anda pelaku bisnis?', style: style.textTitle,),
                SizedBox(height: 6),
                Text('Anda dapat memberikan nama usaha dan menambahkan lebih dari satu lokasi.', style: style.textMutedM,),
                SizedBox(height: 16),
                UiButton("Upgrade ke Akun Bisnis", width: 250, height: style.heightButtonL, color: Colors.teal[300], icon: LineIcons.certificate, textStyle: style.textButton, iconRight: true, onPressed: () {
                  // TODO upgrade akun bisnis
                },),
              ],
            ),
          ) : SizedBox(),
        ) : SizedBox(),
      ],),),
    );
  }
}