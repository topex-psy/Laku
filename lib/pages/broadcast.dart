import 'package:flutter/material.dart';
import '../models/iklan.dart';
import '../utils/api.dart';
import '../utils/helpers.dart';

class Broadcast extends StatefulWidget {
  Broadcast({Key key, this.isOpen = false}) : super(key: key);
  final bool isOpen;

  @override
  _BroadcastState createState() => _BroadcastState();
}

class _BroadcastState extends State<Broadcast> {
  var _listBroadcasts = <IklanModel>[];

  _getAllData() async {
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

  @override
  void dispose() {
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView.separated(
        itemCount: _listBroadcasts.length,
        separatorBuilder: (context, index) {
          return Container();
        },
        itemBuilder: (context, index) {
          return Container();
        },
      ),
    );
  }
}