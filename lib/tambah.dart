import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:laku/models/iklan.dart';
import 'package:laku/providers/settings.dart';
import 'package:line_icons/line_icons.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:multi_image_picker/multi_image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'models/basic.dart';
import 'models/user.dart';
import 'utils/api.dart';
import 'utils/constants.dart';
import 'utils/helpers.dart';
import 'utils/styles.dart' as style;
import 'utils/upload.dart';
import 'utils/widgets.dart';

class Tambah extends StatefulWidget {
  Tambah(this.args, {Key key}) : super(key: key);
  final Map args;

  @override
  _TambahState createState() => _TambahState();
}

class _TambahState extends State<Tambah> {
  var _imagesEdit = <String>[];
  var _images = <Asset>[];
  var _isLoading = true;
  var _maxImageSelect = 3;

  final _formKey = GlobalKey<FormState>();
  final _listTipe = <IconLabel>[
    IconLabel(LineIcons.bullhorn, "Pasang Iklan", value: 'WTS'),
    IconLabel(LineIcons.search, "Cari Iklan", value: 'WTB'),
  ];

  TextEditingController _judulController;
  TextEditingController _deskripsiController;
  FocusNode _judulFocusNode;
  FocusNode _deskripsiFocusNode;
  var _errorText = <String, String>{};
  var _listKategori = <IklanKategoriModel>[];

  IklanKategoriModel _kategori;
  String _tipe;
  String _foto;

  _dismissError(String tag) {
    if (_errorText.containsKey(tag)) setState(() {
      _errorText.remove(tag);
    });
  }

  _submit() async {
    if (_images.isEmpty) {
      h.failAlert("Tambahkan Foto", "Unggah minimal 1 foto untuk iklan Anda.");
      return;
    }

    final hash = DateTime.now().millisecondsSinceEpoch;
    final postData = <String, String>{
      'uid': userSession.uid,
      'tipe': _tipe,
      'judul': _judulController.text,
      'deskripsi': _deskripsiController.text,
      'kategori': _kategori.id.toString(),
      'hash': hash.toString(),
    };
    h.loadAlert("Memasang iklan ...");

    // upload pic
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    settings.setSettings(
      // iklanUploadPic: [...settings.iklanUploadPic, hash],
      isUploadListing: true
    );

    int byteCount = 0;

    uploadImages('listing', _images, hash).then((response) {
      print("IMAGES UPLOAD RESPONSE: $response");
      if (response == null) {
        h.failAlertInternet(message: "Terjadi masalah saat mengunggah foto transaksi Anda. Coba lagi nanti!");
      } else {
        print("IMAGES UPLOAD STATUS CODE: ${response.statusCode}");
        print("IMAGES UPLOAD HEADERS: ${response.headers}");
        response.stream.transform(
          // utf8.decoder
          StreamTransformer.fromHandlers(
            handleData: (data, sink) {
              byteCount += data.length;
              print(" -> byteCount: $byteCount");
              sink.add(data);
            },
            handleError: (error, stack, sink) {},
            handleDone: (sink) {
              sink.close();
            },
          ),
        ).listen((value) {
          print("IMAGES UPLOAD PROGRESS: $value");
        }).onDone(() {
          print("IMAGES UPLOAD DONE");
          // var iklanUploadPicAfter = settings.iklanUploadPic.where((i) => i != hash).toList();
          settings.setSettings(
            // iklanUploadPic: iklanUploadPicAfter,
            isUploadListing: false
          );
        });
      }
    });
    
    var postApi = await api('listing', type: 'post', data: postData);
    Navigator.of(context).pop();
    if (postApi.isSuccess) {
      await h.customAlert("Iklan Terpasang!", "Iklan <strong>${postData['judul']}</strong> telah terpasang!", icon: Icon(LineIcons.check_circle, color: Colors.green, size: 69,));
      // Navigator.of(context).popUntil((route) => route.settings.name == ROUTE_HOME);
      Navigator.of(context).pop({'isSubmit': true});
    } else {
      h.failAlert("Gagal Memproses", "Terjadi kendala saat memproses pemasangan iklan.");
    }
  }

  _pickImages() async {
    if (_imagesEdit.length + _images.length == _maxImageSelect) {
      h.failAlert("Maksimal Foto", "Kamu bisa memasang maksimal sebanyak $_maxImageSelect foto. Upgrade akunmu untuk bisa unggah foto lebih banyak!");
      return;
    }
    var resultList = <Asset>[];
    try {
      resultList = await MultiImagePicker.pickImages(maxImages: _maxImageSelect - _imagesEdit.length - _images.length, enableCamera: true);
    } on Exception catch (e) {
      print("PICK IMAGES ERROOOOOOOOOOOOOOOOOR: $e");
    }
    print("resultList = $resultList");
    if (mounted && resultList.isNotEmpty) setState(() {
      _images.addAll(resultList);
    });
  }

  @override
  void initState() {
    _tipe = widget.args['tipe'] == 0 ? "WTS" : "WTB";
    _judulController = TextEditingController()..addListener(() => _dismissError("judul"));
    _deskripsiController = TextEditingController()..addListener(() => _dismissError("deskripsi"));
    _judulFocusNode = FocusNode();
    _deskripsiFocusNode = FocusNode();
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      var isGranted = await Permission.location.request().isGranted;
      if (isGranted) {
        var tierApi = await api('tier', data: {'uid': userSession.uid});
        var tier = UserTierModel.fromJson(tierApi.result.first);
        var listingCategoryApi = await api('listing_category', data: {'tier': tier.tier});
        setState(() {
          _listKategori = listingCategoryApi.result.map((res) => IklanKategoriModel.fromJson(res)).toList();
          _maxImageSelect = tier.maxListingPic;
          _isLoading = false;
        });
      } else {
        Navigator.of(context).pop({'isGranted': false});
      }
    });
  }

  @override
  void dispose() {
    _judulController.dispose();
    _deskripsiController.dispose();
    _judulFocusNode.dispose();
    _deskripsiFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: _isLoading ? 0 : 1,
          children: <Widget>[
            Container(child: Center(child: UiLoader())),
            Column(
              children: <Widget>[
                UiAppBar(_listTipe.where((t) => t.value == _tipe).first.label, icon: LineIcons.plus),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(THEME_PADDING),
                    child: Form(
                      key: _formKey,
                      autovalidate: false,
                      onChanged: () {},
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                        Text("Foto:", style: style.textLabel),
                        UiAvatar(_foto, size: 150, placeholder: SETUP_NONE_IMAGE, onPressed: () {}, onTapEdit: _pickImages),
                        SizedBox(height: 8.0,),
                        Text("Tipe:", style: style.textLabel),
                        SizedBox(height: 8.0,),
                        SizedBox(
                          height: 45.0,
                          child: ToggleButtons(
                            borderRadius: BorderRadius.circular(THEME_BORDER_RADIUS),
                            children: _listTipe.asMap().map((index, tipe) {
                              var isFirst = index == 0;
                              var isLast = index == _listTipe.length - 1;
                              return MapEntry(index, Row(children: <Widget>[
                                SizedBox(width: isFirst ? 20.0 : 15.0),
                                Icon(tipe.icon, size: 17,),
                                SizedBox(width: 8.0),
                                Text(tipe.label, style: TextStyle(fontSize: Theme.of(context).textTheme.bodyText1.fontSize),),
                                SizedBox(width: isLast ? 20.0 : 15.0),
                              ],));
                            }).values.toList(),
                            isSelected: _listTipe.map((t) => t.value == _tipe).toList(),
                            onPressed: (int index) {
                              setState(() {
                                _tipe = _listTipe[index].value;
                              });
                            },
                          ),
                        ),
                        SizedBox(height: 12,),
                        UiInput("Judul iklan", isRequired: true, icon: LineIcons.edit, type: UiInputType.NAME, controller: _judulController, focusNode: _judulFocusNode, error: _errorText["judul"],),
                        SizedBox(height: 4,),
                        UiInput("Deskripsi", isRequired: true, icon: LineIcons.sticky_note_o, type: UiInputType.NOTE, controller: _deskripsiController, focusNode: _deskripsiFocusNode, error: _errorText["deskripsi"],),
                        SizedBox(height: 4,),
                        Text("Kategori:", style: style.textLabel,),
                        SizedBox(height: 8,),
                        UiSelect(icon: MdiIcons.fromString(_kategori?.icon ?? 'circleOutline'), listMenu: _listKategori, initialValue: _kategori, placeholder: "Pilih kategori", onSelect: (val) {
                          setState(() { _kategori = val; });
                        },),
                        SizedBox(height: 20,),
                        UiButton("Pasang", height: style.heightButtonL, color: Colors.green, icon: LineIcons.check_circle_o, textStyle: style.textButtonL, iconRight: true, onPressed: _submit,),
                        SizedBox(height: 8,),
                      ],)
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}