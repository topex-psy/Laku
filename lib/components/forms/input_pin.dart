import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/user.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../../utils/widgets.dart';

const INPUT_PIN_MAXLENGTH = 6;
const PROFILE_PICTURE_SIZE = 80.0;

class InputPIN extends StatefulWidget {
  InputPIN(this.person, {this.pinOnly = false});
  final UserModel person;
  final bool pinOnly;

  Future<dynamic> show() => h.showAlert(
    barrierDismissible: false,
    header: Container(
      width: double.maxFinite, // penting agar gak error di emulator
      height: 120,
      padding: EdgeInsets.all(20.0),
      color: THEME_COLOR.withOpacity(0.2),
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: <Widget>[
        SizedBox(
          width: PROFILE_PICTURE_SIZE,
          height: PROFILE_PICTURE_SIZE,
          child: ClipOval(
            child: person.foto == null
              ? Image.asset(SETUP_USER_IMAGE, width: PROFILE_PICTURE_SIZE, height: PROFILE_PICTURE_SIZE, fit: BoxFit.cover,)
              : Image.network(person.foto, width: PROFILE_PICTURE_SIZE, height: PROFILE_PICTURE_SIZE, fit: BoxFit.cover,),
          ),
        ),
        SizedBox(width: 15.0,),
        Expanded(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
          Text("Melanjutkan sebagai ...", style: TextStyle(fontSize: 12.0, color: Colors.black54),),
          SizedBox(height: 5.0,),
          AutoSizeText(person.namaLengkap, maxLines: 1, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0),),
          SizedBox(height: 3.0,),
          AutoSizeText(person.email, maxLines: 1, style: TextStyle(fontSize: 14.0, color: Colors.blue),),
        ],)),
        SizedBox(width: 10.0,),
      ],),
    ),
    showButton: false,
    body: this,
  );

  @override
  _InputPINState createState() => _InputPINState();
}

class _InputPINState extends State<InputPIN> {
  var _isInvalid = false;
  var _isLoading = false;

  _login(String sandi) async {
    if (widget.pinOnly) {
      Navigator.of(context).pop(sandi);
      return;
    }
    setState(() {
      _isInvalid = false;
      _isLoading = true;
    });

    final FirebaseUser user = await a.firebaseLoginEmailPassword(widget.person.email, sandi);
    if (user == null) {
      setState(() {
        _isInvalid = true;
        _isLoading = false;
      });
    } else {

      if (isDebugMode) print(
        "\n email            = ${user.email}"
        "\n displayName      = ${user.displayName}"
        "\n photoUrl         = ${user.photoUrl}"
        "\n uid              = ${user.uid}"
        "\n isAnonymous      = ${user.isAnonymous}"
        "\n isEmailVerified  = ${user.isEmailVerified}"
        "\n providerId       = ${user.providerId}"
        "\n providerData     = ${user.providerData}"
      );

      Navigator.of(context).pop(user);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
      ? Center(child: UiLoader())
      : Column(
        children: <Widget>[
          _isInvalid ? Card(
            color: Colors.red,
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(THEME_CARD_RADIUS)),
            child: Text("Nomor PIN salah!"),
          ) : SizedBox(),
          TombolPIN(person: widget.person, onComplete: _login),
        ],
      );
  }
}

class TombolPIN extends StatefulWidget {
  TombolPIN({Key key, @required this.person, @required this.onComplete}) : super(key: key);
  final void Function(String) onComplete;
  final UserModel person;

  @override
  _TombolPINState createState() => _TombolPINState();
}

class _TombolPINState extends State<TombolPIN> {
  var _pakaiPassword = false;
  var _isSendingRecoveryEmail = false;
  var _pencetTombol = 0;

  TextEditingController textController;
  FocusNode textFocus;

  @override
  void initState() {
    textController = TextEditingController();
    textFocus = FocusNode();
    super.initState();
  }

  @override
  void dispose() {
    textController.dispose();
    textFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget tombol(int angka) {
      bool isPencetTombol = _pencetTombol == angka;
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 4),
        child: AnimatedOpacity(
          duration: Duration(milliseconds: 1000),
          opacity: isPencetTombol ? 0.5 : 1,
          child: Container(width: 60, height: 60, child: Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              side: BorderSide(color: THEME_COLOR.withOpacity(0.5), width: isPencetTombol ? 4.0 : 1.0,),
              borderRadius: BorderRadius.circular(50.0),
            ),
            clipBehavior: Clip.antiAlias,
            child: Material(
              color: isPencetTombol ? Colors.pink : Colors.transparent,
              child: InkWell(
                highlightColor: Colors.transparent,
                splashColor: Colors.transparent,
                onHighlightChanged: (val) => setState(() { _pencetTombol = val ? angka : 0; }),
                onTap: () {
                  if (textController.text.length < INPUT_PIN_MAXLENGTH) {
                    textController.text = "${textController.text}$angka";
                    if (textController.text.length == INPUT_PIN_MAXLENGTH) widget.onComplete(textController.text);
                  }
                },
                child: Center(child: Text("$angka", style: TextStyle(fontSize: 20),),),
              ),
            ),
          ),),
        ),
      );
    }
    return Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
      SizedBox(height: 10,),
      Row(crossAxisAlignment: CrossAxisAlignment.center, children: <Widget>[
        Expanded(child: Text("Masukkan ${_pakaiPassword?'Sandi':'PIN'}:"),),
        SizedBox(width: 4,),
        _isSendingRecoveryEmail ? UiLoader() : GestureDetector(onTap: () async {
          setState(() { _isSendingRecoveryEmail = true; });
          await a.forgotPIN(widget.person.email);
          setState(() { _isSendingRecoveryEmail = false; });
        }, child: Chip(label: Text("Lupa?", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),),))
      ],),
      Column(mainAxisSize: MainAxisSize.min, children: _pakaiPassword ? <Widget>[
        UiInput("Masukkan sandi", icon: Icons.lock, showLabel: false, type: UiInputType.PASSWORD, controller: textController, focusNode: textFocus, onSubmit: (String val) => widget.onComplete(val)),
        SizedBox(height: 12.0,),
        UiButton("Masuk", height: 40, onPressed: () => widget.onComplete(textController.text),),
        SizedBox(height: 20,),
        GestureDetector(onTap: () {
          setState(() { _pakaiPassword = false; });
          textController.text = '';
        }, child: Text("Gunakan nomor PIN", style: TextStyle(color: Colors.blue, fontSize: 13, fontWeight: FontWeight.normal),))
      ] : <Widget>[
        Stack(
          alignment: Alignment.centerRight,
          children: <Widget>[
            IgnorePointer(
              child: TextFormField(
                obscureText: true,
                readOnly: true,
                inputFormatters: <TextInputFormatter>[
                  WhitelistingTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                maxLines: 1,
                decoration: InputDecoration(border: InputBorder.none),
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: THEME_FONT_SECONDARY, fontSize: 30, letterSpacing: 5, color: THEME_COLOR),
                controller: textController,
                focusNode: textFocus,
              ),
            ),
            IconButton(
              onPressed: () {
                if (textController.text.isNotEmpty) textController.text = textController.text.substring(0, textController.text.length - 1);
              },
              icon: Icon(Icons.backspace, color: Colors.grey, size: 18,),
            )
          ],
        ),
        Row(mainAxisSize: MainAxisSize.max, mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: <Widget>[
          tombol(1),
          tombol(2),
          tombol(3),
        ],),
        Row(mainAxisSize: MainAxisSize.max, mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: <Widget>[
          tombol(4),
          tombol(5),
          tombol(6),
        ],),
        Row(mainAxisSize: MainAxisSize.max, mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: <Widget>[
          tombol(7),
          tombol(8),
          tombol(9),
        ],),
        SizedBox(height: 20,),
        GestureDetector(onTap: () {
          setState(() { _pakaiPassword = true; });
          textController.text = '';
        }, child: Text("Gunakan kata sandi", style: TextStyle(color: Colors.blue, fontSize: 13, fontWeight: FontWeight.normal),))
      ],),
    ],);
  }
}