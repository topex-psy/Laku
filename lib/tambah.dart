import 'package:flutter/material.dart';
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
  var _isGranted = false;
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
      setState(() {
        _isGranted = isGranted;
        _maxImageSelect = 3; // TODO ambil dari data user
        _isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: _isLoading ? Container(child: Center(child: UiLoader())) : SingleChildScrollView(
          padding: EdgeInsets.all(THEME_PADDING),
          // child: Content(isGranted: _isGranted,),
          child: _isGranted ? FormBarang() : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(LineIcons.info_circle, color: THEME_COLOR, size: 40,),
              SizedBox(height: 20,),
              Text("Harap izinkan aplikasi untuk mengakses lokasi Anda saat ini."),
            ],
          ),
        ),
      ),
    );
  }
}

// class Content extends StatefulWidget {
//   Content({Key key, @required this.isGranted}) : super(key: key);
//   final bool isGranted;

//   @override
//   _ContentState createState() => _ContentState();
// }

// class _ContentState extends State<Content> {
//   @override
//   Widget build(BuildContext context) {
//     return widget.isGranted ? FormBarang() : Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: <Widget>[
//         Icon(LineIcons.info_circle, color: THEME_COLOR, size: 40,),
//         SizedBox(height: 20,),
//         Text("Harap izinkan aplikasi untuk mengkakses lokasi Anda saat ini."),
//       ],
//     );
//   }
// }

class FormBarang extends StatefulWidget {
  @override
  _FormBarangState createState() => _FormBarangState();
}

class _FormBarangState extends State<FormBarang> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      autovalidate: false,
      onChanged: () {},
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
        Text("Nama barang:", style: style.textLabel,),
        Text("Harga:", style: style.textLabel,),
        Text("Kategori:", style: style.textLabel,),
        Text("Foto:", style: style.textLabel,),
        Text("Ukuran iklan:", style: style.textLabel,),
        // TODO 5 token tersisa
        UiButton("Pasang!", height: style.heightButtonL, color: Colors.green, textStyle: style.textButtonL, icon: LineIcons.check, onPressed: () {
          // TODO post item
        },),
      ],)
    );
  }
}