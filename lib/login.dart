import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:code_input/code_input.dart';
import 'package:line_icons/line_icons.dart';
import 'utils/api.dart' as api;
import 'utils/constants.dart';
import 'utils/helpers.dart';
import 'utils/styles.dart' as style;
import 'utils/widgets.dart';
import 'home.dart';
import 'splash.dart';

class Login extends StatefulWidget {
  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  var _isSplashDone = false;
  var _isLoading = false;

  @override
  void initState() {
    super.initState();
    try {
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    } on PlatformException {
      print("setPreferredOrientations FAILEEEEEEEEEEEED");
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _splashScreen();
    });
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  _splashScreen() async {
    Map results = await Navigator.of(context).push(MaterialPageRoute(builder: (_) => Splash()));
    print(results);
    setState(() {
      _isSplashDone = true;
      _isLoading = true;
    });
    _getCurrentUser();
  }

  _getCurrentUser() async {
    final user = await firebaseAuth.currentUser();
    if (user == null) {
      setState(() {
        _isLoading = false;
      });
    } else {
      var userApi = await api.user('get', {'FIREBASE_UID': user.uid});
      print(userApi);
      Map results = await Navigator.of(context).push(MaterialPageRoute(builder: (_) => Home()));
      print(results);
    }
  }

  @override
  Widget build(BuildContext context) {
    initializeHelpers(context, "after init _LoginState");
    var _logoSize = h.screenSize.height * 0.25;
    return Scaffold(
      backgroundColor: THEME_COLOR,
      body: SafeArea(
        child: SingleChildScrollView(
          reverse: true,
          padding: EdgeInsets.all(30),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
            SizedBox(height: 30,),
            Center(child: GestureDetector(
              onTap: () {
                _splashScreen();
              },
              child: Hero(
                tag: "SplashLogo",
                child: Semantics(
                  label: "Logo $APP_NAME",
                  image: true,
                  child: Image.asset('images/logo.png', width: _logoSize, height: _logoSize, fit: BoxFit.contain,),
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
                  child: FormDaftar(setLoading: (val) {
                    if (_isLoading != val) setState(() {
                      _isLoading = val;
                    });
                  }),
                ),
              ],
            )
          ],),
        ),
      ),
    );
  }
}

class FormDaftar extends StatefulWidget {
  FormDaftar({Key key, @required this.setLoading}) : super(key: key);
  final void Function(bool) setLoading;

  @override
  _FormDaftarState createState() => _FormDaftarState();
}

class _FormDaftarState extends State<FormDaftar> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController _emailController;
  TextEditingController _nomorPonselController;
  TextEditingController _smsCodeController;
  FocusNode _emailFocusNode;
  FocusNode _nomorPonselFocusNode;
  FocusNode _smsCodeFocusNode;
  var _emailError = '';
  var _nomorPonselError = '';
  var _smsCodeError = '';
  var _smsVerificationCode = '';

  @override
  void initState() {
    _emailController = TextEditingController();
    _nomorPonselController = TextEditingController();
    _smsCodeController = TextEditingController();
    _emailFocusNode = FocusNode();
    _nomorPonselFocusNode = FocusNode();
    _smsCodeFocusNode = FocusNode();
    super.initState();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _nomorPonselController.dispose();
    _smsCodeController.dispose();
    _emailFocusNode.dispose();
    _nomorPonselFocusNode.dispose();
    _smsCodeFocusNode.dispose();
    super.dispose();
  }

  _verifyPhoneNumber(BuildContext context) async {
    String phoneNumber = "+62${_nomorPonselController.text}";
    widget.setLoading(true);
    await firebaseAuth.verifyPhoneNumber(
      verificationCompleted: (authCredential) => _verificationComplete(authCredential, context),
      verificationFailed: (authException) => _verificationFailed(authException, context),
      codeAutoRetrievalTimeout: (verificationId) => _codeAutoRetrievalTimeout(verificationId),
      codeSent: (verificationId, [code]) => _smsCodeSent(verificationId, [code]),
      timeout: Duration(seconds: 10),
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
    setState(() {
      _smsVerificationCode = verificationId;
    });
    widget.setLoading(false);
  }

  _codeAutoRetrievalTimeout(String verificationId) {
    print("PHONE AUTH CODE TIMEOUT: $verificationId");
    setState(() {
      _smsVerificationCode = verificationId;
    });
    widget.setLoading(false);
  }

  _signInWithCode(String smsCode) {
    var authCredential = PhoneAuthProvider.getCredential(verificationId: _smsVerificationCode, smsCode: smsCode);
    widget.setLoading(true);
    firebaseAuth.signInWithCredential(authCredential).catchError((error) {
      print("SIGNIN WITH CODE ERROR: $error");
    }).then((AuthResult authResult) {
      print("SIGNIN WITH CODE SUCCESS: ${authResult.user.uid}");
      _cekUserUID(authResult.user.uid);
    });
  }

  _cekUserUID(String uid) async {
    var user = await api.user('get', {'FIREBASE_UID': uid});
    widget.setLoading(false);
    print(user);
    // TODO kalo user ada maka tampil form pin, else tampil form daftar
  }

  @override
  Widget build(BuildContext context) {
    var _formVerifikasi = <Widget>[
      Row(children: <Widget>[
        Expanded(child: Text("Silakan masukkan kode verifikasi yang terkirim di kotak masuk SMS.", style: style.textWhite,),),
        SizedBox(width: 12,),
        Icon(LineIcons.user, color: Colors.white, size: 60,),
      ],),
      SizedBox(height: 20,),
      Text("Kode verifikasi:", style: style.textLabel),
      CodeInput(
        length: 4,
        keyboardType: TextInputType.number,
        builder: CodeInputBuilders.lightCircle(),
        onFilled: (value) => print('Your input is $value.'),
      ),
      // UiInput(isRequired: true, icon: LineIcons.mobile_phone, labelStyle: style.textLabelWhite, placeholder: "Kode verifikasi", type: UiInputType.PASSWORD, controller: _smsCodeController, focusNode: _smsCodeFocusNode, error: _smsCodeError,),
      SizedBox(height: 12,),
      SizedBox(height: style.heightButtonL, child: UiButton(label: "OK", color: Colors.teal[300], textStyle: style.textButtonL, icon: LineIcons.check_circle, iconSize: 20, iconRight: true, onPressed: () {
        _signInWithCode(_smsCodeController.text);
      },),),
      SizedBox(height: 12,),
      Center(child: GestureDetector(
        onTap: () {
          setState(() {
            _smsVerificationCode = '';
          });
        },
        child: Padding(
          padding: EdgeInsets.all(4),
          child: Text("Tidak menerima SMS?", style: style.textLink,),
        ),
      ),),
      SizedBox(height: 30,),
      Center(child: Text("Hak cipta ©${DateTime.now().year} $APP_COPYRIGHT", style: style.textWhiteS))
    ];
    var _formDaftar = <Widget>[
      Row(children: <Widget>[
        Expanded(child: Text("Silakan masukkan nomor ponsel untuk melanjutkan.", style: style.textWhite,),),
        SizedBox(width: 12,),
        Icon(LineIcons.user, color: Colors.white, size: 60,),
      ],),
      SizedBox(height: 20,),
      UiInput(isRequired: true, icon: LineIcons.mobile_phone, labelStyle: style.textLabelWhite, placeholder: "Nomor ponsel", type: UiInputType.PHONE, controller: _nomorPonselController, focusNode: _nomorPonselFocusNode, error: _nomorPonselError,),
      // UiInput(isRequired: true, icon: LineIcons.envelope_o, placeholder: "Alamat email", type: UiInputType.EMAIL, controller: _emailController, focusNode: _emailFocusNode, error: _emailError),
      SizedBox(height: 12,),
      SizedBox(height: style.heightButtonL, child: UiButton(label: "Lanjut", color: Colors.teal[300], textStyle: style.textButtonL, icon: LineIcons.check_circle, iconSize: 20, iconRight: true, onPressed: () {
        _verifyPhoneNumber(context);
      },),),
      SizedBox(height: 42,),
      Center(child: Text("Hak cipta ©${DateTime.now().year} $APP_COPYRIGHT", style: style.textWhiteS))
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