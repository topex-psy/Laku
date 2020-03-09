import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
                  child: FormDaftar(),
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
  @override
  _FormDaftarState createState() => _FormDaftarState();
}

class _FormDaftarState extends State<FormDaftar> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController _emailController;
  TextEditingController _nomorPonselController;
  FocusNode _emailFocusNode;
  FocusNode _nomorPonselFocusNode;
  var _emailError = '';
  var _nomorPonselError = '';

  @override
  void initState() {
    _emailController = TextEditingController();
    _nomorPonselController = TextEditingController();
    _emailFocusNode = FocusNode();
    _nomorPonselFocusNode = FocusNode();
    super.initState();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _nomorPonselController.dispose();
    _emailFocusNode.dispose();
    _nomorPonselFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      autovalidate: false,
      onChanged: () {},
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(children: <Widget>[
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                // Text("Selamat Datang!", style: style.textTitle,),
                // SizedBox(height: 4,),
                Text("Silakan masukkan nomor ponsel untuk melanjutkan.", style: style.textWhite,),
              ],),
            ),
            SizedBox(width: 12,),
            Icon(LineIcons.user, color: Colors.white, size: 60,),
          ],),
          SizedBox(height: 20,),
          UiInput(isRequired: true, icon: LineIcons.mobile_phone, labelStyle: style.textLabelWhite, placeholder: "Nomor ponsel", type: UiInputType.PHONE, controller: _nomorPonselController, focusNode: _nomorPonselFocusNode, error: _nomorPonselError,),
          // UiInput(isRequired: true, icon: LineIcons.envelope_o, placeholder: "Alamat email", type: UiInputType.EMAIL, controller: _emailController, focusNode: _emailFocusNode, error: _emailError),
          SizedBox(height: 12,),
          SizedBox(height: style.heightButtonL, child: UiButton(label: "Lanjut", color: Colors.teal[300], textStyle: style.textButtonL, icon: LineIcons.check_circle, iconSize: 20, iconRight: true, onPressed: () async {
            var user = await api.user('get', {'NO_HP': _nomorPonselController.text});
            print(user);
            // TODO kalo user ada maka tampil form pin, else tampil form daftar
          },),),
          SizedBox(height: 12,),
          // Center(child: GestureDetector(
          //   onTap: () {
          //     setState(() {
          //       _isRegistered = !_isRegistered;
          //     });
          //   },
          //   child: Padding(
          //     padding: EdgeInsets.all(4),
          //     child: Text("${_isRegistered?'Belum':'Sudah'} punya akun?", style: style.textLink,),
          //   ),
          // ),)
          // Expanded(child: Container()),
          SizedBox(height: 30,),
          Center(child: Text("Hak cipta ©${DateTime.now().year} $APP_COPYRIGHT", style: style.textWhiteS))
        ],
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