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
  TextEditingController _jenisKelaminController;
  FocusNode _namaLengkapFocusNode;
  FocusNode _tanggalLahirFocusNode;
  FocusNode _emailFocusNode;
  var _errorText = <String, String>{};
  var _isLoading = true;
  var _isChanged = false;
  var _isEdit = false;

  var _jenisKelamin = 'L';
  DateTime _tanggalLahir;
  String _imageName;
  File _image;
  UserModel _userData;

  _getAllData() async {
    var userApi = await api('user', data: {'uid': userSession.uid});
    if (mounted) {
      setState(() {
        _userData = UserModel.fromJson(userApi.result.first);
        _setInitialValues();
        _isLoading = false;
      });
    }
  }
  
  _dismissError(String tag) {
    if (_errorText.containsKey(tag)) setState(() {
      _errorText.remove(tag);
    });
  }

  _setInitialValues() {
    _namaLengkapController.text = _userData.namaLengkap;
    _emailController.text = _userData.email;
    _jenisKelaminController.text = _userData.jenisKelaminLengkap;
    _tanggalLahirController.text = f.formatDate(_userData.tanggalLahir);
    _tanggalLahir  = _userData.tanggalLahir;
    _jenisKelamin  = _userData.jenisKelamin;
  }

  _edit() {
    setState(() {
      _setInitialValues();
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
      'tanggalLahir': _tanggalLahir.toString().substring(0, 10),
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

  _changePassword() {
    // TODO modal change password
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
    _jenisKelaminController = TextEditingController();
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
    _jenisKelaminController.dispose();
    _namaLengkapFocusNode.dispose();
    _emailFocusNode.dispose();
    _tanggalLahirFocusNode.dispose();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    FocusScope.of(context).unfocus();
    // if (_isEdit) return await h.showConfirm("Batalkan?", "Apakah Anda yakin untuk tidak menyimpan perubahan data profil?") ?? false;
    if (_isEdit) {
      var confirm = true;
      if (_isChanged) confirm = await h.showConfirm("Batalkan?", "Apakah Anda yakin untuk tidak menyimpan perubahan data profil?") ?? false;
      if (confirm) setState(() {
        _isChanged = false;
        _isEdit = false;
      });
      return false;
    }
    return true;
  }

  _backPressed() async {
    if (await _onWillPop()) Navigator.of(context).pop();
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
    var person = Provider.of<PersonProvider>(context, listen: false);
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
                  UiAppBar("Profil Saya", icon: LineIcons.user, tool: _actionButton(), onBackPressed: _backPressed),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.only(left: 20, right: 20, top: 15, bottom: 30,),
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
                          Row(children: <Widget>[
                            Expanded(child: _isEdit ? Column(
                              children: [ImageSource.gallery, ImageSource.camera].map((source) => UiMenuList(
                                menuPaddingHorizontal: 8,
                                isLast: source == ImageSource.camera,
                                icon: {ImageSource.camera: MdiIcons.camera, ImageSource.gallery: MdiIcons.imageMultiple}[source],
                                teks: {ImageSource.camera: 'Kamera', ImageSource.gallery: 'Pilih dari Galeri'}[source],
                                value: source,
                                aksi: (val) => _pickImage(val as ImageSource),
                              )).toList(),
                            ) : Column(
                              children: <Widget>[
                                Text(_userData?.namaLengkap ?? '', style: style.textHeadline,),
                                Divider(color: Colors.grey[400],),
                                Text(_userData?.email ?? '',),
                              ],
                            ),),
                            UiAvatar(
                              _image ?? person.foto,
                              size: 150,
                              onPressed: _viewImage,
                              onTapEdit: _isEdit ? () => _pickImage() : null,
                            ),
                          ],),
                          _isEdit
                            ? UiInput("Nama lengkap", isRequired: true, icon: LineIcons.user, type: UiInputType.NAME, controller: _namaLengkapController, focusNode: _namaLengkapFocusNode, error: _errorText["name"],)
                            : SizedBox(),
                          SizedBox(height: 4,),
                          _isEdit
                            ? UiInput("Alamat email", isRequired: true, icon: LineIcons.envelope_o, type: UiInputType.EMAIL, controller: _emailController, focusNode: _emailFocusNode, error: _errorText["email"],)
                            : SizedBox(),
                          SizedBox(height: 4,),
                          UiInput("Tanggal lahir", isRequired: true, readOnly: !_isEdit, icon: LineIcons.calendar, type: UiInputType.DATE_OF_BIRTH, initialValue: _tanggalLahir ?? person.tanggalLahir, controller: _tanggalLahirController, focusNode: _tanggalLahirFocusNode, error: _errorText["dob"], onChanged: (val) {
                            try {
                              setState(() { _tanggalLahir = val as DateTime; });
                            } catch (e) {
                              print("DATETIME PICKER ERROR = $e");
                            }
                          },),
                          SizedBox(height: 4,),
                          Text("Jenis kelamin:", style: style.textLabel),
                          SizedBox(height: 8.0,),
                          _isEdit ? SizedBox(
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
                          ) : UiInput("", showLabel: false, readOnly: true, icon: LineIcons.male, controller: _jenisKelaminController,),
                          SizedBox(height: 30,),
                          _isEdit ? SizedBox() : UiButton("Ganti Password", width: 250, height: style.heightButton, color: Colors.teal[300], icon: LineIcons.unlock_alt, textStyle: style.textButton, iconRight: true, onPressed: _changePassword,),
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