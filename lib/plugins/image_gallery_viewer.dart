import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import '../utils/constants.dart';
import '../utils/variables.dart';

class ImageGalleryItem {
  ImageGalleryItem({this.heroTag, required this.src});
  final String? heroTag;
  final dynamic src;
}

class ImageGalleryViewer extends StatefulWidget {
  ImageGalleryViewer({
    Key? key, 
    required this.galleryItems,
    this.backgroundDecoration,
    this.loadingChild,
    this.minScale,
    this.maxScale,
    this.initialIndex = 0,
    this.scrollDirection = Axis.horizontal,
  }) : pageController = PageController(initialPage: initialIndex), super(key: key);

  final List<ImageGalleryItem> galleryItems;
  final BoxDecoration? backgroundDecoration;
  final PageController pageController;
  final Widget? loadingChild;
  final dynamic minScale;
  final dynamic maxScale;
  final int initialIndex;
  final Axis scrollDirection;

  @override
  _ImageGalleryViewerState createState() => _ImageGalleryViewerState();
}

class _ImageGalleryViewerState extends State<ImageGalleryViewer> {
  int currentIndex = 0;

  @override
  void initState() {
    currentIndex = widget.initialIndex;
    super.initState();
  }

  void onPageChanged(int index) {
    setState(() {
      currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      body: Container(
        decoration: widget.backgroundDecoration,
        constraints: BoxConstraints.expand(height: MediaQuery.of(context).size.height,),
        child: Stack(
          alignment: Alignment.bottomRight,
          children: <Widget>[
            PhotoViewGallery.builder(
              scrollPhysics: const BouncingScrollPhysics(),
              builder: (BuildContext context, int index) {
                final ImageGalleryItem item = widget.galleryItems[index];
                return PhotoViewGalleryPageOptions(
                  imageProvider: a.imageProvider(item.src),
                  initialScale: PhotoViewComputedScale.contained,
                  minScale: PhotoViewComputedScale.contained * (0.5 + index / 10),
                  maxScale: PhotoViewComputedScale.covered * 1.1,
                  heroAttributes: item.heroTag == null ? null : PhotoViewHeroAttributes(tag: item.heroTag!),
                );
              },
              itemCount: widget.galleryItems.length,
              loadingBuilder: (context, event) => widget.loadingChild ?? const CircularProgressIndicator(strokeWidth: 3, color: APP_UI_COLOR_MAIN,),
              backgroundDecoration: widget.backgroundDecoration,
              pageController: widget.pageController,
              onPageChanged: onPageChanged,
              scrollDirection: widget.scrollDirection,
            ),
            Container(
              padding: const EdgeInsets.all(20.0),
              child: Text(
                "${currentIndex + 1}/${widget.galleryItems.length}",
                textAlign: TextAlign.end,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16.0,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}