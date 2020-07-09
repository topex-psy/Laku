import 'dart:async';

import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:multi_image_picker/multi_image_picker.dart';
import 'package:numberpicker/numberpicker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'extensions/string.dart';
import 'extensions/widget.dart';
import 'models/basic.dart';
import 'models/iklan.dart';
import 'models/toko.dart';
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

class _PasangState extends State<Pasang> with TickerProviderStateMixin {
  var _imagesEdit = <String>[];
  var _images = <Asset>[];
  var _isChanged = false;
  var _isLoading = true;
  var _isLoadingCategory = true;
  var _isLoadingShop = true;
  var _errorText = <String, String>{};
  var _listKelompok = <IklanKelompokModel>[];
  var _listKategori = <IklanKategoriModel>[];
  var _listShop = <TokoModel>[];
  var _listJarakAntar = ["100m", "500m", "< 1km", "< 2km", "< 5km", "< 10km"];
  var _stepIndex = 0;

  final _formKey = GlobalKey<FormState>();
  final _listTipe = <IconLabel>[
    IconLabel(LineIcons.edit, "Pasang Iklan", value: 'WTS'),
    IconLabel(LineIcons.bullhorn, "Broadcast", value: 'WTB'),
  ];
  final _listKondisi = <IconLabel>[
    IconLabel(LineIcons.check_circle_o, "Baru", value: 'new'),
    IconLabel(LineIcons.warning, "Bekas", value: 'used'),
  ];
  final _listKetersediaan = <IconLabel>[
    IconLabel(LineIcons.check_circle_o, "Sedia", value: 'tersedia'),
    IconLabel(LineIcons.warning, "Terbatas", value: 'terbatas'),
    IconLabel(LineIcons.hourglass_o, "PO", value: 'preorder'),
  ];
  final _listSteps = <IconLabel>[
    IconLabel(LineIcons.edit, "Detail Iklan"),
    IconLabel(LineIcons.users, "Pratinjau"),
  ];

  TextEditingController _judulController;
  TextEditingController _deskripsiController;
  TextEditingController _hargaController;
  TextEditingController _stokController;
  FocusNode _judulFocusNode;
  FocusNode _deskripsiFocusNode;
  FocusNode _hargaFocusNode;
  FocusNode _stokFocusNode;

  UserTierModel _tier;
  IklanKelompokModel _kelompok;
  IklanKategoriModel _kategori;
  var _tipe = "WTS";
  var _isNegotiable = false;
  var _isAvailable = true;
  var _isDeliverable = false;
  var _isAdult = false;
  var _deskripsiLength = 0;
  String _kondisi;
  String _jarakAntar;
  String _tipeKetersediaan = 'terbatas';
  String _stokUnit;
  String _preOrderUnit;
  int _preOrderDurasi;
  DateTime _jadwalMulai;
  DateTime _jadwalAkhir;
  TokoModel _shop;
  IklanModel _edit;

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
    if (_images.isEmpty && _tipe == "WTS") {
      h.failAlert("Tambahkan Foto", "Unggah minimal 1 foto untuk iklan Anda.");
      return;
    }
    if (_kelompok == null || _kategori == null) {
      h.failAlert("Pilih Kategori", "Harap pilih kategori iklan Anda.");
      return;
    }
    if (_shop == null) {
      if (_listShop.length > 1) {
        h.failAlert("Pilih Lokasi", "Harap pilih titik lokasi iklan Anda.");
        return;
      } else {
        _shop = _listShop.first;
      }
    }

    final hash = _edit == null ? DateTime.now().millisecondsSinceEpoch : _edit.hashCode;
    final postData = <String, String>{
      'id': _edit?.id.toString(),
      'idShop': _shop.id.toString(),
      'uid': userSession.uid,
      'tipe': _tipe,
      'judul': _judulController.text,
      'deskripsi': _deskripsiController.text,
      'harga': _hargaController.text.nominal.toString(),
      'isNego': _isNegotiable.toString(),
      'isTersedia': _isAvailable.toString(),
      'isCOD': _isDeliverable.toString(),
      'isDewasa': _isAdult.toString(),
      'kondisi': _kondisi,
      'tipeKetersediaan': _tipeKetersediaan,
      'preOrderDurasi': _preOrderDurasi.toString(),
      'preOrderUnit': _preOrderUnit,
      'stok': _stokController.text,
      'stokUnit': _stokUnit,
      'jarakAntar': _isDeliverable ? _jarakAntar : null,
      'idKategori': _kategori.id.toString(),
      'mulai': f.formatDate(_jadwalMulai, format: 'yyyy-MM-dd hh:mm:ss'),
      'akhir': f.formatDate(_jadwalAkhir, format: 'yyyy-MM-dd hh:mm:ss'),
      'hash': hash.toString(),
      'picCount': _images.length.toString(),
      'imagesEdit': _imagesEdit.join('|'),
    };
    print(" ... POST DATA: $postData");
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
      Navigator.of(context).pop({'isSubmit': true});
    } else {
      h.failAlert("Gagal Memproses", "Terjadi kendala saat memproses pemasangan iklan.");
    }
  }

  int get _selectedPicsTotal => _imagesEdit.length + _images.length;
  int get _maxAllowedDesc => _tier?.maxListingDesc ?? 500;
  int get _maxAllowedPic => _tier?.maxListingPic ?? IMAGE_UPLOAD_MAX;

  _pickImages() async {
    if (_selectedPicsTotal == _maxAllowedPic) {
      h.failAlert("Maksimal Foto", "Kamu bisa memasang maksimal sebanyak ${_maxAllowedPic} foto. Upgrade akunmu untuk bisa unggah foto lebih banyak!");
      return;
    }
    var images = <Asset>[];
    try {
      images = await MultiImagePicker.pickImages(
        maxImages: _maxAllowedPic - _imagesEdit.length,
        selectedAssets: _images,
        enableCamera: true
      );
    } on Exception catch (e) {
      print("PICK IMAGES ERROOOOOOOOOOOOOOOOOR: $e");
    }
    print("resultList = $images");
    if (mounted && images.isNotEmpty) setState(() {
      _images = images;
    });
  }

  _loadData([bool online = false]) async {
    if (_edit == null) {
      if (_isLoading) setState(() {
        _isLoading = false;
      });
      return;
    }
    var listing = _edit;
    if (online) {
      if (!_isLoading) setState(() {
        _isLoading = true;
      });
      var listingApi = await api('listing', data: {'uid': userSession.uid, 'id': _edit.id});
      listing = IklanModel.fromJson(listingApi.result.first);
    }
    if (mounted) setState(() {
      _tipe = listing.tipe;
      _judulController.text = listing.judul;
      _deskripsiController.text = listing.deskripsi;
      _kondisi = listing.kondisi;
      _hargaController.text = f.formatNumber(listing.harga);
      _stokController.text = f.formatNumber(listing.stok);
      _stokUnit = listing.stokUnit;
      _preOrderDurasi = listing.preOrder;
      _preOrderUnit = listing.preOrderUnit;
      _kategori = _listKategori.where((kat) => kat.id == listing.idKategori).toList().first;
      _kelompok = _listKelompok.where((group) => group.id == _kategori.idKelompok).toList().first;
      _imagesEdit = listing.foto.map((pic) => pic.foto).toList();
      _isAvailable = listing.isTersedia;
      _isDeliverable = listing.layananAntar != null;
      _isNegotiable = listing.isNego;
      _jarakAntar = listing.layananAntar;
      _shop = _listShop.firstWhere((shop) => shop.id == listing.idShop);
      _tipeKetersediaan = listing.tipeKetersediaan;
      _jadwalMulai = listing.jadwalMulai;
      _jadwalAkhir = listing.jadwalAkhir;
      _isLoading = false;
    });
  }

  Future<void> _loadShop() async {
    if (!_isLoadingShop) setState(() {
      _isLoadingShop = true;
    });
    var shopApi = await api('shop', data: {'uid': userSession.uid, 'mode': 'mine'});
    if (mounted) setState(() {
      _listShop = shopApi.result.map((shop) => TokoModel.fromJson(shop)).toList();
      _isLoadingShop = false;
    });
  }

  Future<void> _loadCategory() async {
    if (!_isLoadingCategory) setState(() {
      _isLoadingCategory = true;
    });
    var listingCategoryApi = await api('listing_category', data: {'tier': _tier.tier});
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
    if (mounted) setState(() {
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
          ),
          ...(_listKategori.where((kat) => kat.idKelompok == _kelompok.id).map((kat) => _chipKategori(kat))?.toList() ?? []),
          // _chipKategori()
        ]
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
    _tipe = widget.args['tipe'];
    _edit = widget.args['edit'];
    _tier = userTiers[userSession.tier];
    _judulController = TextEditingController()..addListener(() => _dismissError("judul"));
    _deskripsiController = TextEditingController()..addListener(() {
      _dismissError("deskripsi");
      setState(() {
        _deskripsiLength = _deskripsiController.text.length;
      });
    });
    _hargaController = TextEditingController()..addListener(() => _dismissError("harga"));
    _stokController = TextEditingController()..addListener(() => _dismissError("stok"));
    _judulFocusNode = FocusNode();
    _deskripsiFocusNode = FocusNode();
    _hargaFocusNode = FocusNode();
    _stokFocusNode = FocusNode();
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      var isGranted = await Permission.location.request().isGranted;
      if (isGranted) {
        Future.wait([
          _loadShop(),
          _loadCategory()
        ]).then((_) => _loadData());
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
    _stokController.dispose();
    _judulFocusNode.dispose();
    _deskripsiFocusNode.dispose();
    _hargaFocusNode.dispose();
    _stokFocusNode.dispose();
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
    if (_isChanged || _images.isNotEmpty) return await h.showConfirm("Batalkan ${_edit == null ? 'Iklan' : 'Edit'}", "Apakah Anda yakin ingin membatalkan ${_edit == null ? 'pemasangan' : 'penyuntingan'} iklan ini?") ?? false;
    return true;
  }

  _backPressed() async {
    if (await _onWillPop()) Navigator.of(context).pop();
  }

  String get _title => _edit == null ? _listTipe.firstWhere((tipe) => tipe.value == _tipe, orElse: () => _listTipe.first).label : "Sunting Iklan";

  bool get _isBuyAndSell => _kelompok?.id == 1 ?? false; // jual-beli
  bool get _isPriceable => _kelompok?.isPriceable ?? false; // jual-beli, jasa
  bool get _isScheduleable => _kelompok?.isScheduleable ?? false; // acara, loker

  double get _myRadius => _tier?.radius?.toDouble() ?? 10000;

  Widget _formKetersediaan(String tipe) {
    switch (tipe) {
      case 'terbatas': return Container(padding: EdgeInsets.only(top: 12), child: Row(children: <Widget>[
        SizedBox(width: 100, child: UiInput("Stok", showLabel: false, type: UiInputType.NUMBER, controller: _stokController, focusNode: _stokFocusNode, error: _errorText["stok"],),),
        SizedBox(width: 12,),
        UiSelect(
          placeholder: "Pilih satuan",
          simple: true,
          isDense: true,
          listMenu: <String>['Pcs', 'Pack', 'Roll', 'Kg', 'm2', 'm3'],
          initialValue: _stokUnit,
          onSelect: (val) {
            setState(() { _stokUnit = val; });
          },
        ),
      ],),);
      case 'preorder': return Container(child: Row(children: <Widget>[
        NumberPicker.integer(
          initialValue: _preOrderDurasi ?? 1,
          itemExtent: 40.0,
          minValue: 1,
          maxValue: 30,
          infiniteLoop: false,
          onChanged: (val) => setState(() {
            _preOrderDurasi = val;
          })
        ),
        UiSelect(
          placeholder: "Pilih durasi",
          simple: true,
          isDense: true,
          listMenu: <String>['Hari', 'Minggu', 'Bulan'],
          initialValue: _preOrderUnit,
          onSelect: (val) {
            setState(() { _preOrderUnit = val; });
          },
        ),
      ],),);
      default: return SizedBox(height: 8,);
    }
  }

  Widget get _inputPrice {
    return _isPriceable ? Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // Text("Harga:", style: style.textLabel),
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
          ],
        ),
      ],
    ) : SizedBox();
  }

  Widget get _inputCondition {
    return _isBuyAndSell ? Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text("Kondisi:", style: style.textLabel),
        SizedBox(height: 8.0,),
        UiToggleButton(
          height: 45.0,
          listItem: _listKondisi,
          currentValue: _kondisi,
          onSelect: (int index) {
            setState(() {
              _kondisi = _listKondisi[index].value;
            });
          },
        ),
        SizedBox(height: 12,),
      ],
    ) : SizedBox();
  }

  Widget get _inputAvailable {
    return _isBuyAndSell ? Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text("Ketersediaan:", style: style.textLabel),
        SizedBox(height: 12.0,),
        UiSwitch(label: "Produk tersedia", value: _isAvailable, onToggle: (val) {
          setState(() {
            _isAvailable = val;
          });
        },),
        SizedBox(height: 16.0,),
        AnimatedSize(
          vsync: this,
          duration: Duration(milliseconds: 500),
          curve: Curves.easeOut,
          child: _isAvailable ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              UiToggleButton(
                height: 45.0,
                listItem: _listKetersediaan,
                currentValue: _tipeKetersediaan,
                onSelect: (int index) {
                  setState(() {
                    _tipeKetersediaan = _listKetersediaan[index].value;
                  });
                },
              ),
              _formKetersediaan(_tipeKetersediaan),
              SizedBox(height: 4,),
            ],
          ) : Container(),
        ),
      ],
    ) : SizedBox();
  }

  Widget get _inputDelivery {
    return _isPriceable ? Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text("Layanan COD:", style: style.textLabel),
        SizedBox(height: 12.0,),
        // TODO default ikuti setting toko
        UiSwitch(label: "Bisa COD", value: _isDeliverable, onToggle: (val) {
          setState(() {
            _isDeliverable = val;
          });
        },),
        SizedBox(height: 16.0,),
        AnimatedSize(
          vsync: this,
          duration: Duration(milliseconds: 500),
          curve: Curves.easeOut,
          child: _isDeliverable ? Container(
            padding: EdgeInsets.only(bottom: 12.0),
            child: UiSelect(listMenu: _listJarakAntar, initialValue: _jarakAntar, placeholder: "Pilih jarak", onSelect: (val) {
              setState(() { _jarakAntar = val; });
            },),
          ) : Container(),
        ),
      ],
    ) : SizedBox();
  }
  
  Widget get _inputAdult {
    return _isPriceable ? Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text("Konten Dewasa:", style: style.textLabel),
        SizedBox(height: 12.0,),
        // TODO default ikuti setting toko
        UiSwitch(label: "Unsur dewasa (18+)", value: _isAdult, onToggle: (val) {
          setState(() {
            _isAdult = val;
          });
        },),
        SizedBox(height: 16.0,),
      ],
    ) : SizedBox();
  }

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
                  UiCaption(
                    title: _title,
                    steps: _listSteps,
                    currentIndex: _stepIndex,
                    stepAction: (index) {},
                    backButton: true,
                    onBackPressed: _backPressed,
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      // padding: EdgeInsets.all(THEME_PADDING),
                      child: Form(
                        key: _formKey,
                        autovalidate: false,
                        onChanged: () {
                          _isChanged = true;
                        },
                        child: Column(children: <Widget>[

                          _edit != null ? SizedBox() : UiSection(children: <Widget>[
                            // Text("Tipe Iklan", style: style.textTitle,),
                            // SizedBox(height: 12.0,),
                            // Text("Tipe:", style: style.textLabel),
                            // SizedBox(height: 8.0,),
                            Row(
                              children: <Widget>[
                                Expanded(
                                  child: UiToggleButton(
                                    height: 45.0,
                                    listItem: _listTipe,
                                    currentValue: _tipe,
                                    onSelect: (int index) {
                                      setState(() {
                                        _tipe = _listTipe[index].value;
                                        _resetKategori();
                                      });
                                    },
                                  ),
                                ),
                                _tipe == 'WTS' ? SizedBox() : Padding(
                                  padding: EdgeInsets.only(left: 8.0),
                                  child: Icon(MdiIcons.tagMinusOutline, color: THEME_COLOR),
                                ),
                              ],
                            ),
                            SizedBox(height: 12),
                            Text(_tipe == 'WTS' ? "Pasang iklan yang dapat ditemukan oleh pengguna $APP_NAME di radius ${f.distanceLabel(_myRadius)} dari Anda kapanpun." : "Broadcast adalah siaran yang berlangsung selama 24 jam kepada semua pengguna $APP_NAME di radius ${f.distanceLabel(_myRadius)} dari Anda. Broadcast membutuhkan 1 tiket toa yang Anda miliki.", style: style.textS)
                          ]),

                          UiSection(
                            title: "Unggah Foto",
                            tool: _tier == null ? SizedBox() : Container(
                              padding: EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                              decoration: BoxDecoration(
                                color: Colors.teal[200].withOpacity(.2),
                                borderRadius: BorderRadius.circular(8)
                              ),
                              child: Text('$_selectedPicsTotal/${_maxAllowedPic}', style: style.textB)
                            ),
                            children: <Widget>[
                              UiDropImages(
                                onPickImage: _pickImages,
                                onTapImage: (asset) {
                                  if (asset is String) h.viewImage(_imagesEdit, page: _imagesEdit.indexOf(asset));
                                },
                                onDeleteImage: (asset) => setState(() {
                                  if (asset is String) _imagesEdit.remove(asset);
                                  else _images.remove(asset);
                                }),
                                listImagesEdit: _imagesEdit,
                                listImages: _images,
                                maxImages: _maxAllowedPic,
                                height: 200,
                              ),
                            ]
                          ),

                          UiSection(title: "Detail Iklan", titleSpacing: 20, children: <Widget>[
                            UiInput("Judul iklan", isRequired: true, icon: LineIcons.edit, type: UiInputType.NAME, controller: _judulController, focusNode: _judulFocusNode, error: _errorText["judul"],),
                            UiInput("Deskripsi", isRequired: true, margin: EdgeInsets.zero, maxLength: _maxAllowedDesc, placeholder: "Tulis deskripsi iklan dengan jelas dan lengkap ...", height: 100, icon: LineIcons.sticky_note_o, type: UiInputType.NOTE, controller: _deskripsiController, focusNode: _deskripsiFocusNode, error: _errorText["deskripsi"],),
                            Row(
                              children: <Widget>[
                                Expanded(child: Padding(
                                  padding: EdgeInsets.only(top: 12.0),
                                  child: Text("Kategori:", style: style.textLabel),
                                )),
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black38,
                                    borderRadius: BorderRadius.circular(8)
                                  ),
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  child: Text("${f.formatNumber(_deskripsiLength)}/${f.formatNumber(_maxAllowedDesc)}", style: style.textWhiteMB)
                                ),
                              ],
                            ),
                            SizedBox(height: 12,),
                            // TODO fetch api recent kategori
                            _selectKategori(),
                          ]),

                          _isBuyAndSell || _isPriceable || _isScheduleable ? UiSection(title: "Info Lainnya", titleSpacing: 20, children: <Widget>[
                            _inputPrice,
                            _inputCondition,
                            _inputAvailable,
                            _inputDelivery,
                            _inputAdult,
                            // TODO _isScheduleable
                          ]) : SizedBox(),

                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 20.0),
                            child: Copyright(
                              prefix: "Anda wajib memperhatikan",
                              suffix: "sebelum memasang iklan ini",
                              showCopyright: false,
                              colorText: Colors.grey,
                              colorLink: THEME_COLOR,
                              textAlign: TextAlign.center
                            ),
                          ),

                          Padding(
                            padding: EdgeInsets.all(20.0),
                            child: UiButton(
                              _stepIndex == 0 ? "Selanjutnya" : (_tipe == 'WTS' ? "Pasang Iklan" : "Siarkan"),
                              height: style.heightButtonL,
                              textStyle: style.textButtonL,
                              color: Colors.green,
                              icon: _stepIndex == 0 ? LineIcons.chevron_circle_right : LineIcons.check_circle_o,
                              iconRight: true,
                              onPressed: _submit,
                            ),
                          ),
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