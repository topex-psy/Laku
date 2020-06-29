import 'dart:async';

import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:multi_image_picker/multi_image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'extensions/widget.dart';
import 'models/basic.dart';
import 'models/iklan.dart';
import 'models/user.dart';
import 'providers/settings.dart';
import 'utils/api.dart';
import 'utils/constants.dart';
import 'utils/helpers.dart';
import 'utils/styles.dart' as style;
import 'utils/upload.dart';
import 'utils/widgets.dart';

class Pasang extends StatefulWidget {
  Pasang(this.args, {Key key}) : super(key: key);
  final Map args;

  @override
  _PasangState createState() => _PasangState();
}

class _PasangState extends State<Pasang> {
  var _imagesEdit = <String>[];
  var _images = <Asset>[];
  var _isChanged = false;
  var _isLoading = true;
  var _isLoadingCategory = true;
  var _errorText = <String, String>{};
  var _listKelompok = <IklanKelompokModel>[];
  var _listKategori = <IklanKategoriModel>[];
  var _stepIndex = 0;

  final _formKey = GlobalKey<FormState>();
  final _listTipe = <IconLabel>[
    IconLabel(LineIcons.bullhorn, "Pasang Iklan", value: 'WTS'),
    IconLabel(LineIcons.search, "Cari Sesuatu", value: 'WTB'),
  ];
  final _listSteps = <IconLabel>[
    IconLabel(LineIcons.edit, "Detail Iklan"),
    IconLabel(LineIcons.users, "Sasaran"),
  ];

  TextEditingController _judulController;
  TextEditingController _deskripsiController;
  TextEditingController _hargaController;
  FocusNode _judulFocusNode;
  FocusNode _deskripsiFocusNode;
  FocusNode _hargaFocusNode;

  UserTierModel _tier;
  IklanKelompokModel _kelompok;
  IklanKategoriModel _kategori;
  String _tipe;
  var _isNegotiable = false;

  _dismissError(String tag) {
    if (_errorText.containsKey(tag)) setState(() {
      _errorText.remove(tag);
    });
  }

  _submit() async {
    if (_stepIndex == 0) {
      setState(() {
        _stepIndex = 1;
      });
      return;
    }
    if (_images.isEmpty) {
      h.failAlert("Tambahkan Foto", "Unggah minimal 1 foto untuk iklan Anda.");
      return;
    }
    if (_kelompok == null) {
      h.failAlert("Pilih Kategori", "Harap pilih kategori iklan Anda.");
      return;
    }

    final hash = DateTime.now().millisecondsSinceEpoch;
    final postData = <String, String>{
      'uid': userSession.uid,
      'tipe': _tipe,
      'judul': _judulController.text,
      'deskripsi': _deskripsiController.text,
      'harga': _hargaController.text,
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
    int byteProgress = 0;

    uploadImages('listing', _images, hash).then((response) {
      print("IMAGES UPLOAD RESPONSE: $response");
      if (response == null) {
        h.failAlertInternet(message: "Terjadi masalah saat mengunggah foto transaksi Anda. Coba lagi nanti!");
      } else {
        print("IMAGES UPLOAD CONTENT LENGTH: ${response.contentLength}");
        print("IMAGES UPLOAD STATUS CODE: ${response.statusCode}");
        print("IMAGES UPLOAD HEADERS: ${response.headers}");
        response.stream.transform(
          // utf8.decoder
          StreamTransformer.fromHandlers(
            handleData: (data, sink) {
              byteCount += data.length;
              print(" -> byteCount: $byteCount / ${response.contentLength}");
              sink.add(data);
            },
            handleError: (error, stack, sink) {},
            handleDone: (sink) {
              sink.close();
            },
          ),
        ).listen((value) {
          print("IMAGES UPLOAD PROGRESS: $value");
          byteProgress += value.length;
          print("IMAGES UPLOAD PROGRESS CURRENT: $byteProgress / ${response.contentLength}");
        }).onDone(() {
          print("IMAGES UPLOAD DONE");
          print("IMAGES UPLOAD BYTE COUNT: $byteCount");
          print("IMAGES UPLOAD BYTE PROGRESS: $byteProgress");
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
    if (_imagesEdit.length + _images.length == _tier.maxListingPic) {
      h.failAlert("Maksimal Foto", "Kamu bisa memasang maksimal sebanyak ${_tier.maxListingPic} foto. Upgrade akunmu untuk bisa unggah foto lebih banyak!");
      return;
    }
    var resultList = <Asset>[];
    try {
      resultList = await MultiImagePicker.pickImages(maxImages: _tier.maxListingPic - _imagesEdit.length - _images.length, enableCamera: true);
    } on Exception catch (e) {
      print("PICK IMAGES ERROOOOOOOOOOOOOOOOOR: $e");
    }
    print("resultList = $resultList");
    if (mounted && resultList.isNotEmpty) setState(() {
      _images.addAll(resultList);
    });
  }

  _loadCategory() async {
    setState(() {
      _isLoadingCategory = true;
    });
    var listingCategoryApi = await api('listing_category', data: {'tier': _tier});
    var listKategori = listingCategoryApi.result.map((res) => IklanKategoriModel.fromJson(res)).toList();
    var listKelompok = <int, IklanKelompokModel>{};
    listKategori.forEach((kat) {
      listKelompok[kat.idKelompok] = IklanKelompokModel(
        id: kat.idKelompok,
        judul: kat.kelompok,
        icon: kat.iconKelompok,
        isWTS: kat.isWTS,
        isWTB: kat.isWTB,
        isPriceable: kat.isPriceable,
        isScheduleable: kat.isScheduleable,
      );
    });
    setState(() {
      _listKelompok = listKelompok.values.toList();
      _listKategori = listKategori;
      _isLoadingCategory = false;
      _resetKategori();
    });
  }

  _resetKategori() {
    _kelompok = null;
    _kategori = null;
  }

  _clearKategori() {
    setState(_resetKategori);
  }

  List<Widget> _selectKelompok() {
    return _listKelompok
    .where((k) => _tipe == "WTS" ? k.isWTS : k.isWTB)
    .map((kelompok) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Card(elevation: 1, shape: CircleBorder(), clipBehavior: Clip.antiAlias, child: InkWell(
            child: Container(width: 60, height: 60, child: Center(child: Icon(MdiIcons.fromString(kelompok.icon ?? 'circleOutline'), size: 30, color: THEME_COLOR))),
            onTap: () => setState(() { _kelompok = kelompok; }),
          )),
          SizedBox(height: 3),
          Text(kelompok.judul, textAlign: TextAlign.center, style: TextStyle(fontSize: 13)),
        ],
      );
    }).toList();
  }

  Widget _selectKategori() {
    if (_isLoadingCategory) return Icon(MdiIcons.formatListBulleted, color: Colors.grey, size: 100,).shimmerIt();
    return Wrap(
      spacing: _kelompok == null ? 12 : 0,
      runSpacing: _kelompok == null ? 12 : 5,
      children: _kelompok == null ? _selectKelompok() : (
        <Widget>[
          Padding(
            padding: EdgeInsets.only(bottom: 4.0),
            child: Material(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              elevation: 0,
              color: style.colorSplash,
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                splashColor: style.colorSplash,
                highlightColor: style.colorSplash,
                onTap: _clearKategori,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 5.0),
                  child: Row(children: <Widget>[
                    Icon(MdiIcons.chevronLeft),
                    SizedBox(width: 8,),
                    Expanded(child: GestureDetector(
                      child: Text(_kelompok.judul, style: TextStyle(fontWeight: FontWeight.bold)),
                      onTap: _clearKategori,
                    )),
                  ],),
                ),
              ),
            ),
          )
          // Container(
          //   width: MediaQuery.of(context).size.width - 60,
          //   child: Row(children: <Widget>[
          //     IconButton(icon: Icon(MdiIcons.chevronLeft), onPressed: _clearKategori,),
          //     Expanded(child: GestureDetector(
          //       child: Text(_kelompok.judul, style: TextStyle(fontWeight: FontWeight.bold)),
          //       onTap: _clearKategori,
          //     )),
          //   ],),
          // ),
        ]
        ..addAll(_listKategori.where((kat) => kat.idKelompok == _kelompok.id).map((kat) => _chipKategori(kat))?.toList() ?? [])
        // ..add(_chipKategori())
      ),
    );
  }

  Widget _chipKategori([IklanKategoriModel kat]) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
      clipBehavior: Clip.antiAlias,
      color: _kategori == kat ? THEME_COLOR : Colors.white,
      child: InkWell(
        onTap: () => setState(() { _kategori = _kategori == kat ? null : kat; }),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
            Icon(MdiIcons.fromString(kat?.icon ?? 'circleOutline'), size: 20, color: _kategori == kat ? Colors.white : THEME_COLOR),
            SizedBox(width: 5,),
            Text(kat?.judul ?? 'Lainnya', style: TextStyle(color: _kategori == kat ? Colors.white : Colors.black)),
          ],),
        ),
      ),
    );
  }

  @override
  void initState() {
    _tipe = screenPageController.page.round() == 0 ? "WTS" : "WTB";
    _judulController = TextEditingController()..addListener(() => _dismissError("judul"));
    _deskripsiController = TextEditingController()..addListener(() => _dismissError("deskripsi"));
    _hargaController = TextEditingController()..addListener(() => _dismissError("harga"));
    _judulFocusNode = FocusNode();
    _deskripsiFocusNode = FocusNode();
    _hargaFocusNode = FocusNode();
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      var isGranted = await Permission.location.request().isGranted;
      if (isGranted) {
        var tierApi = await api('user_tier', data: {'uid': userSession.uid});
        var tier = UserTierModel.fromJson(tierApi.result.first);
        setState(() {
          _tier = tier;
          _isLoading = false;
        });
        _loadCategory();
      } else {
        Navigator.of(context).pop({'isGranted': false});
      }
    });
  }

  @override
  void dispose() {
    _judulController.dispose();
    _deskripsiController.dispose();
    _hargaController.dispose();
    _judulFocusNode.dispose();
    _deskripsiFocusNode.dispose();
    _hargaFocusNode.dispose();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    FocusScope.of(context).unfocus();
    if (_stepIndex > 0) {
      setState(() {
        _stepIndex--;
      });
      return false;
    }
    if (_isChanged || _images.isNotEmpty) return await h.showConfirm("Batalkan Iklan", "Apakah Anda yakin ingin membatalkan pemasangan iklan ini?") ?? false;
    return true;
  }

  _backPressed() async {
    if (await _onWillPop()) Navigator.of(context).pop();
  }

  bool get _isPriceable => _kelompok?.isPriceable ?? false; // jual-beli, jasa
  bool get _isConditionable => _kelompok?.id == 1 ?? false; // jual-beli
  bool get _isScheduleable => _kelompok?.isScheduleable ?? false; // acara, loker

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        body: SafeArea(
          child: IndexedStack(
            index: _isLoading ? 0 : 1,
            children: <Widget>[
              Container(child: Center(child: UiLoader())),
              Column(
                children: <Widget>[
                  UiCaption(steps: _listSteps, currentIndex: _stepIndex, stepAction: (index) {}, backButton: true, onBackPressed: _backPressed,),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(THEME_PADDING),
                      child: Form(
                        key: _formKey,
                        autovalidate: false,
                        onChanged: () {
                          _isChanged = true;
                        },
                        child: Column(children: <Widget>[

                          Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: _stepIndex == 0 ? <Widget>[
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
                                    _resetKategori();
                                  });
                                },
                              ),
                            ),
                            SizedBox(height: 12,),

                            Text("Foto:", style: style.textLabel),
                            SizedBox(height: 8.0,),
                            UiDropImages(
                              onTap: _pickImages,
                              onDeleteImage: (Asset asset) => setState(() { _images.remove(asset); }),
                              listImages: _images,
                              maxImages: _tier?.maxListingPic,
                              height: 200,
                            ),
                            SizedBox(height: 12.0,),

                            UiInput("Judul iklan", isRequired: true, icon: LineIcons.edit, type: UiInputType.NAME, controller: _judulController, focusNode: _judulFocusNode, error: _errorText["judul"],),
                            // SizedBox(height: 4,),

                            UiInput("Deskripsi", isRequired: true, height: 100, icon: LineIcons.sticky_note_o, type: UiInputType.NOTE, controller: _deskripsiController, focusNode: _deskripsiFocusNode, error: _errorText["deskripsi"],),
                            // SizedBox(height: 4,),

                            _isPriceable ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                RichText(text: TextSpan(
                                  style: Theme.of(context).textTheme.bodyText1,
                                  children: <TextSpan>[
                                    TextSpan(text: 'Harga: ', style: style.textLabel),
                                    TextSpan(text: '(Opsional)', style: style.textLabelGrey),
                                  ],
                                ),),
                                SizedBox(height: 8,),
                                Row(
                                  children: <Widget>[
                                    Expanded(child: UiInput("Harga", showLabel: false, icon: LineIcons.tag, type: UiInputType.CURRENCY, controller: _hargaController, focusNode: _hargaFocusNode, error: _errorText["harga"],)),
                                    Container(
                                      width: 150,
                                      child: CheckboxListTile(
                                        activeColor: Colors.green,
                                        controlAffinity: ListTileControlAffinity.leading,
                                        dense: true,
                                        title: Text("Bisa nego"),
                                        value: _isNegotiable,
                                        onChanged: (val) {
                                          setState(() { _isNegotiable = val; });
                                        },
                                      ),
                                    ),
                                    // TODO kondisi barang baru/bekas
                                  ],
                                ),
                              ],
                            ) : SizedBox(),
                            // SizedBox(height: 4,),

                            // TODO _isScheduleable

                            Text("Kategori:", style: style.textLabel),
                            SizedBox(height: 12,),
                            // TODO fetch api recent kategori
                            _selectKategori(),
                          ] : <Widget>[
                          ],),
                          
                          SizedBox(height: 30,),
                          UiButton(_stepIndex == 0 ? "Selanjutnya" : "Pasang Iklan", height: style.heightButtonL, color: Colors.green, icon: _stepIndex == 0 ? LineIcons.chevron_circle_right : LineIcons.check_circle_o, textStyle: style.textButtonL, iconRight: true, onPressed: _submit,),

                          // Text("Kategori:", style: style.textLabel,),
                          // SizedBox(height: 8,),
                          // UiSelect(icon: MdiIcons.fromString(_kategori?.icon ?? 'viewList'), listMenu: _listKategori, initialValue: _kategori, placeholder: "Pilih kategori", onSelect: (val) {
                          //   setState(() { _kategori = val; });
                          // },),
                          SizedBox(height: 20,),
                        ],)
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}