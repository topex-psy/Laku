import 'package:flutter/material.dart';
import 'package:laku/models/iklan.dart';
import 'package:line_icons/line_icons.dart';
import 'package:multi_image_picker/multi_image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'utils/constants.dart';
import 'utils/helpers.dart';
import 'utils/styles.dart' as style;
import 'utils/widgets.dart';

class Tambah extends StatefulWidget {
  @override
  _TambahState createState() => _TambahState();
}

class _TambahState extends State<Tambah> {
  var _imagesEdit = <String>[];
  var _images = <Asset>[];
  var _isLoading = true;
  var _maxImageSelect = 3;

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
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      var isGranted = await Permission.location.request().isGranted;
      if (isGranted) {
        setState(() {
          _maxImageSelect = 3; // TODO ambil dari data user
          _isLoading = false;
        });
      } else {
        Navigator.of(context).pop({'isGranted': false});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: _isLoading ? Container(child: Center(child: UiLoader())) : SingleChildScrollView(
          padding: EdgeInsets.all(THEME_PADDING),
          child: FormIklan()
        ),
      ),
    );
  }
}

class FormIklan extends StatefulWidget {
  @override
  _FormIklanState createState() => _FormIklanState();
}

class _FormIklanState extends State<FormIklan> {
  static const tipeLbl  = <String>['Iklan', 'Cari'];
  static const tipeVal  = <String>['WTS', 'WTB'];
  final _formKey = GlobalKey<FormState>();

  TextEditingController _judulController;
  FocusNode _judulFocusNode;
  var _errorText = <String, String>{};
  var _tipe  = 'WTS';
  KategoriIklanModel _kategori;
  
  final _listKategori = <KategoriIklanModel>[
    KategoriIklanModel('Semua', LineIcons.at),
    KategoriIklanModel('Jual-Beli', LineIcons.at),
    KategoriIklanModel('Event', LineIcons.at),
    KategoriIklanModel('Loker', LineIcons.at),
    KategoriIklanModel('Jodoh', LineIcons.at),
    KategoriIklanModel('Lainnya', LineIcons.at),
  ];

  _dismissError(String tag) {
    if (_errorText.containsKey(tag)) setState(() {
      _errorText.remove(tag);
    });
  }

  @override
  void initState() {
    _judulController = TextEditingController()..addListener(() => _dismissError("name"));
    _judulFocusNode = FocusNode();
    super.initState();
  }

  @override
  void dispose() {
    _judulController.dispose();
    _judulFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      autovalidate: false,
      onChanged: () {},
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
        Text("Tipe iklan:", style: style.textLabel),
        SizedBox(height: 8.0,),
        SizedBox(
          height: 45.0,
          child: ToggleButtons(
            borderRadius: BorderRadius.circular(THEME_BORDER_RADIUS),
            children: <Widget>[
              Row(children: <Widget>[
                SizedBox(width: 20.0),
                Icon(LineIcons.male, size: 17,),
                SizedBox(width: 8.0),
                Text(tipeLbl[0], style: TextStyle(fontSize: Theme.of(context).textTheme.bodyText1.fontSize),),
                SizedBox(width: 15.0),
              ],),
              Row(children: <Widget>[
                SizedBox(width: 15.0),
                Icon(LineIcons.female, size: 17,),
                SizedBox(width: 8.0),
                Text(tipeLbl[1], style: TextStyle(fontSize: Theme.of(context).textTheme.bodyText1.fontSize),),
                SizedBox(width: 20.0),
              ],),
            ],
            isSelected: tipeVal.map((t) => t == _tipe).toList(),
            onPressed: (int index) {
              setState(() {
                _tipe = tipeVal[index];
              });
            },
          ),
        ),
        SizedBox(height: 8,),
        UiInput("Judul iklan", isRequired: true, icon: LineIcons.user, type: UiInputType.NAME, controller: _judulController, focusNode: _judulFocusNode, error: _errorText["name"],),
        Text("Kategori:", style: style.textLabel,), //jubel, jasa, loker, event, jodoh, kehilangan, lainnya
        SizedBox(height: 8,),
        UiSelect(icon: _kategori?.icon, listMenu: _listKategori, initialValue: _kategori, placeholder: "Pilih kategori", onSelect: (val) {
          setState(() { _kategori = val; });
        },),

        // Text("Foto:", style: style.textLabel,),
        // Text("Detail:", style: style.textLabel,),
        // Text("Warna pin:", style: style.textLabel,),
        SizedBox(height: 20,),
        UiButton("Pasang!", height: style.heightButtonXL, textStyle: style.textButtonXL, icon: LineIcons.check_circle_o, iconRight: true, onPressed: () {
          // TODO post item
        },),
      ],)
    );
  }
}