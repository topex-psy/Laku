import 'package:flutter/material.dart';
import 'models/iklan.dart';
import 'utils/helpers.dart';
import 'utils/widgets.dart';

class Listing extends StatefulWidget {
  Listing(this.args, {Key key}) : super(key: key);
  final Map args;

  @override
  _ListingState createState() => _ListingState();
}

class _ListingState extends State<Listing> {
  @override
  Widget build(BuildContext context) {
    final IklanModel _item = widget.args['item'];
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: <Widget>[
            UiAppBar(_item.judul),
            Expanded(
              child: SingleChildScrollView(
                child: Column(children: <Widget>[
                  UiDropImages(
                    listImages: _item.foto,
                    height: 200,
                    onTapImage: (image) => h.viewImage(_item.foto, page: _item.foto.indexOf(image)),
                  ),
                ],),
              ),
            ),
          ],
        ),
      ),
    );
  }
}