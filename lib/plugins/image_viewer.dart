import 'dart:io';

import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';

class ImageViewer extends StatefulWidget {
  ImageViewer(this.args, {Key key}) : super(key: key);
  final Map args;

  @override
  _ImageViewerState createState() => _ImageViewerState();
}

class _ImageViewerState extends State<ImageViewer> {
  ImageProvider<dynamic> get _imageProvider {
    var image = widget.args['image'];
    if (image is String) return NetworkImage(image);
    if (image is File) return FileImage(image);
    return AssetImage(image);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      body: Container(
        child: PhotoView(
          heroAttributes: PhotoViewHeroAttributes(tag: "UserImage"),
          initialScale: PhotoViewComputedScale.contained,
          minScale: PhotoViewComputedScale.contained * 0.5,
          maxScale: PhotoViewComputedScale.contained * 3.0,
          imageProvider: _imageProvider
        )
      ),
    );
  }
}