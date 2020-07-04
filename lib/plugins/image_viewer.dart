import 'dart:io';

import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import '../models/iklan.dart';

class ImageViewer extends StatefulWidget {
  ImageViewer(this.args, {Key key}) : super(key: key);
  final Map args;

  @override
  _ImageViewerState createState() => _ImageViewerState();
}

class _ImageViewerState extends State<ImageViewer> {
  PageController pageController;

  ImageProvider<dynamic> _imageProvider(image) {
    if (image is IklanPicModel) return NetworkImage(image.foto);
    if (image is String) return NetworkImage(image);
    if (image is File) return FileImage(image);
    return AssetImage(image);
  }

  String get _caption {
    var image;
    if (_listImages is List) {
      if (pageController == null || !pageController.hasClients) return '';
      image = _listImages[pageController.page.round() - 1];
    } else {
      image = _listImages;
    }
    if (image is IklanPicModel) {
      return image.judul;
    }
    return '';
  }

  get _listImages => widget.args['image'];

  @override
  void initState() {
    pageController = PageController(initialPage: widget.args['page'] ?? 0);
    super.initState();
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final _initialScale = PhotoViewComputedScale.contained;
    final _minScale = PhotoViewComputedScale.contained * 0.5;
    final _maxScale = PhotoViewComputedScale.contained * 3.0;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        alignment: Alignment.bottomCenter,
        children: <Widget>[
          Container(
            child: _listImages is List ? PhotoViewGallery.builder(
              scrollPhysics: BouncingScrollPhysics(),
              builder: (BuildContext context, int index) {
                var image = _listImages[index];
                return PhotoViewGalleryPageOptions(
                  imageProvider: _imageProvider(image),
                  heroAttributes: PhotoViewHeroAttributes(tag: widget.args['tag'] ?? image),
                  initialScale: _initialScale,
                  minScale: _minScale,
                  maxScale: _maxScale,
                );
              },
              itemCount: _listImages.length,
              loadingBuilder: (context, event) => Center(
                child: Container(
                  width: 20.0,
                  height: 20.0,
                  child: CircularProgressIndicator(
                    value: event == null
                        ? 0
                        : event.cumulativeBytesLoaded / event.expectedTotalBytes,
                  ),
                ),
              ),
              // backgroundDecoration: widget.backgroundDecoration,
              pageController: pageController,
              // onPageChanged: onPageChanged,
            ) : PhotoView(
              heroAttributes: PhotoViewHeroAttributes(tag: widget.args['tag'] ?? "UserImage"),
              imageProvider: _imageProvider(_listImages),
              initialScale: _initialScale,
              minScale: _minScale,
              maxScale: _maxScale,
            )
          ),
          Padding(
            padding: EdgeInsets.all(20),
            child: Text(_caption ?? '', textAlign: TextAlign.center, style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }
}