import 'package:flutter/material.dart';
import '../../utils/api.dart';
import '../../utils/models.dart';
import '../../utils/variables.dart';
import '../../utils/widgets.dart';

class BroadcastPage extends StatefulWidget {
  const BroadcastPage({Key? key, this.isOpen = false}) : super(key: key);
  final bool isOpen;

  @override
  _BroadcastPageState createState() => _BroadcastPageState();
}

class _BroadcastPageState extends State<BroadcastPage> {
  var _listBroadcasts = <ListingModel>[];

  _getAllData() async {
    final broadcastResult = await ApiProvider(context).api('listing', data: {
      'uid': session!.id,
      'category': 'broadcast',
      'type': 'near',
    });
    if (broadcastResult.isSuccess) {
      if (mounted) {
        setState(() {
          _listBroadcasts = broadcastResult.data.map<ListingModel>((broadcast) => ListingModel.fromJson(broadcast)).toList();
        });
      }
    }
  }
  
  @override
  void didUpdateWidget(BroadcastPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance?.addPostFrameCallback((_) {
      if (!oldWidget.isOpen && widget.isOpen) {
        _getAllData();
      }
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance?.addPostFrameCallback((_) {
      _getAllData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: _listBroadcasts.isEmpty
        ? MyPlaceholder(
          content: ContentModel(
            title: "Tidak Ada Broadcast",
            description: "Tidak ada broadcast untuk saat ini."
          ),
        )
        : ListView.separated(
          itemCount: _listBroadcasts.length,
          separatorBuilder: (context, index) => Container(),
          itemBuilder: (context, index) {
            final _item = _listBroadcasts[index];
            return Column(children: <Widget>[
              Text(_item.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),),
              Text(_item.description),
            ],);
          },
        ),
    );
  }
}