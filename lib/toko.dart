import 'package:flutter/material.dart';
import 'package:laku/models/toko.dart';
import 'package:laku/utils/constants.dart';
import 'package:laku/utils/helpers.dart';
import 'package:laku/utils/widgets.dart';
import 'package:line_icons/line_icons.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'utils/api.dart';
import 'utils/styles.dart' as style;

class Toko extends StatefulWidget {
  @override
  _TokoState createState() => _TokoState();
}

class _TokoState extends State<Toko> {
  final _refreshController = RefreshController(initialRefresh: false);
  var _listToko = <TokoModel>[];
  var _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getAllData();
    });
  }

  _getAllData() async {
    if (!_isLoading) setState(() {
      _isLoading = true;
    });
    var tokoApi = await api('shop', data: {'uid': currentPerson.uid});
    _refreshController.refreshCompleted();
    setState(() {
      _listToko = tokoApi.result.map((res) => TokoModel.fromJson(res)).toList();
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: Column(children: <Widget>[
        SmartRefresher(
          enablePullDown: true,
          enablePullUp: false,
          header: WaterDropMaterialHeader(color: Colors.white, backgroundColor: THEME_COLOR),
          controller: _refreshController,
          onRefresh: _getAllData,
          child: ListView.separated(
            separatorBuilder: (context, index) => Container(color: Colors.grey, height: 1,),
            itemCount: _listToko.length,
            itemBuilder: (context, index) {
              var _toko = _listToko[index];
              return Container(
                padding: EdgeInsets.all(8),
                child: Row(children: <Widget>[
                  Icon(LineIcons.adjust),
                  SizedBox(width: 20,),
                  Expanded(child: Column(
                    children: <Widget>[
                      Text(_toko.judul, style: style.textLabel,),
                      Text(_toko.alamat),
                    ],
                  ))
                ],),
              );
            },
          ),
        ),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: EdgeInsets.all(8.0),
            child: Column(
              children: <Widget>[
                Text('Anda pemilik bisnis?', style: style.textTitle,),
                UiButton("Upgrade ke Akun Bisnis", width: 200, height: style.heightButtonL, color: Colors.green, icon: LineIcons.certificate, textStyle: style.textButtonL, iconRight: true, onPressed: () {
                  // TODO upgrade akun bisnis
                },),
              ],
            ),
          ),
        ),
        Spacer(),
      ],),),
    );
  }
}