import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:code_input/code_input.dart';
import 'package:line_icons/line_icons.dart';
import 'utils/constants.dart';
import 'utils/helpers.dart';
import 'utils/styles.dart' as style;
import 'utils/widgets.dart';

const AUTO_VERIFY_TIMEOUT = 60;
const RESEND_CODE_TIMEOUT = 10;
const SMS_CODE_LENGTH = 6;

class Verifikasi extends StatefulWidget {
  Verifikasi(this.args, {Key key}) : super(key: key);
  final Map args;

  @override
  _VerifikasiState createState() => _VerifikasiState();
}

class _VerifikasiState extends State<Verifikasi> {
  String _verificationId;
  var _showResend = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _verifyPhone();
    });
  }

  _submit(String smsCode) {
    final cred = PhoneAuthProvider.getCredential(verificationId: _verificationId, smsCode: smsCode);
    Navigator.of(context).pop(cred);
  }

  _verifyPhone() async {
    setState(() {
      _verificationId = null;
      _showResend = false;
    });
    final phone = widget.args['phone'];
    await firebaseAuth.verifyPhoneNumber(
      phoneNumber: "$APP_COUNTRY_CODE$phone",
      timeout: Duration(seconds: 60),
      verificationCompleted: Navigator.of(context).pop,
      verificationFailed: null,
      codeSent: (verificationId, [forceResendingToken]) {
        setState(() {
          _verificationId = verificationId;
        });
      },
      codeAutoRetrievalTimeout: null
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: THEME_COLOR,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
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
                child: IgnorePointer(
                  ignoring: _verificationId == null,
                  child: Opacity(
                    opacity: _verificationId == null ? .5 : 1,
                    child: CodeInput(
                      length: SMS_CODE_LENGTH,
                      keyboardType: TextInputType.number,
                      builder: CodeInputBuilders.lightCircle(),
                      onFilled: _submit,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 12,),
              UiButton("OK", height: style.heightButtonXL, color: Colors.teal[300], textStyle: style.textButtonXL, icon: LineIcons.check_circle, iconSize: 20, iconRight: true, onPressed: () {},),
              SizedBox(height: 12,),
              Center(child: _showResend ? GestureDetector(
                onTap: _verifyPhone,
                child: Padding(
                  padding: EdgeInsets.all(4),
                  child: Text("Tidak menerima SMS?", style: style.textWhite,),
                ),
              ) : Padding(
                padding: EdgeInsets.all(4),
                child: UiCountdown("Mengirim SMS", duration: RESEND_CODE_TIMEOUT, onFinish: () {
                  setState(() {
                    _showResend = true;
                  });
                }),
              ),),
            ],
          ),
        ),
      ),
    );
  }
}