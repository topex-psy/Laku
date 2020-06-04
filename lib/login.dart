import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:code_input/code_input.dart';
import 'package:dio/dio.dart';
import 'package:laku/providers/person.dart';
import 'package:line_icons/line_icons.dart';
import 'package:provider/provider.dart';
import 'utils/api.dart';
import 'utils/constants.dart';
import 'utils/helpers.dart';
import 'utils/styles.dart' as style;
import 'utils/widgets.dart';

const AUTO_VERIFY_TIMEOUT = 60;
const RESEND_CODE_TIMEOUT = 10;
const SMS_CODE_LENGTH = 6;

class Login extends StatefulWidget {
  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  var _isLoading = true;
  var _isWillExit = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getCurrentUser();
    });
  }

  _getCurrentUser() async {
    FocusScope.of(context).requestFocus(FocusNode());
    if (!_isLoading) setState(() { _isLoading = true; });
    final user = await firebaseAuth.currentUser();
    if (user == null) {
      print(" ==> FIREBASE USER: NOT LOGGED IN");
      setState(() { _isLoading = false; });
    } else {
      print(" ==> FIREBASE USER: EXIST");
      Map userApi = await api('user', data: {'uid': user.uid});
      if (userApi == null) {
        setState(() { _isLoading = false; });
        return;
      }
      Map userGet = userApi['get'];
      if (userGet['TOTAL'] == 0) {
        final results = await Navigator.of(context).pushNamed(ROUTE_DAFTAR) as Map;
        if (results != null && results.containsKey('email')) {
          await auth('register', results);
        }
        _getCurrentUser();
      } else {
        Map userRes = userApi['result'][0];
        if (userRes['IS_BANNED'] == null || userRes['IS_BANNED'].isEmpty) {
          h.failAlert("Akun Terblokir", "Akunmu diblokir hingga ${f.formatDate(DateTime.parse(userRes['BAN_UNTIL']))} karena ${userRes['BAN_REASON']}");
          setState(() { _isLoading = false; });
        } else {
          var person = Provider.of<PersonProvider>(context, listen: false);
          person.setPerson(
            namaDepan: userRes['NAMA_DEPAN'],
            namaBelakang: userRes['NAMA_BELAKANG'],
            foto: userRes['FOTO'],
            isSignedIn: true,
          );
          currentPersonUid = user.uid;
          await Navigator.of(context).pushNamed(ROUTE_HOME);
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    h = UIHelper(context);
    a = UserHelper(context);
    f = FormatHelper();

    final _logoSize = MediaQuery.of(context).size.height * 0.25;
    return WillPopScope(
      onWillPop: () async {
        if (_isWillExit) return SystemChannels.platform.invokeMethod<bool>('SystemNavigator.pop');
        h.showToast("Ketuk sekali lagi untuk menutup aplikasi.");
        _isWillExit = true;
        Future.delayed(Duration(milliseconds: 2000), () { _isWillExit = false; });
        return false;
      },
      child: Scaffold(
        backgroundColor: THEME_COLOR,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              reverse: true,
              padding: EdgeInsets.all(30),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                SizedBox(height: 30,),
                Center(child: Hero(
                  tag: "SplashLogo",
                  child: Semantics(
                    label: "Logo $APP_NAME",
                    image: true,
                    child: Image.asset('images/logo.png', width: _logoSize, height: _logoSize, fit: BoxFit.contain,),
                  ),
                ),),
                SizedBox(height: 30,),
                IndexedStack(
                  index: _isLoading ? 0 : 1,
                  alignment: Alignment.center,
                  children: <Widget>[
                    UiLoader(loaderColor: Colors.white, textStyle: style.textWhite,),
                    Selector<PersonProvider, bool>(
                      selector: (buildContext, person) => person.isSignedIn,
                      builder: (context, isSignedIn, child) {
                        return (isSignedIn ?? false) ? Container() : LoginForm(
                          setLoading: (val) {
                            if (_isLoading != val) setState(() {
                              _isLoading = val;
                            });
                          },
                          getCurrentUser: _getCurrentUser
                        );
                      }
                    ),
                  ],
                )
              ],),
            ),
          ),
        ),
      ),
    );
  }
}

class LoginForm extends StatefulWidget {
  LoginForm({Key key, @required this.setLoading, @required this.getCurrentUser}) : super(key: key);
  final void Function(bool) setLoading;
  final VoidCallback getCurrentUser;

  @override
  _LoginFormState createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  TextEditingController _nomorPonselController;
  FocusNode _nomorPonselFocusNode;
  var _nomorPonselError = '';
  var _smsVerificationCode = '';
  var _showResend = false;
  var _signedIn = false;

  @override
  void initState() {
    _nomorPonselController = TextEditingController();
    _nomorPonselFocusNode = FocusNode();
    super.initState();
  }

  @override
  void dispose() {
    _nomorPonselController.dispose();
    _nomorPonselFocusNode.dispose();
    super.dispose();
  }

  _verifyPhoneNumber(BuildContext context) async {
    if (_nomorPonselController.text.isEmpty) {
      h.showFlashBar("Masukkan nomor ponsel!", "Harap masukkan nomor ponsel valid untuk login atau mendaftar ke aplikasi.");
      return;
    }
    String phoneNumber = "+62${_nomorPonselController.text}";
    FocusScope.of(context).requestFocus(FocusNode());
    widget.setLoading(true);
    await firebaseAuth.verifyPhoneNumber(
      verificationCompleted: (authCredential) => _verificationComplete(authCredential, context),
      verificationFailed: (authException) => _verificationFailed(authException, context),
      codeAutoRetrievalTimeout: (verificationId) => _codeAutoRetrievalTimeout(verificationId),
      codeSent: (verificationId, [code]) => _smsCodeSent(verificationId, [code]),
      timeout: Duration(seconds: AUTO_VERIFY_TIMEOUT),
      phoneNumber: phoneNumber,
    );
  }

  _verificationComplete(AuthCredential authCredential, BuildContext context) {
    widget.setLoading(true);
    firebaseAuth.signInWithCredential(authCredential).then((authResult) {
      print("PHONE AUTH SUCCESS: ${authResult.user.uid}");
      _cekUserUID(authResult.user.uid);
    });
  }

  _verificationFailed(AuthException authException, BuildContext context) {
    print("PHONE AUTH FAILED: ${authException.message}");
  }

  _smsCodeSent(String verificationId, List<int> code) {
    print("PHONE AUTH CODE SENT: $verificationId");
    print("PHONE AUTH CODE: $code");
    setState(() {
      _smsVerificationCode = verificationId;
      _showResend = false;
    });
    widget.setLoading(false);
  }

  _codeAutoRetrievalTimeout(String verificationId) {
    print("PHONE AUTH CODE TIMEOUT: $verificationId");
    if (!_signedIn) setState(() {
      _smsVerificationCode = '';
    });
  }

  _signInWithCode(String smsCode) async {
    if (smsCode.length < SMS_CODE_LENGTH) return;
    print(" ==> _signInWithCode ...\n$_smsVerificationCode\n$smsCode");
    FocusScope.of(context).requestFocus(FocusNode());
    widget.setLoading(true);
    var authCredential = PhoneAuthProvider.getCredential(verificationId: _smsVerificationCode, smsCode: smsCode);
    try {
      AuthResult authResult = await firebaseAuth.signInWithCredential(authCredential);
      _cekUserUID(authResult.user.uid);
    } on PlatformException catch(e) {
      print(e.code);
      print(e.message);
      print(e.toString());
      widget.setLoading(false);
      if (e.code == "ERROR_INVALID_VERIFICATION_CODE") {
        h.failAlert("Autentikasi Gagal", "Kode verifikasi salah!");
      } else {
        h.failAlert("Autentikasi Gagal", "Terjadi kesalahan saat memverifikasi kode. Silakan coba lagi.");
      }
    }
  }

  _cekUserUID(String uid) async {
    setState(() {
      _signedIn = true;
    });
    print("SIGNED IN: $uid");
    widget.getCurrentUser();
  }

  @override
  Widget build(BuildContext context) {
    var _formVerifikasi = <Widget>[
      Row(children: <Widget>[
        Expanded(child: Text("Silakan masukkan kode verifikasi yang dikirim melalui SMS.", style: style.textWhite,),),
        SizedBox(width: 12,),
        Icon(LineIcons.mobile, color: Colors.white, size: 60,),
      ],),
      SizedBox(height: 20,),
      Text("Kode verifikasi:", style: style.textLabelWhite),
      SizedBox(height: 8,),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: CodeInput(
          length: SMS_CODE_LENGTH,
          keyboardType: TextInputType.number,
          builder: CodeInputBuilders.lightCircle(),
          onFilled: _signInWithCode,
        ),
      ),
      SizedBox(height: 12,),
      SizedBox(height: style.heightButtonL, child: UiButton(label: "OK", color: Colors.teal[300], textStyle: style.textButtonXL, icon: LineIcons.check_circle, iconSize: 20, iconRight: true, onPressed: () {},),),
      SizedBox(height: 12,),
      Center(child: _showResend ? GestureDetector(
        onTap: () {
          setState(() {
            _smsVerificationCode = '';
          });
        },
        child: Padding(
          padding: EdgeInsets.all(4),
          child: Text("Tidak menerima SMS?", style: style.textWhiteS,),
        ),
      ) : Padding(
        padding: EdgeInsets.all(4),
        child: Detik("Mengirim SMS ...", duration: RESEND_CODE_TIMEOUT, onFinish: () {
          setState(() {
            _showResend = true;
          });
        }),
      ),),
    ];
    var _formNomorPonsel = <Widget>[
      Row(children: <Widget>[
        Expanded(child: Text("Silakan masukkan nomor ponsel untuk melanjutkan.", style: style.textWhite,),),
        SizedBox(width: 12,),
        Icon(LineIcons.user, color: Colors.white, size: 60,),
      ],),
      SizedBox(height: 20,),
      UiInput("Nomor ponsel", isRequired: true, autoFocus: true, icon: LineIcons.mobile_phone, labelStyle: style.textLabelWhite, type: UiInputType.PHONE, controller: _nomorPonselController, focusNode: _nomorPonselFocusNode, error: _nomorPonselError,),
      SizedBox(height: 12,),
      SizedBox(height: style.heightButtonL, child: UiButton(label: "Lanjut", color: Colors.teal[300], textStyle: style.textButtonL, icon: LineIcons.check_circle, iconRight: true, onPressed: () {
        _verifyPhoneNumber(context);
      },),),
      SizedBox(height: 42,),
      Copyright()
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _smsVerificationCode.isEmpty ? _formNomorPonsel : _formVerifikasi,
    );
  }
}

class FirstDisabledFocusNode extends FocusNode {
  @override
  bool consumeKeyboardToken() {
    return false;
  }
}

class Detik extends StatefulWidget {
  Detik(this.label, {Key key, @required this.duration, this.onFinish}) : super(key: key);
  final String label;
  final int duration;
  final VoidCallback onFinish;

  @override
  _DetikState createState() => _DetikState();
}

class _DetikState extends State<Detik> {
  int _detik;
  Timer _timer;

  @override
  void initState() {
    _detik = widget.duration;
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _timer = Timer.periodic(Duration(seconds: 1), (timer) {
        if (_detik > 0) setState(() { _detik--; }); else if (widget.onFinish != null) {
          widget.onFinish();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text("${widget.label} $_detik", style: style.textWhiteS,);
  }
}