import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/api.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../utils/models.dart' show UserModel;
import '../utils/variables.dart';
import '../utils/widgets.dart';

class LoginPage extends StatefulWidget {
  const LoginPage(this.args, {Key? key}) : super(key: key);
  final Map<String, dynamic> args;

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {

  final TextEditingController _emailController = TextEditingController();
  final _errorText = <String, String>{};
  var _isLoading = true;

  _dismissError(String tag) {
    if (_errorText.containsKey(tag)) {
      setState(() {
        _errorText.remove(tag);
      });
    }
  }

  _login() {
    // form validation
    setState(() {
      if (_emailController.text.isEmpty) {
        _errorText["email"] = "Harap masukkan email Anda!";
      } else if (!f.isValidEmail(_emailController.text)) {
        _errorText["email"] = "Alamat email tidak valid!";
      }
    });
    if (_errorText.isNotEmpty) {
      print("LOGIN ERRORS: $_errorText");
      return;
    }

    // check user email in database
    FocusScope.of(context).unfocus();
    _checkUserEmail();
  }

  _checkUserEmail() async {
    setState(() {
      _isLoading = true;
    });
    final userData = {"email": _emailController.text};
    final userResult = await ApiProvider().api('user/check', method: "post", data: userData, withLog: true);
    print("userResult: $userResult");
    if (!userResult.isSuccess) {
      if (userResult.message == "user-not-found") {
        await Navigator.pushNamed(context, ROUTE_REGISTER, arguments: userData);
        reInitContext(context);
      } else {
        h.showCallbackDialog(
          "Terjadi kendala saat memuat data. Periksa koneksi internetmu atau coba lagi nanti!",
          title: "Gagal Memproses",
          type: MyCallbackType.error
        );
      }
      setState(() {
        _isLoading = false;
      });
    } else {
      print("user result: ${userResult.data.first}");
      profile = UserModel.fromJson(userResult.data.first);
      print("user data: $profile");
      if (FirebaseAuth.instance.currentUser == null) {
        // firebase login with email & password
        final pin = await u.promptPIN();
        if (pin == null) {
          setState(() {
            _isLoading = false;
          });
        } else {
          User? firebaseUser;
          try {
            final firebaseAuth = await FirebaseAuth.instance.signInWithEmailAndPassword(email: _emailController.text, password: pin);
            firebaseUser = firebaseAuth.user;
          } on FirebaseAuthException catch(e) {
            // Unhandled Exception: [firebase_auth/wrong-password] The password is invalid or the user does not have a password.
            print("firebase error: $e");
          } catch(e) {
            print("other error: $e");
          }
          if (firebaseUser == null) {
            h.showCallbackDialog("PIN yang kamu masukkan salah!", title: "Login Gagal", type: MyCallbackType.error);
            setState(() {
              _isLoading = false;
            });
          } else {
            _loginSuccess();
          }
        }
      } else {
        // user logged in
        _loginSuccess();
      }
    }
  }

  /// store user data from profile & redirect to dashboard
  _loginSuccess() async {
    setState(() {
      _isLoading = true;
    });

    // store user data
    // await widget.analytics.setUserId(profile!.id.toString());
    // await widget.analytics.setUserProperty(name: 'email', value: profile!.email);
    await u.login();

    // redirect
    // await Navigator.push(context, PageRouteBuilder(pageBuilder: (_, __, ___) => const DashboardPage({ "justLogin": true })));
    await Navigator.pushNamed(context, ROUTE_DASHBOARD, arguments: { "transition": "none", "justLogin": true });
    reInitContext(context);
    setState(() {
      _isLoading = false;
    });
  }

  _loginFail([String? devNote]) {
    if (_isLoading) {
      setState(() {
        _isLoading = false;
      });
    }
    h.showCallbackDialog("Terjadi masalah saat login. Silakan coba lagi.", title: "Gagal Login", type: MyCallbackType.error, devNote: devNote);
    if (devNote != null) print(devNote);
  }

  _loginFacebook() async {
    // docs:  https://facebook.meedu.app/#/login
    final LoginResult result = await FacebookAuth.instance.login();
    print("facebook login status: ${result.status}");
    print("facebook login message: ${result.message}");
    if (result.status == LoginStatus.success) {
      setState(() {
        _isLoading = true;
      });
      final fbAccessToken = result.accessToken!;
      final fbUserData = await FacebookAuth.instance.getUserData();
      // log("fbUserData: ${f!.formatJson(fbUserData)}");

      // firebase login
      final facebookAuthCred = FacebookAuthProvider.credential(fbAccessToken.token);
      try {
        final firebaseAuth = await FirebaseAuth.instance.signInWithCredential(facebookAuthCred);
        final firebaseUser = firebaseAuth.user;
        if (firebaseUser == null) {
          await Navigator.pushNamed(context, ROUTE_REGISTER, arguments: {
            "name": fbUserData["name"],
            "email": fbUserData["email"],
            "picture": fbUserData["picture"]["data"]["url"],
            "method": "facebook",
          });
          reInitContext(context);
        } else {
          log(
            "firebaseUser:"
            "\n email            = ${firebaseUser.email}"
            "\n displayName      = ${firebaseUser.displayName}"
            "\n photoUrl         = ${firebaseUser.photoURL}"
            "\n uid              = ${firebaseUser.uid}"
            "\n isAnonymous      = ${firebaseUser.isAnonymous}"
            "\n isEmailVerified  = ${firebaseUser.emailVerified}"
            "\n providerData     = ${firebaseUser.providerData}"
          );
          _emailController.text = firebaseUser.email!;
          _login();
        }
      } on FirebaseAuthException catch(e) {
        if (e.code == "account-exists-with-different-credential") {
          // final methods = await FirebaseAuth.instance.fetchSignInMethodsForEmail(fbUserData["email"]);
          _emailController.text = fbUserData["email"];
          h.showCallbackDialog(
            "Alamat email kamu sudah terdaftar di aplikasi $APP_NAME.",
            title: "Email Sudah Terdaftar",
            type: MyCallbackType.info
          ).then((_) {
            _login();
          });
        } else {
          _loginFail("FirebaseAuthException error: $e");
        }
      } on PlatformException catch(e) {
        _loginFail("PlatformException error: $e");
      } catch(e) {
        _loginFail("other error: $e");
      }
    } else if (result.status == LoginStatus.failed) {
      h.showCallbackDialog(
        "Terjadi masalah saat login dengan Facebook. Silakan coba lagi.",
        title: "Login Facebook Gagal",
        type: MyCallbackType.error
      );
    }
  }

  @override
  void initState() {
    _emailController.addListener(() { if (_emailController.text.isNotEmpty) _dismissError("email"); });
    super.initState();
    WidgetsBinding.instance?.addPostFrameCallback((_) async {
      languageCode = context.locale.languageCode;

      SharedPreferences prefs = await SharedPreferences.getInstance();
      isTour1Completed = isDebugMode && DEBUG_TOUR ? false : (prefs.getBool('isTour1Completed') ?? false);
      isTour2Completed = isDebugMode && DEBUG_TOUR ? false : (prefs.getBool('isTour2Completed') ?? false);
      isTour3Completed = isDebugMode && DEBUG_TOUR ? false : (prefs.getBool('isTour3Completed') ?? false);

      // check current user
      User? firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser?.email != null) {
        _emailController.text = firebaseUser!.email!;
        _checkUserEmail();
        return;
      }

      isFirstRun = (isDebugMode && DEBUG_ONBOARDING) || (prefs.getBool('isFirstRun') ?? true);
      String email = prefs.getString('login_email') ?? (isDebugMode ? DEBUG_USER : '');
      int? savedID = prefs.getInt('login_id');
      _emailController.text = email;

      if (savedID == null) {
        if (isFirstRun) {
          await Navigator.pushNamed(context, ROUTE_INTRO);
        }
        setState(() {
          _isLoading = false;
        });
      } else {
        _login();
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: APP_UI_COLOR[100]!,
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
          child: Stack(
            alignment: Alignment.center,
            children: [
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(30),
                  child: Column(children: [
                    const MyAppLogo(type: MyLogoType.inverted, size: 180.0),
                    const Text(APP_TAGLINE, textAlign: TextAlign.center, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 40,),
                    const Text("Yuk, langsung aja!", textAlign: TextAlign.center, style: TextStyle(fontSize: 16)),
                    const SizedBox(height: 40,),
                    MyInputField(label: 'Email', type: MyInputType.EMAIL, size: MyButtonSize.LARGE, action: TextInputAction.go, onSubmitted: (email) => _login(), controller: _emailController, error: _errorText["email"],),
                    const SizedBox(height: 24,),
                    MyButton('action_continue'.tr(), fullWidth: true, onPressed: _login),
                    const SizedBox(height: 10,),
                    const Text("atau", style: TextStyle(fontSize: 14, color: Colors.blueGrey)),
                    const SizedBox(height: 10,),
                    MyButton('action_login_facebook'.tr(), color: Colors.blue[900], icon: Icons.facebook, size: MyButtonSize.SMALL, fullWidth: true, onPressed: _loginFacebook),
                    const SizedBox(height: 42,),
                    const MyFooter(showCopyright: true),
                  ],),
                ),
              ),
              MyLoader(isLoading: _isLoading,),
            ],
          ),
        ),
      ),
    );
  }
}