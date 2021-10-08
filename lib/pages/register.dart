import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:local_auth/local_auth.dart';
import '../utils/api.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../utils/models.dart';
import '../utils/widgets.dart';
import '../utils/variables.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage(this.args, {Key? key}) : super(key: key);
  final Map<String, dynamic> args;

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> with TickerProviderStateMixin {

  final _nameController = TextEditingController();
  final _dobController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _scrollController = ScrollController();
  final _passwordFocus = FocusNode();
  final _errorText = <String, String>{};

  var _isLoading = false;
  var _loadingText = "";
  var _loadingProgress = 0.0;
  var _step = 0;
  var _gender = genderOptions.first;
  var _confirmPassword = "";
  var _enableFingerprint = false;

  dynamic _userPic;
  // Position? _position;
  late String _method;

  _dismissError(String tag) {
    if (_errorText.containsKey(tag)) {
      setState(() {
        _errorText.remove(tag);
      });
    }
  }

  _browsePicture(ImageSource source) async {
    var resultList = await u!.takePicture(source, maxSelect: 1);
    setState(() {
      _userPic = resultList.first;
    });
  }

  _register() async {
    _errorText.clear();
    if (_step < 1) {
      setState(() {
        if (_nameController.text.isEmpty) {
          _errorText["name"] = "Isi nama lengkapmu!";
        }
        if (_dobController.text.isEmpty) {
          _errorText["dob"] = "Isi tanggal lahirmu!";
        }
      });
      if (_errorText.isNotEmpty) {
        print("REGISTER ERRORS 1: $_errorText");
        return;
      }
      setState(() {
        _step++;
      });
      _scrollController.jumpTo(0);
      return;
    }
    setState(() {
      if (_passwordController.text.length < SETUP_MAX_LENGTH_PIN) {
        _errorText["password"] = "Isi PIN sebanyak $SETUP_MAX_LENGTH_PIN digit!";
      }
      if (!f!.isValidEmail(_emailController.text)) {
        _errorText["email"] = "Isi alamat email valid!";
      }
    });
    if (_errorText.isNotEmpty) {
      print("REGISTER ERRORS 2: $_errorText");
      return;
    }

    // konfirmasi pin baru
    _confirmPassword = await u!.promptPIN(title: "Coba masukkan PIN sekali lagi!", showForgot: false, showUsePassword: false) ?? "";
    print("confirmPassword: $_confirmPassword");
    if (_confirmPassword.isEmpty) return;
    if (_confirmPassword != _passwordController.text) {
      h!.showCallbackDialog("PIN dan konfirmasi PIN tidak sesuai!", type: MyCallbackType.warning);
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
    });

    // aktivasi fingerprint
    final localAuth = LocalAuthentication();
    if (await localAuth.isDeviceSupported()) {
      try {
        if (await localAuth.canCheckBiometrics) {
          List<BiometricType> availableBiometrics = await localAuth.getAvailableBiometrics();
          if (availableBiometrics.contains(BiometricType.fingerprint)) {
            _enableFingerprint = await h!.showConfirmDialog(
              "Ingin mengaktifkan login dengan sidik jari?",
              title: "Aktivasi Fingerprint",
              rejectText: "Lewati",
            ) ?? false;
            if (_enableFingerprint) {
              _enableFingerprint = await localAuth.authenticate(localizedReason: 'Coba tempelkan sidik jarimu untuk melanjutkan');
              await h!.showCallbackDialog(
                "Aktivasi login dengan sidik jari ${_enableFingerprint ? "berhasil" : "gagal"}."
                "${_enableFingerprint ? "" : " Kamu bisa coba lagi nanti di menu Pengaturan."}",
                type: _enableFingerprint ? MyCallbackType.success : MyCallbackType.error,
                title: "Aktivasi Fingerprint",
              );
            }
          }
        }
      } on PlatformException catch(e) {
        print("PlatformException: $e");
      }
    }

    setState(() {
      _loadingText = "Mengompresi foto";
      _loadingProgress = 0.0;
    });

    // compress image
    final compressedImage = await a.compressImage(_userPic);

    setState(() {
      _loadingText = "Menyimpan data";
      _loadingProgress = 0.0;
    });

    // post user ke db
    final registerPostData = RegisterModel(
      name: _nameController.text,
      password: _passwordController.text,
      email: _emailController.text,
      gender: _gender.value,
      dob: _dobController.text,
      // lastLatitude: _position!.latitude,
      // lastLongitude: _position!.longitude,
      image: compressedImage,
      isFingerPrint: _enableFingerprint,
      isFacebook: _method == "facebook",
    ).toJson();
    
    final registerResult = await ApiProvider(context).api('user', method: "post", data: registerPostData, withLog: true, onSendProgress: (sent, total) {
      final progress = sent / total;
      final percent = progress * 100;
      if (percent.toInt() % 10 == 0) {
        setState(() {
          _loadingProgress = progress;
        });
      }
    });
    log("REGISTER RESULT: $registerResult");
    if (registerResult.isSuccess) {
      // store user data
      profile = UserModel.fromJson(registerResult.data.first);
      // await widget.analytics.setUserId(profile!.id.toString());
      // await widget.analytics.setUserProperty(name: 'email', value: profile!.email);
      await u!.login();

      // go to dashboard
      Navigator.pushReplacementNamed(context, ROUTE_DASHBOARD, arguments: {"just_register": true});
    } else {
      _loginFail("login failed: ${registerResult.message}");
    }
  }

  _loginFail([String? devNote]) {
    if (_isLoading) {
      setState(() {
        _isLoading = false;
      });
    }
    h!.showCallbackDialog("Terjadi masalah saat mendaftar akun. Silakan coba lagi.", title: "Gagal Daftar", type: MyCallbackType.error, devNote: devNote);
    if (devNote != null) print(devNote);
  }

  Future<bool> _onWillPop() async {
    if (_step > 0) {
      setState(() {
        _step--;
      });
      _scrollController.jumpTo(0);
      return false;
    }
    return await h!.showConfirmDialog("Apakah kamu yakin ingin batal membuat akun?", title: "Batal Daftar") ?? false;
  }

  @override
  void initState() {
    _nameController.text = widget.args["name"] ?? "";
    _emailController.text = widget.args["email"];
    _userPic = widget.args["picture"];
    _method = widget.args["method"] ?? "password";
    _nameController.addListener(() { if (_nameController.text.isNotEmpty) _dismissError("name"); });
    _dobController.addListener(() { if (_dobController.text.isNotEmpty) _dismissError("dob"); });
    _passwordController.addListener(() { if (_passwordController.text.isNotEmpty) _dismissError("password"); });
    _emailController.addListener(() { if (_emailController.text.isNotEmpty) _dismissError("email"); });
    super.initState();
    WidgetsBinding.instance?.addPostFrameCallback((_) async {
      // final Position? position = await l.checkGPS();
      // if (position is Position) {
      //   setState(() {
      //     _position = position;
      //   });
      // } else {
      //   Navigator.of(context).popUntil((route) => route.isFirst);
      // }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _nameController.dispose();
    _dobController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    
    final footerWidgets = [
      const SizedBox(height: 36,),
      MyButton(tr('action_continue'), fullWidth: true, onPressed: _register),
      const SizedBox(height: 42,),
      const MyFooter(),
      const SizedBox(height: 36,),
    ];

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: APP_UI_COLOR[50]!,
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              gradient: LinearGradient(
                begin: const FractionalOffset(0.8, 0.5),
                end: const FractionalOffset(0.1, 1.0),
                colors: [
                  Colors.white.withOpacity(0.0),
                  Colors.white.withOpacity(0.25),
                  Colors.white.withOpacity(0.5),
                ],
                stops: const [
                  0.0,
                  0.5,
                  1.0,
                ]
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 6,),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(width: 15,),
                    IconButton(icon: const Icon(Icons.chevron_left_rounded), iconSize: 32, color: APP_UI_COLOR_MAIN, onPressed: () async {
                      if (await _onWillPop()) Navigator.of(context).pop();
                    },),
                    const SizedBox(width: 12,),
                    const Expanded(child: Text("Buat Akunmu", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700))),
                    const SizedBox(width: 30,),
                  ],
                ),
                const SizedBox(height: 6,),
                Expanded(
                  child: Stack(
                    children: [
                      MyWizard(
                        scrollController: _scrollController,
                        steps: [
                          ContentModel(title: "Data Diri", description: "Halo! Lengkapi data dirimu untuk dapat menggunakan aplikasi $APP_NAME."),
                          ContentModel(title: "Data Login", description: "Buat PIN 6 digit angka Anda untuk login ke aplikasi $APP_NAME."),
                        ],
                        step: _step,
                        body: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  MyAvatar(
                                    _userPic ?? DEFAULT_USER_PIC_ASSET,
                                    strokeWidth: 3,
                                    elevation: 0,
                                    size: 100.0,
                                  ),
                                  const SizedBox(width: 12,),
                                  Expanded(
                                    child: Column(
                                      children: pickImageOptions.map((menu) {
                                        final ImageSource source = menu.value;
                                        return MyMenuList(
                                          isLast: source == ImageSource.camera,
                                          menu: MenuModel(menu.label, source, icon: menu.icon, onPressed: () {
                                            _browsePicture(source);
                                          }),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20,),
                              MyInputField(label: 'Nama Lengkap', inputType: MyInputType.NAME, controller: _nameController, error: _errorText["name"]),
                              const SizedBox(height: 20,),
                              MyInputField(label: 'Tanggal Lahir', inputType: MyInputType.BIRTHDATE, controller: _dobController, error: _errorText["dob"]),
                              const SizedBox(height: 20,),
                              MyToggleButton(options: genderOptions, selected: _gender, onSelect: (index) {
                                setState(() {
                                  _gender = genderOptions[index];
                                });
                              }),
                              ...footerWidgets,
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _method == "facebook" ? const SizedBox() : MyInputField(
                                label: 'Email',
                                inputType: MyInputType.EMAIL,
                                controller: _emailController,
                                error: _errorText["email"],
                                editMode: true,
                              ),
                              const SizedBox(height: 20,),
                              MyInputField(
                                label: 'Buat PIN',
                                inputType: MyInputType.PIN,
                                controller: _passwordController,
                                focusNode: _passwordFocus,
                                error: _errorText["password"]
                              ),
                              ...footerWidgets,
                            ],
                          ),
                        ],
                      ),
                      MyLoader(isLoading: _isLoading, message: _loadingText, progress: _loadingProgress,),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}