import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:line_icons/line_icons.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';
import '../components/forms/reset_pin.dart';
import '../models/user.dart';
import '../providers/person.dart';
import '../utils/api.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../utils/styles.dart' as style;
import '../utils/widgets.dart';

class Profil extends StatefulWidget {
  Profil({Key key, this.isOpen = false}) : super(key: key);
  final bool isOpen;

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
  TextEditingController _nomorPonselController;
  FocusNode _namaLengkapFocusNode;
  FocusNode _tanggalLahirFocusNode;
  FocusNode _emailFocusNode;
  FocusNode _nomorPonselFocusNode;
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
    _nomorPonselController.text = _userData.phone;
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
      setState(() { _isEdit = false; });
      return;
    }
    setState(() {
      _errorText.clear();
      if (_namaLengkapController.text.isEmpty) _errorText["name"] = "Harap masukkan nama lengkapmu!";
      if (_emailController.text.isEmpty) _errorText["email"] = "Harap masukkan alamat emailmu!";
      else if (!f.isValidEmail(_emailController.text)) _errorText["email"] = "Harap masukkan alamat email valid!";
      if (_nomorPonselController.text.isEmpty) _errorText["phone"] = "Harap masukkan nomor ponselmu!";
    });
    if (_errorText.isNotEmpty) return;

    var email = _emailController.text;
    var phone = _nomorPonselController.text;
    var isEmailChanged = _userData.email != _emailController.text;
    var isPhoneChanged = _userData.phone != _nomorPonselController.text;
    FirebaseUser user;
    AuthCredential cred;
    if (isEmailChanged) {
      user = await a.inputPIN(_userData);
      if (user == null) return;
    }
    if (isPhoneChanged) {
      cred = await a.inputOTP(phone);
      if (cred == null) return;
    }

    final postData = <String, String>{
      'uid': userSession.uid,
      'namaLengkap': _namaLengkapController.text,
      'gender': _jenisKelamin,
      'tanggalLahir': _tanggalLahir.toString().substring(0, 10),
      'email': email,
      'phone': phone,
      'imageName': _imageName ?? '',
      'image': _image != null ? 'data:image/png;base64,' + base64Encode(_image.readAsBytesSync()) : '',
    };

    h.loadAlert();
    var postApi = await api('user', sub1: 'profile', type: 'post', data: postData);
    h.closeDialog();

    if (postApi.isSuccess) {
      var updatedProfile = UserModel.fromJson(postApi.result.first);
      var person = Provider.of<PersonProvider>(context, listen: false);
      person.setPerson(
        namaDepan: updatedProfile.namaDepan,
        namaBelakang: updatedProfile.namaBelakang,
        jenisKelamin: updatedProfile.jenisKelamin,
        tanggalLahir: updatedProfile.tanggalLahir,
        email: updatedProfile.email,
        foto: updatedProfile.foto,
      );
      a.firebaseUpdateProfile(
        namaLengkap: updatedProfile.namaLengkap,
        foto: updatedProfile.foto
      );
      if (isEmailChanged) a.firebaseUpdateEmail(email);
      if (isPhoneChanged) a.firebaseUpdatePhoneNumber(cred);
      setState(() {
        _userData = updatedProfile;
        _isEdit = false;
        _isChanged = false;
        _image = null;
      });
      Future.delayed(Duration(milliseconds: 200), () => 
        h.showFlashbarSuccess("Profil Disunting!", "Informasi profil Anda telah berhasil disimpan.")
      );
    } else {
      h.failAlert("Gagal Memproses", "Terjadi kendala saat menyimpan profil.");
    }
  }

  _resetPIN() {
    h.showAlert(title: "Ganti Nomor PIN", showButton: false, body: ResetPIN());
  }

  _viewImage() {
    var person = Provider.of<PersonProvider>(context, listen: false);
    h.viewImage(_image ?? person.foto, heroTag: "profile_pic");
  }

  _pickImage([ImageSource source]) async {
    source ??= await h.showAlert(
      title: "Unggah Foto Profil",
      showButton: false,
      body: Column(children: [ImageSource.gallery, ImageSource.camera].map((source) =>
        UiMenuList(
          isLast: source == ImageSource.camera,
          icon: {ImageSource.camera: MdiIcons.camera, ImageSource.gallery: MdiIcons.imageMultiple}[source],
          teks: {ImageSource.camera: 'Kamera', ImageSource.gallery: 'Pilih dari Galeri'}[source],
          aksi: (val) => Navigator.of(context).pop(val as ImageSource),
          value: source,
        )
      ).toList(),)
    );
    if (source == null) return;
    final pickedFile = await _imagePicker.getImage(
      source: source,
      imageQuality: IMAGE_UPLOAD_QUALITY,
      maxWidth: IMAGE_UPLOAD_SIZE,
      maxHeight: IMAGE_UPLOAD_SIZE
    );
    var image = File(pickedFile.path);
    if (image != null) {
      setState(() {
        _imageName = "${image.path.split('/scaled_').last}";
        _image = image;
      });
    }
  }

  @override
  void initState() {
    _namaLengkapController = TextEditingController()..addListener(() => _dismissError("name"));
    _emailController = TextEditingController()..addListener(() => _dismissError("email"));
    _nomorPonselController = TextEditingController()..addListener(() => _dismissError("phone"));
    _tanggalLahirController = TextEditingController();
    _jenisKelaminController = TextEditingController();
    _namaLengkapFocusNode = FocusNode();
    _emailFocusNode = FocusNode();
    _nomorPonselFocusNode = FocusNode();
    _tanggalLahirFocusNode = FocusNode();
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getAllData();
    });
  }

  @override
  void didUpdateWidget(Profil oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!oldWidget.isOpen && widget.isOpen) {
        _getAllData();
      }
    });
  }

  @override
  void dispose() {
    _namaLengkapController.dispose();
    _emailController.dispose();
    _nomorPonselController.dispose();
    _tanggalLahirController.dispose();
    _jenisKelaminController.dispose();
    _namaLengkapFocusNode.dispose();
    _emailFocusNode.dispose();
    _nomorPonselFocusNode.dispose();
    _tanggalLahirFocusNode.dispose();
    super.dispose();
  }

  // Future<bool> _onWillPop() async {
  //   FocusScope.of(context).unfocus();
  //   if (_isEdit) {
  //     var confirm = true;
  //     if (_isChanged) confirm = await h.showConfirm("Batalkan?", "Apakah Anda yakin untuk tidak menyimpan perubahan data profil?") ?? false;
  //     if (confirm) setState(() {
  //       _setInitialValues();
  //       _isChanged = false;
  //       _isEdit = false;
  //     });
  //     return false;
  //   }
  //   return true;
  // }

  // _backPressed() async {
  //   if (await _onWillPop()) Navigator.of(context).pop();
  // }

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
    return SafeArea(
      child: Column(
        children: <Widget>[
          UiAppBar("Profil Saya", icon: LineIcons.user, tool: _actionButton(), onBackPressed: () => a.navigatePage(0),),
          Expanded(
            child: IndexedStack(
              alignment: Alignment.center,
              index: _isLoading ? 0 : 1,
              children: <Widget>[
                UiLoader(),
                Container(
                  width: double.infinity,
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      children: <Widget>[
                        Row(children: <Widget>[
                          Expanded(child: _isEdit ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [ImageSource.gallery, ImageSource.camera].map((source) => UiMenuList(
                              menuPaddingHorizontal: 8,
                              isLast: source == ImageSource.camera,
                              icon: {ImageSource.camera: MdiIcons.camera, ImageSource.gallery: MdiIcons.imageMultiple}[source],
                              teks: {ImageSource.camera: 'Kamera', ImageSource.gallery: 'Pilih dari Galeri'}[source],
                              value: source,
                              aksi: (val) => _pickImage(val as ImageSource),
                            )).toList(),
                          ) : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(_userData?.namaLengkap ?? '', style: style.textHeadline,),
                              Divider(color: Colors.grey[400],),
                              Text(_userData?.email ?? '',),
                            ],
                          ),),
                          UiAvatar(
                            _image ?? person.foto,
                            heroTag: "profile_pic",
                            size: 140,
                            onPressed: _viewImage,
                            onTapEdit: _isEdit ? () => _pickImage() : null,
                          ),
                        ],),
                        Padding(
                          padding: EdgeInsets.only(right: 15.0),
                          child: Form(
                            key: _formKey,
                            autovalidate: false,
                            onChanged: () {
                              if (!_isChanged) setState(() {
                                _isChanged = true;
                              });
                            },
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                              _isEdit
                                ? UiInput("Nama lengkap", isRequired: true, icon: LineIcons.user, type: UiInputType.NAME, controller: _namaLengkapController, focusNode: _namaLengkapFocusNode, error: _errorText["name"],)
                                : SizedBox(),
                              UiInput("Nomor Ponsel", isRequired: true, readOnly: !_isEdit, icon: LineIcons.mobile_phone, type: UiInputType.PHONE, controller: _nomorPonselController, focusNode: _nomorPonselFocusNode, error: _errorText["phone"],),
                              _isEdit
                                ? UiInput("Alamat email", isRequired: true, icon: LineIcons.envelope_o, type: UiInputType.EMAIL, controller: _emailController, focusNode: _emailFocusNode, error: _errorText["email"],)
                                : SizedBox(),
                              UiInput("Tanggal lahir", isRequired: true, readOnly: !_isEdit, icon: LineIcons.calendar, type: UiInputType.DATE_OF_BIRTH, initialValue: _tanggalLahir ?? person.tanggalLahir, controller: _tanggalLahirController, focusNode: _tanggalLahirFocusNode, error: _errorText["dob"], onChanged: (val) {
                                try {
                                  setState(() { _tanggalLahir = val as DateTime; });
                                } catch (e) {
                                  print("DATETIME PICKER ERROR = $e");
                                }
                              },),
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
                              // TODO edit profil (kontak)
                              _isEdit ? SizedBox() : UiButton("Ganti Nomor PIN", height: style.heightButtonL, color: Colors.teal[300], icon: LineIcons.unlock_alt, textStyle: style.textButton, iconRight: true, onPressed: _resetPIN,),
                              SizedBox(height: 12,),
                              _isEdit ? SizedBox() : UiButton("Keluar", height: style.heightButtonL, color: Colors.red, icon: LineIcons.sign_out, textStyle: style.textButton, iconRight: true, onPressed: a.logout,),
                              SizedBox(height: 12,),
                            ],)
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}