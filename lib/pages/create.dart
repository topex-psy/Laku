import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:geolocator/geolocator.dart';
import 'package:line_icons/line_icons.dart';
import 'package:provider/provider.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';
import 'package:wechat_camera_picker/wechat_camera_picker.dart';
import '../../../extensions/string.dart';
import '../../../extensions/widget.dart';
import '../../../plugins/image_gallery_viewer.dart';
import '../../../utils/api.dart';
import '../../../utils/constants.dart';
import '../../../utils/helpers.dart';
import '../../../utils/models.dart';
import '../../../utils/providers.dart';
import '../../../utils/variables.dart';
import '../../../utils/widgets.dart';

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
  var _isEdit = false;
  var _isChanged = false;
  var _isLoadingCategory = true;
  var _isLoadingShop = true;
  var _errorText = <String, String>{};
  var _listCategory = <String>[];
  var _listCategorySub = <String>[];
  var _listShop = <ShopModel>[];
  var _step = 0;

  final _formKey = GlobalKey<FormState>();
  final _listType = <MenuModel>[
    MenuModel("Pasang Iklan", 'listing', icon: LineIcons.edit,),
    MenuModel("Broadcast", 'broadcast', icon: LineIcons.bullhorn,),
  ];

  final _scrollController = ScrollController();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _deliveryInfoController = TextEditingController();
  final _deliveryDistanceController = TextEditingController();
  final _titleFocus = FocusNode();
  final _descriptionFocus = FocusNode();
  final _priceFocus = FocusNode();

  String? _category;
  String? _subcategory;
  var _isNew = true;
  var _isNegotiable = false;
  var _isDeliverable = false;
  var _isAdult = false;
  var _descriptionLength = 0;
  var _type = "market";
  DateTime? _jadwalMulai;
  DateTime? _jadwalAkhir;
  ShopModel? _shop;
  ListingModel? _item;

  _dismissError(String tag) {
    if (_errorText.containsKey(tag)) {
      setState(() {
        _errorText.remove(tag);
      });
    }
  }

  _submit() async {
    if (_step == 0) {
      return setState(() { _step++; });
    }
    if (_images.isEmpty && !_isEdit && _type != "broadcast") {
      return h!.showCallbackDialog("Unggah minimal 1 foto untuk iklan Anda.", title: "Tambahkan Foto", type: MyCallbackType.warning);
    }
    // if (_category == null || _subcategory == null) {
    //   return h!.showCallbackDialog("Harap pilih kategori iklan Anda.", title: "Pilih Kategori", type: MyCallbackType.warning);
    // }

    Position? position;
    if (_shop == null && _listShop.isNotEmpty) {
      dynamic setLocation = await h!.showConfirmDialog(
        "Kamu tidak memilih toko. Apakah ingin menjadikan posisimu saat ini sebagai titik poin?",
        additionalButtons: [
          MenuModel("Set lokasi", false, color: APP_UI_COLOR_PRIMARY, onPressed: () => Navigator.of(context).pop("manual")),
        ],
      );
      if (setLocation == "manual") {
        position = await l.pickPosition();
      } else if (!setLocation) {
        return;
      }
    }

    setState(() {
      _isLoading = true;
    });
    position = position ?? await l.myPosition();
    var _imagesNew = <String>[];
    if (_images.isNotEmpty) {
      setState(() {
        _loadingText = "Mengompresi foto";
      });
      _imagesNew = await _compressImages(toBase64: true);
    }
    setState(() {
      _loadingText = "Memasang iklan";
      _loadingProgress = 0.0;
    });
    final hash = _item == null ? f!.generateHash(): _item.hashCode;
    // final postData = <String, String?>{
    final postData = <String, dynamic>{
      'id': _item?.id.toString(),
      'id_user': session!.id.toString(),
      'id_shop': _shop?.id.toString(),
      'type': _type,
      'category': _category,
      'subcategory': _subcategory,
      'title': _titleController.text,
      'description': _descriptionController.text,
      'price': _priceController.text.nominal.toString(),
      'is_new': _isNew ? 1 : 0,
      'is_for_adult': _isAdult ? 1 : 0,
      'is_negotiable': _isNegotiable ? 1 : 0,
      'delivery_info': _isDeliverable ? _deliveryInfoController.text : null,
      'delivery_max_distance': _isDeliverable ? _deliveryDistanceController.text : null,
      'valid_from': _jadwalMulai?.toIso8601String(),
      'valid_until': _jadwalAkhir?.toIso8601String(),
      'latitude': position.latitude,
      'longitude': position.longitude,
      'images_count': _images.length,
      'images_edit': _imagesEdit.join('|'),
      'images': _imagesNew.join('|'),
      'hash': hash.toString(),
    };
    print(" ... POST DATA: $postData");
    final postResult = await ApiProvider(context).api('listing', method: 'post', data: postData, withLog: true, onSendProgress: (sent, total) {
      final progress = sent / total;
      final percent = progress * 100;
      if (percent.toInt() % 10 == 0) {
        setState(() {
          _loadingProgress = progress;
        });
      }
    });
    setState(() {
      _isLoading = false;
      _loadingText = "";
      _loadingProgress = 0.0;
    });

    if (postResult.isSuccess) {
      String caption, message;
      if (_type == 'broadcast') {
        caption = "Broadcast Terkirim!";
        message = "Pesan broadcast Anda telah disiarkan dan dapat dilihat selama 24 jam!";
      } else {
        caption = "Iklan Terpasang!";
        message = "Iklan <strong>${postData['title']}</strong> telah terpasang!";
      }
      await h!.showCallbackDialog(message, title: caption, type: MyCallbackType.success);
      Navigator.of(context).pop({'isSubmit': true});
    } else {
      h!.showCallbackDialog(
        "Terjadi kendala saat memasang ${_type == 'broadcast' ? 'broadcast' : 'iklan'}mu.",
        title: "Gagal Memproses",
        type: MyCallbackType.error
      );
    }
  }

  int get _selectedPicsTotal => _imagesEdit.length + _images.length;
  int get _maxAllowedDesc => profile!.tier.maxListingDesc;
  int get _maxAllowedPic => profile!.tier.maxListingPic;

  _browsePicture() async {
    final resultList = await u?.browsePicture(
      maximum: _maxAllowedPic - _imagesEdit.length,
      selectedList: _images,
      uploadedList: _imagesEdit,
    ) ?? [];
    print("resultList = $resultList");
    if (mounted && resultList.isNotEmpty) {
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
    ApiModel? uploadResult = await ApiProvider(context).api(
      'upload',
      method: "post",
      getParams: {"type": "data"},
      data: {"data": data},
      options: Options(
        contentType: "application/json",
        headers: {
          HttpHeaders.contentTypeHeader: Headers.jsonContentType,
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

  Future<void> _loadShop() async {
    if (!_isLoadingShop) {
      setState(() {
        _isLoadingShop = true;
      });
    }
    final shopResult = await ApiProvider(context).api('shop/user', method: 'get', getParams: { 'id': session!.id.toString() });
    if (mounted) {
      setState(() {
        _listShop = shopResult.data.map((shop) => ShopModel.fromJson(shop)).toList();
        _isLoadingShop = false;
      });
    }
  }

  Future<void> _loadCategory() async {
    if (!_isLoadingCategory) {
      setState(() {
        _isLoadingCategory = true;
      });
    }
    final listingCategoryResult = await ApiProvider(context).api('listing/category', method: "get", getParams: { 'type': _type });
    if (listingCategoryResult.isSuccess) {
      if (mounted) {
        final listKelompok = List<Map<String, String>>.from(listingCategoryResult.data.first["category"]);
        setState(() {
          _listCategory = listKelompok.map((k) => k['category']!).toList() ..add('other');
          _isLoadingCategory = false;
          // _resetKategori();
        });
      }
    }
  }

  // _resetKategori() {
  //   _category = null;
  //   _subcategory = null;
  // }

  // _clearKategori() {
  //   setState(_resetKategori);
  // }

  // List<Widget> _selectKelompok() {
  //   return _listCategory.map((category) {
  //     return Column(
  //       mainAxisSize: MainAxisSize.min,
  //       children: <Widget>[
  //         Card(elevation: 1, shape: const CircleBorder(), clipBehavior: Clip.antiAlias, child: InkWell(
  //           child: const SizedBox(width: 60, height: 60, child: Center(child: Icon(Icons.circle, size: 30, color: APP_UI_COLOR_MAIN))),
  //           onTap: () => setState(() { _category = category; }),
  //         )),
  //         const SizedBox(height: 3),
  //         Text(category, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13)),
  //       ],
  //     );
  //   }).toList();
  // }

  @override
  void initState() {
    _images = widget.args["selectedAssets"] ?? [];
    _item = widget.args["item"];
    _isEdit = _item != null;
    _titleController.addListener(() => _dismissError("title"));
    _descriptionController.addListener(() {
      _dismissError("deskripsi");
      setState(() {
        _descriptionLength = _descriptionController.text.length;
      });
    });
    _priceController.addListener(() => _dismissError("price"));

    super.initState();
    WidgetsBinding.instance?.addPostFrameCallback((_) async {
      _loadCategory();
      _loadShop();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _deliveryInfoController.dispose();
    _deliveryDistanceController.dispose();
    _titleFocus.dispose();
    _descriptionFocus.dispose();
    _priceFocus.dispose();
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
          child: MyWizard(
            scrollController: _scrollController,
            steps: [
              ContentModel(title: "Detail Iklan", description: "Lengkapi informasi detail untuk iklan yang akan kamu pasang!"),
              ContentModel(title: "Pratinjau", description: "Pastikan iklan yang akan kamu pasang sudah terlihat bagus."),
            ],
            step: _step,
            body: [
              Column(children: [
                MyImageUpload(
                  imageList: _images,
                  imageEditList: _imagesEdit,
                  maximum: _maxAllowedPic,
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
            ]
          ),
        ),
      ),
    );
  }
}