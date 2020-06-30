import 'package:flutter/material.dart';
import 'package:laku/models/iklan.dart';
import 'package:line_icons/line_icons.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'extensions/widget.dart';
import 'models/basic.dart';
import 'models/toko.dart';
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
  var _listData = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
    });
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
    });
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
            onTap: () {
              print(" -> TAP iklan");
            },
            child: Padding(
              padding: EdgeInsets.only(left: 20, top: 20, bottom: 20, right: 8),
              child: Row(children: <Widget>[
                ClipRRect(
                  borderRadius: BorderRadius.circular(25),
                  child: FadeInImage.assetNetwork(
                    placeholder: IMAGE_DEFAULT_NONE,
                    image: _data.foto.first.foto,
                    fit: BoxFit.cover,
                    width: 50,
                    height: 50,
                  ),
                ),
                SizedBox(width: 20,),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(_data.judul, style: style.textLabel,),
                    SizedBox(height: 2),
                    h.html("Tipe: <strong>${_data.tipe == 'WTS' ? 'Iklan' : 'Pencarian'}</strong>"),
                    SizedBox(height: 2),
                    h.html("Kategori: <strong>${_data.kategori}</strong>"),
                    SizedBox(height: 2),
                    Text(_data.deskripsi),
                  ],
                )),
                SizedBox(width: 8,),
                IconButton(
                  highlightColor: Colors.red[200].withOpacity(.5),
                  splashColor: Colors.red[200].withOpacity(.5),
                  icon: Icon(LineIcons.trash),
                  color: Colors.grey,
                  onPressed: () {
                    print(" -> TAP delete");
                  }
                ),
              ],),
            ),
          ),
        );
      case 'shop':
      default:
        TokoModel _data = _listData[index];
        return Material(
          color: Colors.white,
          child: InkWell(
            onTap: () async {
              final results = await Navigator.of(context).pushNamed(ROUTE_DATA, arguments: {'tipe': 'listing', 'shop': _data.id}) as Map;
              print(results);
            },
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Row(children: <Widget>[
                Icon(LineIcons.map_marker, size: 50, color: THEME_COLOR,),
                SizedBox(width: 20,),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(_data.judul, style: style.textLabel,),
                    SizedBox(height: 2),
                    Text(_data.alamat),
                    SizedBox(height: 10),
                    Wrap(children: <Widget>[
                      Container(
                        height: 30,
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          color: THEME_COLOR,
                          borderRadius: BorderRadius.circular(20)
                        ),
                        padding: EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ClipRRect(borderRadius: BorderRadius.circular(5), child: Text("  3  ", style: TextStyle(color: Colors.white, backgroundColor: Colors.white30, fontWeight: FontWeight.bold),),),
                            SizedBox(width: 8,),
                            Text("Iklan", style: style.textWhite,),
                          ],
                        ),
                      ).shimmerIt(minOpacity: 0.8, maxOpacity: 1.0),
                    ],)
                  ],
                ))
              ],),
            ),
          ),
        );
    }
  }

  _action(String action) {

  }

  Widget _actionButton() {
    return Container(
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

  @override
  Widget build(BuildContext context) {
    final _title = _getTitle();
    return Scaffold(
      body: SafeArea(child: Column(children: <Widget>[
        UiAppBar(_title.label, icon: _title.icon, tool: _actionButton(),),
        Expanded(
          child: SmartRefresher(
            enablePullDown: true,
            enablePullUp: false,
            header: WaterDropMaterialHeader(color: Colors.white, backgroundColor: THEME_COLOR),
            controller: _refreshController,
            onRefresh: _getAllData,
            child: ListView.separated(
              separatorBuilder: (context, index) => Container(color: Colors.grey, height: 1,),
              itemCount: _listData.length,
              itemBuilder: _buildItem,
            ),
          ),
        ),
        widget.args['tipe'] == 'shop' && widget.args['mode'] == 'mine' ? Container(
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
        ) : Container(),
      ],),),
    );
  }
}