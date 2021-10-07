import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:line_icons/line_icons.dart';
import '../../utils/api.dart';
import '../../utils/helpers.dart';
import '../../utils/models.dart';
import '../../utils/widgets.dart';
import '../../utils/variables.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key, this.isOpen = false}) : super(key: key);
  final bool isOpen;

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {

  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _dobController = TextEditingController();
  final _genderController = TextEditingController();
  final _namaFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _dobFocus = FocusNode();
  final _errorText = <String, String>{};

  var _isLoading = true;
  var _isChanged = false;
  var _isEdit = false;

  var _loadingText = "";
  var _loadingProgress = 0.0;
  var _gender = genderOptions.first;
  DateTime? _tanggalLahir;
  dynamic _image;
  UserModel? _userData;

  _getAllData() async {
    final userResult = await ApiProvider(context).api('user', method: "get", getParams: {'id': session!.id.toString()});
    if (userResult.isSuccess) {
      if (mounted) {
        setState(() {
          _userData = UserModel.fromJson(userResult.data.first);
          _setInitialValues();
          _isLoading = false;
        });
      }
    }
  }
  
  _dismissError(String tag) {
    if (_errorText.containsKey(tag)) {
      setState(() {
        _errorText.remove(tag);
      });
    }
  }

  _setInitialValues() {
    if (_userData != null) {
      _tanggalLahir  = _userData!.dob;
      _gender  = genderOptions.firstWhere((gender) => gender.value == _userData!.gender);
      _nameController.text = _userData!.name;
      _emailController.text = _userData!.email;
      _genderController.text = _gender.label;
      _phoneController.text = _userData!.phone ?? "";
      _dobController.text = f!.formatDate(_userData!.dob);
    }
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
      if (_nameController.text.isEmpty) _errorText["name"] = "Harap masukkan nama lengkapmu!";
      if (_emailController.text.isEmpty) {
        _errorText["email"] = "Harap masukkan alamat emailmu!";
      } else if (!f!.isValidEmail(_emailController.text)) {
        _errorText["email"] = "Harap masukkan alamat email valid!";
      }
      if (_phoneController.text.isEmpty) _errorText["phone"] = "Harap masukkan nomor ponselmu!";
    });
    if (_errorText.isNotEmpty) return;

    var email = _emailController.text;
    var phone = _phoneController.text;
    var isEmailChanged = _userData!.email != _emailController.text;
    var isPhoneChanged = _userData!.phone != _phoneController.text;

    User? user;
    AuthCredential? cred;
    if (isEmailChanged) {
      final pin = await u!.promptPIN();
      if (pin == null) return;
      final firebaseAuth = await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: pin);
      user = firebaseAuth.user;
      if (user == null) return;
    }
    // TODO konfirmasi no telp
    // if (isPhoneChanged) {
    //   cred = await u!.inputOTP(phone);
    //   if (cred == null) return;
    // }

    var postData = <String, String?>{
      'uid': session!.id.toString(),
      'namaLengkap': _nameController.text,
      'gender': _gender.value,
      'tanggalLahir': _tanggalLahir.toString().substring(0, 10),
      'email': email,
      'phone': phone,
    };

    if (_image != null) {
      setState(() {
        _loadingText = "Mengompresi foto";
        _loadingProgress = 0.0;
      });
      // compress image
      postData['image'] = await a.compressImage(_image);
    }

    setState(() {
      _loadingText = "Menyimpan data";
      _loadingProgress = 0.0;
    });

    final putUserResult = await ApiProvider(context).api('user', method: 'put', withLog: true, data: postData);
    if (putUserResult.isSuccess) {
      profile = UserModel.fromJson(putUserResult.data.first);

      // update firebase profile
      u!.firebaseUpdateProfile(
        name: profile!.name,
        image: _image == null ? null : profile!.image
      );
      if (isEmailChanged) u!.firebaseUpdateEmail(email);
      // TODO update phone in firebase
      // if (isPhoneChanged) u!.firebaseUpdatePhoneNumber(cred);

      setState(() {
        _userData = profile;
        _isEdit = false;
        _isChanged = false;
        _image = null;
      });

      // TODO butuh delay?
      Future.delayed(const Duration(milliseconds: 200), () {
        h!.showFlashbarSuccess("Profil Disunting!", "Informasi profil Anda telah berhasil disimpan.");
      });
    } else {
      h!.showCallbackDialog(
        "Terjadi kendala saat menyimpan profil.",
        title: "Gagal Memproses",
        type: MyCallbackType.error,
      );
    }
  }

  _resetPIN() {
    h!.showDialog(
      // TODO ResetPIN(),
      Container(),
      title: "Ganti Nomor PIN",
      showCloseButton: false,
    );
  }

  _browsePicture([ImageSource? source]) async {
    source ??= await h?.showDialog(
      Column(
        children: pickImageOptions.map((menu) {
          final ImageSource source = menu.value;
          return MyMenuList(
            isLast: source == ImageSource.camera,
            menu: MenuModel(menu.label, source, icon: menu.icon, onPressed: () {
              Navigator.of(context).pop(source);
            }),
          );
        }).toList(),
      ),
      closeButtonText: "Batal",
      buttonSize: MyButtonSize.SMALL
    );
    if (source == null) return;
    var resultList = await u!.takePicture(source, maxSelect: 1);
    setState(() {
      _image = resultList.first;
    });
  }

  @override
  void initState() {
    _nameController.addListener(() => _dismissError("name"));
    _emailController.addListener(() => _dismissError("email"));
    _phoneController.addListener(() => _dismissError("phone"));
    super.initState();
    WidgetsBinding.instance?.addPostFrameCallback((_) {
      _getAllData();
    });
  }

  @override
  void didUpdateWidget(ProfilePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance?.addPostFrameCallback((_) {
      if (!oldWidget.isOpen && widget.isOpen) {
        _getAllData();
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    _genderController.dispose();
    _namaFocus.dispose();
    _emailFocus.dispose();
    _phoneFocus.dispose();
    _dobFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Stack(
        children: <Widget>[
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Card(
              margin: const EdgeInsets.all(15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              shadowColor: Colors.grey[300],
              child: Padding(
                padding: const EdgeInsets.only(left: 15.0, right: 15.0, bottom: 15.0),
                child: Column(
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.only(left: 10.0),
                      child: Row(children: <Widget>[
                        Expanded(
                          child: _isEdit ? Column(
                            children: pickImageOptions.map((menu) {
                              final ImageSource source = menu.value;
                              return MyMenuList(
                                isLast: source == ImageSource.camera,
                                menu: MenuModel(menu.label, source, icon: menu.icon, onPressed: () {
                                  _browsePicture(source);
                                }),
                              );
                            }).toList(),
                          ) : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(_userData?.name ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),),
                              Divider(color: Colors.grey[400],),
                              Text(_userData?.email ?? '',),
                            ],
                          ),
                        ),
                        Transform.translate(
                          offset: const Offset(0, -20),
                          child: MyAvatar(
                            _image ?? _userData?.image,
                            heroTag: "profile_pic",
                            strokeWidth: 0,
                            elevation: 4,
                            size: 140.0,
                            onTapEdit: _isEdit ? _browsePicture : null,
                          ),
                        ),
                      ],),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: Form(
                        key: _formKey,
                        autovalidateMode: AutovalidateMode.disabled,
                        onChanged: () {
                          if (!_isChanged) {
                            setState(() {
                            _isChanged = true;
                          });
                          }
                        },
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                          _isEdit
                            ? MyInputField(label: 'Nama Lengkap', inputType: MyInputType.NAME, icon: LineIcons.user, controller: _nameController, focusNode: _namaFocus, error: _errorText["name"])
                            : const SizedBox(),
                          MyInputField(label: "Nomor Ponsel", readOnly: !_isEdit, icon: LineIcons.mobilePhone, inputType: MyInputType.PHONE, controller: _phoneController, focusNode: _phoneFocus, error: _errorText["phone"],),
                          _isEdit
                            ? MyInputField(label: "Alamat email", icon: LineIcons.envelope, inputType: MyInputType.EMAIL, controller: _emailController, focusNode: _emailFocus, error: _errorText["email"],)
                            : const SizedBox(),
                          MyInputField(label: "Tanggal lahir", readOnly: !_isEdit, icon: LineIcons.calendar, inputType: MyInputType.BIRTHDATE, controller: _dobController, focusNode: _dobFocus, error: _errorText["dob"],),
                          const Text("Jenis kelamin:"),
                          const SizedBox(height: 8.0,),
                          _isEdit ? MyToggleButton(options: genderOptions, selected: _gender, onSelect: (index) {
                            setState(() {
                              _gender = genderOptions[index];
                            });
                          }) : MyInputField(label: "", showLabel: false, readOnly: true, icon: LineIcons.male, controller: _genderController,),
                          const SizedBox(height: 30,),
                          MyButton(_isEdit ? "Simpan" : "Edit Profil", disabled: _userData == null, color: _isEdit ? Colors.green : Colors.blue, icon: _isEdit ? Icons.check_circle_outline : Icons.edit, iconRight: true, onPressed: _isEdit ? _submit : _edit,),
                          const SizedBox(height: 12,),
                          _isEdit ? Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: MyButton("Batalkan", color: Colors.grey[400], icon: Icons.close, iconRight: true, onPressed: _edit,),
                          ) : const SizedBox(),
                          _isEdit ? const SizedBox() : MyButton("Ganti Nomor PIN", color: Colors.teal[300], icon: Icons.keyboard, iconRight: true, onPressed: _resetPIN,),
                          const SizedBox(height: 12,),
                          _isEdit ? const SizedBox() : MyButton("Keluar", color: Colors.red, icon: Icons.logout, iconRight: true, onPressed: u!.logout,),
                          const SizedBox(height: 12,),
                        ],)
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          MyLoader(isLoading: _isLoading, message: _loadingText, progress: _loadingProgress,),
        ],
      ),
    );
  }
}