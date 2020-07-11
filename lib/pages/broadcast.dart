import 'package:flutter/material.dart';
import 'package:laku/utils/widgets.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/iklan.dart';
import '../utils/api.dart';
import '../utils/helpers.dart';
import '../utils/styles.dart' as style;

class Broadcast extends StatefulWidget {
  Broadcast({Key key, this.isOpen = false}) : super(key: key);
  final bool isOpen;

  @override
  _BroadcastState createState() => _BroadcastState();
}

class _BroadcastState extends State<Broadcast> {
  var _listBroadcasts = <IklanModel>[];

  _getAllData() async {
    var _isGranted = await Permission.location.isGranted;
    if (!_isGranted) return;
    var broadcastApi = await api('listing', data: {'uid': userSession.uid, 'type': 'WTB', 'mode': 'near'});
    if (mounted) {
      setState(() {
        _listBroadcasts = broadcastApi.result.map<IklanModel>((broadcast) => IklanModel.fromJson(broadcast)).toList();
      });
    }
  }
  
  @override
  void didUpdateWidget(Broadcast oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!oldWidget.isOpen && widget.isOpen) {
        _getAllData();
      }
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getAllData();
    });
  }

  // @override
  // void dispose() {
  //   super.dispose();
  // }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: _listBroadcasts.isEmpty ? UiPlaceholder(type: 'broadcast', label: "Tidak ada broadcast untuk saat ini.",) : ListView.separated(
        itemCount: _listBroadcasts.length,
        separatorBuilder: (context, index) => Container(),
        itemBuilder: (context, index) {
          final _item = _listBroadcasts[index];
          return Container(
            child: Column(children: <Widget>[
              Text(_item.judul, style: style.textTitle,),
              Text(_item.deskripsi),
            ],),
          );
        },
      ),
    );
  }
}