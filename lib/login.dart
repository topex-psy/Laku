import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_analytics/observer.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:code_input/code_input.dart';
import 'package:laku/providers/person.dart';
import 'package:line_icons/line_icons.dart';
import 'package:provider/provider.dart';
import 'utils/api.dart' as api;
import 'utils/constants.dart';
import 'utils/helpers.dart';
import 'utils/styles.dart' as style;
import 'utils/widgets.dart';

const AUTO_VERIFY_TIMEOUT = 60;
const RESEND_CODE_TIMEOUT = 10;
const SMS_CODE_LENGTH = 6;

class Login extends StatefulWidget {
  Login({Key key, @required this.analytics, @required this.observer, this.arguments}) : super(key: key);
  final FirebaseAnalytics analytics;
  final FirebaseAnalyticsObserver observer;
  final Map arguments;

  @override
  _LoginState createState() => _LoginState(analytics, observer);
}

class _LoginState extends State<Login> {
  _LoginState(this.analytics, this.observer);
  final FirebaseAnalytics analytics;
  final FirebaseAnalyticsObserver observer;

  var _isSplashDone = false;
  var _isLoading = false;
  var _isWillExit = false;

  @override
  void initState() {
    bool _noSplash = widget.arguments.containsKey('noSplash') && widget.arguments['noSplash'];
    _isSplashDone = _noSplash;
    super.initState();

    // set orientation menjadi portrait untuk sementara
    try {
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    } on PlatformException {
      print("setPreferredOrientations FAILEEEEEEEEEEEED");
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(FocusNode());
      if (!_noSplash) _splashScreen();
    });
  }

  @override
  void dispose() {
    // SystemChrome.setPreferredOrientations([
    //   DeviceOrientation.landscapeRight,
    //   DeviceOrientation.landscapeLeft,
    //   DeviceOrientation.portraitUp,
    //   DeviceOrientation.portraitDown,
    // ]);
    super.dispose();
  }

  _splashScreen() async {
    // Map results = await Navigator.of(context).push(MaterialPageRoute(builder: (_) => Splash(analytics: analytics, observer: observer,)));
    final results = await Navigator.of(context).pushNamed(ROUTE_SPLASH);
    print(results);
    setState(() {
      _isSplashDone = true;
      _isLoading = true;
    });
    _getCurrentUser();
  }

  _getCurrentUser() async {
    if (!_isLoading) setState(() { _isLoading = true; });
    final user = await firebaseAuth.currentUser();
    if (user == null) setState(() { _isLoading = false; }); else {
      FocusScope.of(context).requestFocus(FocusNode());
      var person = Provider.of<PersonProvider>(context, listen: false);
      // TODO FIXME fetch user data, set personprovider
      // TODO ke form daftar kalo fetch not found
      var userApi = await api.user('get', {'uid': user.uid});
      print(" ==> GET USER RESULT: $userApi");

      person.setPerson(
        namaDepan: 'Taufik',
        namaBelakang: 'Nur Rahmanda',
        foto: null,
        isSignedIn: true,
      );

      currentPersonUid = user.uid;
      // Map results = await Navigator.of(context).push(MaterialPageRoute(settings: RouteSettings(name: ROUTE_HOME), builder: (_) => Home()));
      final results = await Navigator.of(context).pushNamed(ROUTE_HOME);
      setState(() {
        _isLoading = false;
      });
      print(results);
    }
  }

  @override
  Widget build(BuildContext context) {
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
          child: SingleChildScrollView(
            reverse: true,
            padding: EdgeInsets.all(30),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
              SizedBox(height: 30,),
              Center(child: GestureDetector(
                onTap: _splashScreen,
                child: Hero(
                  tag: "SplashLogo",
                  child: Opacity(
                    opacity: _isSplashDone ? 1 : 0,
                    child: Semantics(
                      label: "Logo $APP_NAME",
                      image: true,
                      child: Image.asset('images/logo.png', width: _logoSize, height: _logoSize, fit: BoxFit.contain,),
                    ),
                  ),
                ),
              ),),
              SizedBox(height: 30,),
              IndexedStack(
                index: _isLoading ? 0 : 1,
                alignment: Alignment.center,
                children: <Widget>[
                  UiLoader(loaderColor: Colors.white, textStyle: style.textWhite,),
                  Offstage(
                    offstage: !_isSplashDone,
                    child: Consumer<PersonProvider>(
                      builder: (context, person, child) {
                        return (person.isSignedIn ?? false) ? Container() : FormDaftar(
                          setLoading: (val) {
                            if (_isLoading != val) setState(() {
                              _isLoading = val;
                            });
                          },
                          getCurrentUser: _getCurrentUser
                        );
                      },
                    ),
                  ),
                ],
              )
            ],),
          ),
        ),
      ),
    );
  }
}

class FormDaftar extends StatefulWidget {
  FormDaftar({Key key, @required this.setLoading, @required this.getCurrentUser}) : super(key: key);
  final void Function(bool) setLoading;
  final VoidCallback getCurrentUser;

  @override
  _FormDaftarState createState() => _FormDaftarState();
}

class _FormDaftarState extends State<FormDaftar> {
  final _formKey = GlobalKey<FormState>();
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

  _signInWithCode(String smsCode) {
    if (smsCode.length < SMS_CODE_LENGTH) return;
    print(" ==> _signInWithCode ...\n$_smsVerificationCode\n$smsCode");
    FocusScope.of(context).requestFocus(FocusNode());
    widget.setLoading(true);
    var authCredential = PhoneAuthProvider.getCredential(verificationId: _smsVerificationCode, smsCode: smsCode);
    firebaseAuth.signInWithCredential(authCredential).catchError((error) {
      print("SIGNIN WITH CODE ERROR: $error");
    }).then((AuthResult authResult) {
      print("SIGNIN WITH CODE SUCCESS: ${authResult.user.uid}");
      _cekUserUID(authResult.user.uid);
    });
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
      SizedBox(height: style.heightButtonL, child: UiButton(label: "OK", color: Colors.teal[300], textStyle: style.textButtonL, icon: LineIcons.check_circle, iconSize: 20, iconRight: true, onPressed: () {},),),
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
      // SizedBox(height: 30,),
      // Copyright()
    ];
    var _formDaftar = <Widget>[
      Row(children: <Widget>[
        Expanded(child: Text("Silakan masukkan nomor ponsel untuk melanjutkan.", style: style.textWhite,),),
        SizedBox(width: 12,),
        Icon(LineIcons.user, color: Colors.white, size: 60,),
      ],),
      SizedBox(height: 20,),
      UiInput(isRequired: true, icon: LineIcons.mobile_phone, labelStyle: style.textLabelWhite, placeholder: "Nomor ponsel", type: UiInputType.PHONE, controller: _nomorPonselController, focusNode: _nomorPonselFocusNode, error: _nomorPonselError,),
      SizedBox(height: 12,),
      SizedBox(height: style.heightButtonL, child: UiButton(label: "Lanjut", color: Colors.teal[300], textStyle: style.textButtonL, icon: LineIcons.check_circle, iconSize: 20, iconRight: true, onPressed: () {
        _verifyPhoneNumber(context);
      },),),
      SizedBox(height: 42,),
      Copyright()
    ];
    return Form(
      key: _formKey,
      autovalidate: false,
      onChanged: () {},
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _smsVerificationCode.isEmpty ? _formDaftar : _formVerifikasi,
      ),
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