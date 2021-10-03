import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';
import 'package:wechat_camera_picker/wechat_camera_picker.dart';
import '../../../plugins/image_gallery_viewer.dart';
import '../../../utils/api.dart';
import '../../../utils/constants.dart';
import '../../../utils/variables.dart';

class CreatePage extends StatefulWidget {
  const CreatePage(this.analytics, this.args, {Key? key}) : super(key: key);
  final FirebaseAnalytics analytics;
  final Map<String, dynamic> args;

  @override
  _CreatePageState createState() => _CreatePageState();
}

class _CreatePageState extends State<CreatePage> {

  var _imagesEdit = <String>[];
  var _images = <AssetEntity>[];
  var _isLoading = false;
  var _loadingText = "";
  var _loadingProgress = 0.0;

  _addPicture() async {
    final resultList = await u?.browsePicture(
      selectedList: _images,
      uploadedList: _imagesEdit,
    );
    print("resultList = $resultList");
    if (mounted && resultList != null && resultList.isNotEmpty) {
      setState(() {
        _images = resultList;
      });
    }
  }

  Future<List<String>> _compressImages({bool toBase64 = true}) async {
    var array = <String>[];
    for (AssetEntity image in _images) {
      String? result = await a.compressImage(image, toBase64: toBase64);
      if (result != null) array.add(result);
    }
    return array;
  }

  Future<ApiModel> _uploadImages(List<Map<String, dynamic>> data) async {
    ApiModel? uploadResult = await ApiProvider().api(
      'upload',
      method: "post",
      getParams: {"type": "data"},
      data: json.encode({"data": data}),
      options: Options(
        contentType: "application/json",
        headers: {
          HttpHeaders.contentTypeHeader: "application/json",
        }
      ),
      withLog: true,
      onSendProgress: (sent, total) {
        final progress = sent / total;
        final percent = progress * 100;
        if (percent.toInt() % 10 == 0) {
          setState(() {
            _loadingProgress = progress;
          });
        }
      }
    );
    print("upload result: $uploadResult");
    return uploadResult;
  }

  @override
  void initState() {
    _images = widget.args["selectedAssets"] ?? [];
    super.initState();
    WidgetsBinding.instance?.addPostFrameCallback((_) async {
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return await h!.showConfirmDialog("Apakah Anda yakin ingin batal memasang iklan?", title: "Batal Pasang") ?? false;
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(children: [
              MyImageUpload(
                imageList: _images,
                imageEditList: _imagesEdit,
                maximum: SETUP_MAX_LISTING_IMAGES,
                onDelete: (asset) {
                  print("onDelete: $asset");
                  setState(() {
                    if (asset is AssetEntity) {
                      _images.remove(asset);
                    } else {
                      _imagesEdit.remove(asset);
                    }
                  });
                },
              ),
            ],),
          ),
        ),
      ),
    );
  }
}

class MyImageUpload extends StatelessWidget {
  const MyImageUpload({
    this.imageList = const [],
    this.imageEditList = const [],
    this.placeholder,
    required this.onDelete,
    required this.maximum,
    Key? key
  }) : super(key: key);
  final List<AssetEntity> imageList;
  final List<String> imageEditList;
  final String? placeholder;
  final void Function(dynamic) onDelete;
  final int maximum;

  @override
  Widget build(BuildContext context) {

    List<Widget> _makeList(List images) {
      final deleteButton = Container(
        child: const Icon(Icons.close_rounded, color: Colors.black, size: 22,),
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white
        ),
      );
      final galleryItems = images.map((image) => ImageGalleryItem(src: image)).toList();
      return images.asMap().map((index, asset) {
        return MapEntry(index, Stack(
          alignment: Alignment.topRight,
          children: <Widget>[
            GestureDetector(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(
                  builder: (context) => ImageGalleryViewer(
                    galleryItems: galleryItems,
                    backgroundDecoration: const BoxDecoration(color: Colors.black,),
                    initialIndex: index,
                    scrollDirection: Axis.horizontal,
                  ),
                ));
              },
              child: asset is AssetEntity
                ? Image(
                  image: AssetEntityImageProvider(asset, isOriginal: false),
                  width: 300,
                  height: 300,
                  fit: BoxFit.cover,
                )
                : Image.network(asset,
                  width: 300,
                  height: 300,
                  fit: BoxFit.cover,
                )
            ),
            GestureDetector(
              onTap: () {
                onDelete(asset);
              },
              child: deleteButton,
            ),
          ]
        ));
      }).values.toList();
    }

    var listImages = _makeList([...imageEditList, ...imageList]);
    var gridCount = SETUP_MAX_LISTING_IMAGES; // min(listImages.length, min(MAX_LISTING_IMAGES, maximum));
    var gridHeight = (MediaQuery.of(context).size.width - 80) / gridCount;
    var totalHeight = gridHeight * (listImages.length / gridCount).ceil();

    return listImages.isEmpty ? Text(
      placeholder ?? "Silakan unggah maksimal $maximum foto.",
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: Colors.grey,
      )
    ) : SizedBox(
      height: totalHeight,
      child: GridView.count(
        mainAxisSpacing: 2.0,
        crossAxisSpacing: 2.0,
        // physics: listImages.length > gridCount ? AlwaysScrollableScrollPhysics() : NeverScrollableScrollPhysics(),
        physics: const NeverScrollableScrollPhysics(),
        // scrollDirection: Axis.horizontal,
        crossAxisCount: gridCount,
        children: listImages,
      ),
    );
  }
}