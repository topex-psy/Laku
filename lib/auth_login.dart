import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:code_input/code_input.dart';
import 'package:dio/dio.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:laku/providers/person.dart';
import 'package:line_icons/line_icons.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock/wakelock.dart';
import 'extensions/string.dart';
import 'utils/api.dart';
import 'utils/constants.dart';
import 'utils/helpers.dart';
import 'utils/styles.dart' as style;
import 'utils/widgets.dart';

import 'components/intro/page_dragger.dart';
import 'components/intro/page_reveal.dart';
import 'components/intro/pager_indicator.dart';
import 'components/intro/pages.dart';

const AUTO_VERIFY_TIMEOUT = 60;
const RESEND_CODE_TIMEOUT = 10;
const SMS_CODE_LENGTH = 6;

class Login extends StatefulWidget {
  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> with TickerProviderStateMixin {
  var _loginFormKey = Key('key');
  var _isIntroduction = false;
  var _isLoading = true;
  var _isWillExit = false;

  StreamController<SlideUpdate> slideUpdateStream;
  AnimatedPageDragger animatedPageDragger;

  var _activeIndex = 0;
  var _slideDirection = SlideDirection.none;
  var _nextPageIndex = 0;
  var _slidePercent = 0.0;

  _LoginState() {
    slideUpdateStream = StreamController<SlideUpdate>();
    slideUpdateStream.stream.listen((SlideUpdate event) {
      setState(() {
        if (event.updateType == UpdateType.dragging) {
          _slideDirection = event.direction;
          _slidePercent = event.slidePercent;

          if (_slideDirection == SlideDirection.leftToRight) {
            _nextPageIndex = _activeIndex - 1;
          } else if (_slideDirection == SlideDirection.rightToLeft) {
            _nextPageIndex = _activeIndex + 1;
          } else {
            _nextPageIndex = _activeIndex;
          }
        } else if (event.updateType == UpdateType.doneDragging) {
          if (_slidePercent > 0.333) {
            animatedPageDragger = AnimatedPageDragger(
              slideDirection: _slideDirection,
              transitionGoal: TransitionGoal.open,
              slidePercent: _slidePercent,
              slideUpdateStream: slideUpdateStream,
              vsync: this,
            );
          } else {
            animatedPageDragger = AnimatedPageDragger(
              slideDirection: _slideDirection,
              transitionGoal: TransitionGoal.close,
              slidePercent: _slidePercent,
              slideUpdateStream: slideUpdateStream,
              vsync: this,
            );
            _nextPageIndex = _activeIndex;
          }

          animatedPageDragger.run();
        } else if (event.updateType == UpdateType.animating) {
          _slideDirection = event.direction;
          _slidePercent = event.slidePercent;
        } else if (event.updateType == UpdateType.doneAnimating) {
          _activeIndex = _nextPageIndex;
          _slideDirection = SlideDirection.none;
          _slidePercent = 0.0;
          animatedPageDragger.dispose();
        }
      });
    });
  }

  @override
  void initState() {
    _activeIndex = 0;
    _slidePercent = 0.0;
    _nextPageIndex = _activeIndex;
    _isIntroduction = isFirstRun;
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(FocusNode());
      if (isFirstRun) {
        setState(() {
          print(" -> wakelock: ENABLED");
          Wakelock.enable();
        });
      } else {
        // Future.microtask(() => _getCurrentUser());
        // Future.delayed(Duration.zero, () => _getCurrentUser());
        _getCurrentUser();
      }
    });
  }

  _generateNewKey() => Key(DateTime.now().millisecondsSinceEpoch.toString());

  _getCurrentUser() async {
    FocusScope.of(context).requestFocus(FocusNode());
    if (!_isLoading) setState(() {
      _isLoading = true;
    });
    final user = await firebaseAuth.currentUser();
    if (user == null) {
      print(" ==> FIREBASE USER: NOT LOGGED IN");
      setState(() {
        // _smsVerificationCode = '';
        _loginFormKey = _generateNewKey();
        _isLoading = false;
      });
    } else {
      print(" ==> FIREBASE USER: EXIST");
      currentPerson.uid = user.uid;
      currentPerson.phone = user.phoneNumber;
      Map userApi = await api('user', data: {'uid': currentPerson.uid});
      if (userApi == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }
      Map userGet = userApi['get'];
      if (userGet['TOTAL'] == 0) {
        // user belum register
        final results = await Navigator.of(context).pushNamed(ROUTE_DAFTAR) as Map;
        // if (results != null && results.containsKey('email')) {
        //   await auth('register', results);
        // }
        print("REGISTER RESULT: $results");
        _getCurrentUser();
      } else {
        // user sudah register
        Map<String, String> userRes = Map.from(userApi['result'][0]);
        if (userRes['IS_BANNED'].isEmptyOrNull) {
          var person = Provider.of<PersonProvider>(context, listen: false);
          person.setPerson(
            namaDepan: userRes['NAMA_DEPAN'],
            namaBelakang: userRes['NAMA_BELAKANG'],
            foto: userRes['FOTO'],
            isSignedIn: true,
          );
          await Navigator.of(context).pushNamed(ROUTE_HOME);
          setState(() {
            _loginFormKey = _generateNewKey();
            _isLoading = false;
          });
        } else {
          h.failAlert("Akun Terblokir", "Akunmu diblokir hingga ${f.formatDate(DateTime.parse(userRes['BAN_UNTIL']))} karena ${userRes['BAN_REASON']}");
          setState(() { _isLoading = false; });
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
    final _imageWidth = MediaQuery.of(context).size.width * 0.69;
    final _pages = [
      PageViewModel(
        color: Colors.purple[400],
        hero: Image.asset('images/onboarding/1.png', width: _imageWidth,),
        // hero: SvgPicture.asset('images/onboarding/1.svg', width: imageWidth,),
        // heroTag: 'SplashLogo',
        icon: LineIcons.tags,
        title: 'Banyak Barang',
        body: 'Apakah kamu sering buang duit untuk berbelanja barang-barang yang gak penting?',
      ),
      PageViewModel(
        color: Colors.green[400],
        hero: Image.asset('images/onboarding/2.png', width: _imageWidth,),
        // hero: SvgPicture.asset('images/onboarding/2.svg', width: imageWidth,),
        icon: LineIcons.mobile_phone,
        title: 'Jangan Bingung',
        body: 'Beritahu orang-orang kalau kamu punya barang-barang itu. Mungkin mereka lebih butuh.',
      ),
      PageViewModel(
        color: Colors.teal[400],
        hero: Image.asset('images/onboarding/3.png', width: _imageWidth,),
        // hero: SvgPicture.asset('images/onboarding/3.svg', width: imageWidth,),
        icon: LineIcons.cloud,
        title: 'Jadikan Duit!',
        body: 'Pasang iklan apa saja seperti produk baru, bekas, bisnis, jasa, loker, kos-kosan. Semua bisa!',
      ),
    ];
    return WillPopScope(
      onWillPop: () async {
        if (_isIntroduction && _activeIndex > 0) {
          setState(() {
            animatedPageDragger = AnimatedPageDragger(
              slideDirection: SlideDirection.leftToRight,
              transitionGoal: TransitionGoal.open,
              slidePercent: 0.0,
              slideUpdateStream: slideUpdateStream,
              vsync: this,
            );
            _nextPageIndex = _activeIndex - 1;
            animatedPageDragger.run();
          });
          return false;
        }
        if (_isWillExit) return SystemChannels.platform.invokeMethod<bool>('SystemNavigator.pop');
        h.showToast("Ketuk sekali lagi untuk menutup aplikasi.");
        _isWillExit = true;
        Future.delayed(Duration(milliseconds: 2000), () { _isWillExit = false; });
        return false;
      },
      child: Scaffold(
        backgroundColor: THEME_COLOR,
        body: IndexedStack(
          index: _isIntroduction ? 0 : 1,
          children: <Widget>[
            // login content 1: intro
            Stack(
              children: [
                _activeIndex == _pages.length ? Container() : GestureDetector(
                  onTap: () {
                    if (_activeIndex < _pages.length - 1) {
                      setState(() {
                        animatedPageDragger = AnimatedPageDragger(
                          slideDirection: SlideDirection.rightToLeft,
                          transitionGoal: TransitionGoal.open,
                          slidePercent: 0.0,
                          slideUpdateStream: slideUpdateStream,
                          vsync: this,
                        );
                        _nextPageIndex = _activeIndex + 1;
                        animatedPageDragger.run();
                      });
                    } else {
                      if (isFirstRun) SharedPreferences.getInstance().then((prefs) {
                        prefs.setBool('isFirstRun', false);
                        isFirstRun = false;
                      });
                      setState(() {
                        print(" -> wakelock: DISABLED");
                        Wakelock.disable();
                        _isIntroduction = false;
                      });
                      _getCurrentUser();
                      // Navigator.of(context).pushNamedAndRemoveUntil(ROUTE_LOGIN, (route) => false);
                    }
                  },
                  child: OnboardingPage(
                    viewModel: _pages[_activeIndex],
                    percentVisible: 1.0,
                  ),
                ),
                PageReveal(
                  revealPercent: _slidePercent,
                  child: OnboardingPage(
                    viewModel: _pages[_nextPageIndex],
                    percentVisible: _slidePercent,
                  ),
                ),
                PagerIndicator(
                  viewModel: PagerIndicatorViewModel(
                    _pages,
                    _activeIndex,
                    _slideDirection,
                    _slidePercent,
                  ),
                ),
                PageDragger(
                  canDragLeftToRight: _activeIndex > 0 && _activeIndex < _pages.length,
                  canDragRightToLeft: _activeIndex < _pages.length - 1,
                  slideUpdateStream: this.slideUpdateStream,
                ),
              ],
            ),
            // login content 2: form
            SafeArea(
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
                        SpinKitChasingDots(color: Colors.white70, size: 50,),
                        LoginForm(
                          key: _loginFormKey,
                          getCurrentUser: _getCurrentUser,
                          setLoading: (val) {
                            Future.microtask(() => FocusScope.of(context).requestFocus(FocusNode()));
                            if (_isLoading != val) setState(() {
                              _isLoading = val;
                            });
                          },
                        ),
                      ],
                    ),
                  ],),
                ),
              ),
            )
          ],
        ),
        // body: _isIntroduction ? Stack(
        //   children: [
        //     _activeIndex == _pages.length ? Container() : GestureDetector(
        //       onTap: () {
        //         if (_activeIndex < _pages.length - 1) {
        //           setState(() {
        //             animatedPageDragger = AnimatedPageDragger(
        //               slideDirection: SlideDirection.rightToLeft,
        //               transitionGoal: TransitionGoal.open,
        //               slidePercent: 0.0,
        //               slideUpdateStream: slideUpdateStream,
        //               vsync: this,
        //             );
        //             _nextPageIndex = _activeIndex + 1;
        //             animatedPageDragger.run();
        //           });
        //         } else {
        //           if (isFirstRun) SharedPreferences.getInstance().then((prefs) {
        //             prefs.setBool('isFirstRun', false);
        //             isFirstRun = false;
        //           });
        //           setState(() {
        //             print(" -> wakelock: DISABLED");
        //             Wakelock.disable();
        //             _isIntroduction = false;
        //           });
        //           _getCurrentUser();
        //           // Navigator.of(context).pushNamedAndRemoveUntil(ROUTE_LOGIN, (route) => false);
        //         }
        //       },
        //       child: OnboardingPage(
        //         viewModel: _pages[_activeIndex],
        //         percentVisible: 1.0,
        //       ),
        //     ),
        //     PageReveal(
        //       revealPercent: _slidePercent,
        //       child: OnboardingPage(
        //         viewModel: _pages[_nextPageIndex],
        //         percentVisible: _slidePercent,
        //       ),
        //     ),
        //     PagerIndicator(
        //       viewModel: PagerIndicatorViewModel(
        //         _pages,
        //         _activeIndex,
        //         _slideDirection,
        //         _slidePercent,
        //       ),
        //     ),
        //     PageDragger(
        //       canDragLeftToRight: _activeIndex > 0 && _activeIndex < _pages.length,
        //       canDragRightToLeft: _activeIndex < _pages.length - 1,
        //       slideUpdateStream: this.slideUpdateStream,
        //     ),
        //   ],
        // ) : SafeArea(
        //   child: Center(
        //     child: SingleChildScrollView(
        //       reverse: true,
        //       padding: EdgeInsets.all(30),
        //       child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[

        //         SizedBox(height: 30,),
        //         Center(child: Hero(
        //           tag: "SplashLogo",
        //           child: Semantics(
        //             label: "Logo $APP_NAME",
        //             image: true,
        //             child: Image.asset('images/logo.png', width: _logoSize, height: _logoSize, fit: BoxFit.contain,),
        //           ),
        //         ),),
        //         SizedBox(height: 30,),

        //         IndexedStack(
        //           index: _isLoading ? 0 : 1,
        //           alignment: Alignment.center,
        //           children: <Widget>[
        //             SpinKitChasingDots(color: Colors.white70, size: 50,),
        //             LoginForm(
        //               key: _loginFormKey,
        //               getCurrentUser: _getCurrentUser,
        //               setLoading: (val) {
        //                 Future.microtask(() => FocusScope.of(context).requestFocus(FocusNode()));
        //                 if (_isLoading != val) setState(() {
        //                   _isLoading = val;
        //                 });
        //               },
        //             ),
        //           ],
        //         ),
        //       ],),
        //     ),
        //   ),
        // ),
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

class _LoginFormState extends State<LoginForm> with TickerProviderStateMixin {
  TextEditingController _nomorPonselController;
  FocusNode _nomorPonselFocusNode;
  var _nomorPonselError = '';
  var _smsVerificationCode = '';
  var _showResend = false;
  var _signedIn = false;
  var _signingIn = false;

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

  @override
  void didUpdateWidget(LoginForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.key != oldWidget.key) {
      // WidgetsBinding.instance.addPostFrameCallback((_) {
      //   _nomorPonselFocusNode.requestFocus();
      // });
    }
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
    if (smsCode.length < SMS_CODE_LENGTH || _signingIn) return;
    _signingIn = true;
    print(" ==> _signInWithCode ...\n$_smsVerificationCode\n$smsCode");
    // Future.delayed(Duration(milliseconds: 500), () => FocusScope.of(context).requestFocus(FocusNode()));
    // FocusScope.of(context).requestFocus(FocusNode());
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
      _signingIn = false;
    }
  }

  _cekUserUID(String uid) async {
    setState(() {
      _signingIn = false;
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
      UiButton("OK", height: style.heightButtonXL, color: Colors.teal[300], textStyle: style.textButtonXL, icon: LineIcons.check_circle, iconSize: 20, iconRight: true, onPressed: () {},),
      SizedBox(height: 12,),
      Center(child: _showResend ? GestureDetector(
        onTap: () {
          setState(() {
            _smsVerificationCode = '';
          });
        },
        child: Padding(
          padding: EdgeInsets.all(4),
          child: Text("Tidak menerima SMS?", style: style.textWhite,),
        ),
      ) : Padding(
        padding: EdgeInsets.all(4),
        child: Detik("Mengirim SMS", duration: RESEND_CODE_TIMEOUT, onFinish: () {
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
      UiInput(
        "Nomor ponsel",
        isRequired: true,
        autoFocus: true,
        icon: LineIcons.mobile_phone,
        labelStyle: style.textLabelWhite,
        textStyle: style.textInputXL,
        type: UiInputType.PHONE,
        controller: _nomorPonselController,
        focusNode: _nomorPonselFocusNode,
        error: _nomorPonselError,
        height: 55.0,
      ),
      SizedBox(height: 12,),
      UiButton("Lanjut", height: style.heightButtonXL, color: Colors.teal[300], textStyle: style.textButtonL, icon: LineIcons.check_circle, iconRight: true, onPressed: () {
        _verifyPhoneNumber(context);
      },),
      SizedBox(height: 42,),
      Copyright()
    ];
    return AnimatedSize(
      vsync: this,
      duration: Duration(milliseconds: 500),
      curve: Curves.easeOut,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _smsVerificationCode.isEmpty ? _formNomorPonsel : _formVerifikasi,
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(widget.label, style: style.textWhite,),
        SizedBox(width: 8,),
        ClipRRect(borderRadius: BorderRadius.circular(5), child: Text("  $_detik  ", style: TextStyle(color: Colors.white, backgroundColor: Colors.white30, fontWeight: FontWeight.bold),),),
      ],
    );
  }
}