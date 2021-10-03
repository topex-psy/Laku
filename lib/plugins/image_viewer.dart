import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import '../utils/variables.dart';

class ImageViewer extends StatefulWidget {
  const ImageViewer(this.image, {Key? key}) : super(key: key);
  final dynamic image;

  @override
  _ImageViewerState createState() => _ImageViewerState();
}

class _ImageViewerState extends State<ImageViewer> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      body: PhotoView(
        heroAttributes: const PhotoViewHeroAttributes(tag: "UserImage"),
        initialScale: PhotoViewComputedScale.contained,
        minScale: PhotoViewComputedScale.contained * 0.5,
        maxScale: PhotoViewComputedScale.contained * 3.0,
        imageProvider: a.imageProvider(widget.image)
      ),
    );
  }
}