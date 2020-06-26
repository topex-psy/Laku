import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:line_icons/line_icons.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'models/basic.dart';
import 'models/user.dart';
import 'providers/person.dart';
import 'utils/api.dart';
import 'utils/constants.dart';
import 'utils/helpers.dart';
import 'utils/styles.dart' as style;
import 'utils/widgets.dart';

class Profil extends StatefulWidget {
  @override
  _ProfilState createState() => _ProfilState();
}

class _ProfilState extends State<Profil> {

  final _formKey = GlobalKey<FormState>();
  final _imagePicker = ImagePicker();

  TextEditingController _namaLengkapController;
  TextEditingController _tanggalLahirController;
  TextEditingController _emailController;
  FocusNode _namaLengkapFocusNode;
  FocusNode _tanggalLahirFocusNode;
  FocusNode _emailFocusNode;
  var _errorText = <String, String>{};
  var _isLoading = true;
  var _isChanged = false;
  var _isEdit = false;

  var _jenisKelamin  = 'L';
  var _tanggalLahir  = '';
  String _imageName;
  File _image;
  UserModel _userData;

  _getAllData() async {
    var userApi = await api('user', data: {'uid': userSession.uid});
    setState(() {
      _userData = UserModel.fromJson(userApi.result.first);
      _isLoading = false;
    });
  }
  
  _dismissError(String tag) {
    if (_errorText.containsKey(tag)) setState(() {
      _errorText.remove(tag);
    });
  }

  _edit() {
    setState(() {
      _isChanged = false;
      _isEdit = !_isEdit;
    });
  }

  _submit() async {
    if (!_isChanged) {
      setState(() {
        _isEdit = false;
      });
      return;
    }
    setState(() {
      _errorText.clear();
      if (_namaLengkapController.text.isEmpty) _errorText["name"] = "Harap masukkan nama lengkapmu!";
      if (_emailController.text.isEmpty) _errorText["email"] = "Harap masukkan alamat emailmu!";
    });
    if (_errorText.isNotEmpty) return;

    final postData = <String, String>{
      'uid': userSession.uid,
      'namaLengkap': _namaLengkapController.text,
      'gender': _jenisKelamin,
      'tanggalLahir': _tanggalLahir,
      'email': _emailController.text,
      'imageName': _imageName ?? '',
      'image': _image != null ? 'data:image/png;base64,' + base64Encode(_image.readAsBytesSync()) : '',
    };

    h.loadAlert();

    var postApi = await api('user', sub1: 'profile', type: 'post', data: postData);
    Navigator.of(context).pop();
    if (postApi.isSuccess) {
        var updatedProfile = UserModel.fromJson(postApi.result.first);
        a.firebaseUpdateProfile(
          namaLengkap: updatedProfile.namaLengkap,
          foto: updatedProfile.foto
        );
        setState(() {
          _isEdit = false;
          _isChanged = false;
          _image = null;
        });
      Future.delayed(Duration(milliseconds: 300), () => 
        h.showFlashbarSuccess("Profil Disunting!", "Informasi profil Anda telah berhasil disimpan.")
      );
    } else {
      h.failAlert("Gagal Memproses", "Terjadi kendala saat menyimpan profil.");
    }
  }

  _viewImage() {
    var person = Provider.of<PersonProvider>(context, listen: false);
    Navigator.of(context).pushNamed(ROUTE_IMAGE, arguments: {'image': _image ?? person.foto});
  }

  _pickImage([ImageSource source]) async {
    if (source == null) {
        source = await h.showAlert(title: "Unggah Foto Profil", showButton: false, body: Column(children: [ImageSource.gallery, ImageSource.camera].map((source) => UiMenuList(
        isLast: source == ImageSource.camera,
        icon: {ImageSource.camera: MdiIcons.camera, ImageSource.gallery: MdiIcons.imageMultiple}[source],
        teks: {ImageSource.camera: 'Kamera', ImageSource.gallery: 'Pilih dari Galeri'}[source],
        value: source,
        aksi: (val) {
          Navigator.of(context).pop(val as ImageSource);
        },
      )).toList(),));
      if (source != null) _pickImage(source);
    } else {
      final pickedFile = await _imagePicker.getImage(
        source: source,
        imageQuality: PIC_UPLOAD_QUALITY,
        maxWidth: PIC_UPLOAD_SIZE_NORMAL,
        maxHeight: PIC_UPLOAD_SIZE_NORMAL
      );
      var image = File(pickedFile.path);
      if (image != null) {
        setState(() {
          _imageName = "${image.path.split('/scaled_').last}";
          _image = image;
        });
      }
    }
  }

  @override
  void initState() {
    _namaLengkapController = TextEditingController()..addListener(() => _dismissError("name"));
    _emailController = TextEditingController()..addListener(() => _dismissError("email"));
    _tanggalLahirController = TextEditingController();
    _namaLengkapFocusNode = FocusNode();
    _emailFocusNode = FocusNode();
    _tanggalLahirFocusNode = FocusNode();
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getAllData();
      // var isGranted = await Permission.location.request().isGranted;
      // if (isGranted) {
      // } else {
      //   Navigator.of(context).pop({'isGranted': false});
      // }
    });
  }

  @override
  void dispose() {
    _namaLengkapController.dispose();
    _emailController.dispose();
    _tanggalLahirController.dispose();
    _namaLengkapFocusNode.dispose();
    _emailFocusNode.dispose();
    _tanggalLahirFocusNode.dispose();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    FocusScope.of(context).unfocus();
    if (_isEdit && _isChanged) return await h.showConfirm("Batalkan?", "Apakah Anda yakin untuk tidak menyimpan perubahan data profil?") ?? false;
    return true;
  }

  Widget _actionButton() {
    return Container(
      height: double.infinity,
      width: 60,
      child: RaisedButton(
        elevation: 0,
        child: Icon(_isEdit ? MdiIcons.check : MdiIcons.pencil, size: 30,),
        color: _isEdit ? Colors.green : Colors.teal,
        textColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        onPressed: _isEdit ? _submit : _edit,
      ),
    );
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
                  UiAppBar("Profil Saya", icon: LineIcons.user, tool: _actionButton(),),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(THEME_PADDING),
                      child: Form(
                        key: _formKey,
                        autovalidate: false,
                        onChanged: () {
                          print("FOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOORM ONCHANGED!");
                          if (!_isChanged) setState(() {
                            _isChanged = true;
                          });
                        },
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                          // Text("Foto:", style: style.textLabel),
                          Row(children: <Widget>[
                            Expanded(child: Column(
                              children: [ImageSource.gallery, ImageSource.camera].map((source) => UiMenuList(
                                isLast: source == ImageSource.camera,
                                icon: {ImageSource.camera: MdiIcons.camera, ImageSource.gallery: MdiIcons.imageMultiple}[source],
                                teks: {ImageSource.camera: 'Kamera', ImageSource.gallery: 'Pilih dari Galeri'}[source],
                                value: source,
                                aksi: (val) => _pickImage(val as ImageSource),
                              )).toList(),
                            ),),
                            Selector<PersonProvider, String>(
                              selector: (buildContext, person) => person.foto,
                              builder: (context, foto, child) => UiAvatar(
                                _image ?? foto,
                                size: 150,
                                onPressed: _viewImage,
                                onTapEdit: _isEdit ? () => _pickImage() : null,
                              ),
                            ),
                          ],),
                          // Align(
                          //   alignment: Alignment.centerRight,
                          //   child: Selector<PersonProvider, String>(
                          //     selector: (buildContext, person) => person.foto,
                          //     builder: (context, foto, child) => UiAvatar(
                          //       _image ?? foto,
                          //       size: 150,
                          //       onPressed: _viewImage,
                          //       onTapEdit: _isEdit ? () => _pickImage() : null,
                          //     ),
                          //   ),
                          // ),
                          // SizedBox(height: 20,),
                          UiInput("Nama lengkap", isRequired: true, icon: LineIcons.user, type: UiInputType.NAME, controller: _namaLengkapController, focusNode: _namaLengkapFocusNode, error: _errorText["name"],),
                          SizedBox(height: 4,),
                          UiInput("Alamat email", isRequired: true, icon: LineIcons.envelope_o, type: UiInputType.EMAIL, controller: _emailController, focusNode: _emailFocusNode, error: _errorText["email"],),
                          SizedBox(height: 4,),
                          UiInput("Tanggal lahir", isRequired: true, icon: LineIcons.calendar, type: UiInputType.DATE_OF_BIRTH, controller: _tanggalLahirController, focusNode: _tanggalLahirFocusNode, error: _errorText["dob"], onChanged: (val) {
                            try {
                              setState(() {
                                _tanggalLahir = val == null ? '' : (val as DateTime).toString().substring(0, 10);
                                if (_errorText.containsKey("dob")) _errorText.remove("dob");
                              });
                            } catch (e) {
                              print("DATETIME PICKER ERROR = $e");
                            }
                          },),
                          SizedBox(height: 4,),
                          Text("Jenis kelamin:", style: style.textLabel),
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
                                  Text(jenisKelaminLbl[0], style: TextStyle(fontSize: Theme.of(context).textTheme.bodyText1.fontSize),),
                                  SizedBox(width: 15.0),
                                ],),
                                Row(children: <Widget>[
                                  SizedBox(width: 15.0),
                                  Icon(LineIcons.female, size: 17,),
                                  SizedBox(width: 8.0),
                                  Text(jenisKelaminLbl[1], style: TextStyle(fontSize: Theme.of(context).textTheme.bodyText1.fontSize),),
                                  SizedBox(width: 20.0),
                                ],),
                              ],
                              onPressed: (int index) {
                                setState(() {
                                  _jenisKelamin = jenisKelaminVal[index];
                                });
                              },
                              isSelected: <bool>[
                                _jenisKelamin == jenisKelaminVal[0],
                                _jenisKelamin == jenisKelaminVal[1],
                              ],
                            ),
                          ),
                          // SizedBox(height: 30,),
                          // UiButton("Simpan", height: style.heightButtonL, color: Colors.green, icon: LineIcons.check_circle_o, textStyle: style.textButtonL, iconRight: true, onPressed: _submit,),
                          SizedBox(height: 12,),
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