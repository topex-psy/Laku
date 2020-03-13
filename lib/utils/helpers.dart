import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_rounded_date_picker/src/material_rounded_date_picker_style.dart';
import 'package:flutter_rounded_date_picker/src/material_rounded_year_picker_style.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/person.dart';
import '../utils/api.dart' as api;
import 'constants.dart';
import 'toast.dart';

final firebaseAuth = FirebaseAuth.instance;
final screenScaffoldKey = GlobalKey<ScaffoldState>();
String currentPersonUid;
bool isTour1Completed = false;
bool isTour2Completed = false;
bool isTour3Completed = false;
bool isDebugMode = false;
bool isFirstRun = true;
Timer timer;

UIHelper h;
UserHelper a;
FormatHelper f;

initializeHelpers(BuildContext context, [String source]) {
  print("INITIALIZE HELPERS ............... $source");
  if (h?.currentContext == context) {
    print("CONTEXT IDENTHICC!!!!!");
    return;
  }
  h = UIHelper(context);
  a = UserHelper(context);
  f = FormatHelper();
}

class FormatHelper {
  int randomNumber(int min, int max) => min + Random().nextInt(max - min);
  String formatNumber(num nominal) => nominal == null ? null : NumberFormat("###,###.###", APP_LOCALE).format(nominal.toDouble());
}

class UserHelper {
  final BuildContext context;
  UserHelper(this.context);

  signOut() async {
    final user = await firebaseAuth.currentUser();
    if (user != null) {
      api.auth('logout', {'uid': user.uid});
      await firebaseAuth.signOut();
    }
    final person = Provider.of<PersonProvider>(context, listen: false);
    person.setPerson(isSignedIn: false);
    Future.delayed(Duration.zero, () {
      Navigator.of(context).popUntil((route) => route.isFirst);
      // Navigator.of(context).pushNamedAndRemoveUntil(ROUTE_LOGIN, (route) => route.isFirst, arguments: {'noSplash': true});
      // Navigator.of(context).popUntil((route) => route.settings.name == ROUTE_LOGIN);
      // Navigator.of(context).popUntil(ModalRoute.withName(ROUTE_LOGIN));
      // Navigator.of(context).pop();
    });
  }
}

class UIHelper {
  final BuildContext context;
  UIHelper(this.context);

  BuildContext get currentContext => context;
  Size get screenSize => MediaQuery.of(context).size;

  /// fungsi untuk menampilkan toast
  showToast(String message, {int duration = Toast.DEFAULT_DURATION}) {
    Toast.show(message, context, duration: duration);
  }

  /// fungsi untuk menampilkan popup dialog berisi pesan atau konten apapun
  Future showAlert({String title, Widget header, Widget dialog, Widget body, Widget listView, EdgeInsetsGeometry contentPadding, bool barrierDismissible = true, bool showButton = true, String buttonText = "OK", Widget customButton, Color warnaAksen}) {
    return showGeneralDialog(
      barrierColor: Colors.black.withOpacity(0.5),
      barrierDismissible: barrierDismissible,
      transitionBuilder: (context, a1, a2, widget) {
        final curvedValue = Curves.easeInOutBack.transform(a1.value) - 1.0;
        return Theme(
          data: Theme.of(context),
          child: Transform(
            transform: Matrix4.identity()..scale(1.0, 1.0 + curvedValue, 1.0),
            child: Opacity(
              opacity: a1.value,
              child: dialog ?? AlertDialog(
                shape: ContinuousRectangleBorder(borderRadius: BorderRadius.circular(30.0)),
                title: header ?? (title != null ? Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.0),) : null),
                titlePadding: header != null ? EdgeInsets.zero : EdgeInsets.only(left: 24.0, right: 24.0, top: 24.0),
                content: listView ?? SingleChildScrollView(child: body,),
                contentPadding: contentPadding ?? EdgeInsets.only(left: 24.0, top: (title ?? header) == null ? 24.0 : 12.0, right: 24.0, bottom: 24.0),
                actions: showButton ? <Widget>[
                  customButton ?? SizedBox(),
                  FlatButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(buttonText, style: TextStyle(fontWeight: FontWeight.bold),),
                  ),
                ] : null,
              ),
            ),
          ),
        );
      },
      transitionDuration: Duration(milliseconds: 500),
      barrierLabel: '',
      context: context,
      pageBuilder: (context, animation1, animation2) => Container()
    );
  }

  /// fungsi untuk menampilkan popup dialog konfirmasi
  Future<bool> showConfirm(String judul, String pesan) async {
    return await showGeneralDialog(
      barrierColor: Colors.black.withOpacity(0.5),
      transitionBuilder: (context, a1, a2, widget) {
        final curvedValue = Curves.easeInOutBack.transform(a1.value) - 1.0;
        return Theme(
          data: Theme.of(context),
          child: Transform(
            transform: Matrix4.identity()..scale(1.0, 1.0 + curvedValue, 1.0),
            child: Opacity(
              opacity: a1.value,
              child: AlertDialog(
                shape: ContinuousRectangleBorder(borderRadius: BorderRadius.circular(30.0)),
                title: judul != null ? Text(judul, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.0),) : null,
                content: SingleChildScrollView(child: html(pesan, textStyle: TextStyle(fontSize: 16.0, height: 1.4),),),
                contentPadding: EdgeInsets.only(left: 24.0, top: judul != null ? 12.0 : 24.0, right: 24.0, bottom: 12.0),
                actions: <Widget>[
                  Padding(
                    padding: EdgeInsets.only(bottom: 8.0),
                    child: FlatButton(child: Text("Tidak", style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),), onPressed: () {
                      Navigator.of(context).pop(false);
                    },),
                  ),
                  Padding(
                    padding: EdgeInsets.only(bottom: 8.0),
                    child: FlatButton(child: Text("Ya", style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),), onPressed: () {
                      Navigator.of(context).pop(true);
                    },),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      transitionDuration: Duration(milliseconds: 500),
      barrierDismissible: true,
      barrierLabel: '',
      context: context,
      pageBuilder: (context, animation1, animation2) => Container()
    );
  }

  /// fungsi untuk menutup popup dialog
  // TODO FIXME seharusnya kalo nggak ada dialog lagi nggak perlu melakukan apa-apa
  closeDialog() => Navigator.of(context, rootNavigator: true).pop('dialog');

  /// fungsi untuk menampilkan popup dialog custom
  Future<dynamic> customAlert(String title, String message, {Widget icon, Axis direction = Axis.horizontal, void Function() onAction, void Function() onDismiss, actionLabel}) => showAlert(
    title: title,
    body: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
      direction == Axis.horizontal ? Row(children: <Widget>[
        icon ?? SizedBox(),
        icon == null ? SizedBox() : SizedBox(width: 12,),
        Expanded(child: html(message, textStyle: TextStyle(height: 1.4),)),
      ],) : Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
        icon ?? SizedBox(),
        icon == null ? SizedBox() : SizedBox(height: 12,),
        html(message, textStyle: TextStyle(height: 1.4),),
      ],),
      SizedBox(height: 12.0,),
      Row(mainAxisSize: MainAxisSize.max, mainAxisAlignment: onAction == null ? MainAxisAlignment.center : MainAxisAlignment.spaceAround, children: <Widget>[
        onAction == null || actionLabel == null ? SizedBox() : FlatButton(
          child: Text(actionLabel, style: TextStyle(color: Theme.of(context).accentColor, fontWeight: FontWeight.bold),),
          onPressed: onAction,
        ),
        FlatButton(
          child: Text("OK", style: TextStyle(color: Theme.of(context).accentColor, fontWeight: FontWeight.bold),),
          onPressed: Navigator.of(context).pop,
        ),
      ],),
    ],),
    showButton: false,
  ).then((res) {
    if (onDismiss != null) onDismiss();
  });

  /// fungsi untuk menampilkan popup pesan gagal
  Future<dynamic> failAlert(String title, String message, {Widget icon, Axis direction = Axis.horizontal, void Function() onRetry, void Function() onDismiss}) => customAlert(
    title,
    message,
    icon: icon,
    direction: direction,
    onAction: onRetry,
    onDismiss: onDismiss,
    actionLabel: 'Coba Lagi',
  );

  /// fungsi untuk menampilkan popup memuat data
  loadAlert([String teks]) => showAlert(body: Row(children: <Widget>[
    SizedBox(width: 30, height: 30, child: CircularProgressIndicator(strokeWidth: 3.0,)),
    SizedBox(width: 5,),
    Text("Tunggu sebentar ...")
  ],), showButton: false, barrierDismissible: false);

  /// fungsi yang mengembalikan teks versi html
  Html html(String htmlString, {TextStyle textStyle}) => Html(
    data: htmlString,
    defaultTextStyle: textStyle,
    onLinkTap: (url) async {
      print("OPENING URL: $url");
      print("OPENING PAGE: ${url.replaceAll(APP_HOST, '')}");
      // loadAlert();
      // var responseJson = await getPage(url.replaceAll(APP_HOST, ''));
      // var page = PageApi.fromJson(responseJson["result"]);
      // closeDialog();
      // showAlert(title: page.judul, body: html(page.isi, textStyle: TextStyle(fontSize: 14)));
    },
  );

  MaterialRoundedDatePickerStyle get datePickerStyle {
    return MaterialRoundedDatePickerStyle(
      textStyleDayButton: TextStyle(fontSize: 18), //Rab, 19 Feb
      textStyleYearButton: TextStyle(fontSize: 45, color: Colors.white), //2020
      textStyleDayHeader: TextStyle(fontSize: 11), // M S S R K J S
      textStyleCurrentDayOnCalendar: TextStyle(fontSize: 16, color: THEME_COLOR),
      textStyleDayOnCalendar: TextStyle(fontSize: 16),
      textStyleDayOnCalendarSelected: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
      // textStyleDayOnCalendarDisabled: TextStyle(fontSize: 28, color: Colors.white.withOpacity(0.1)),
      textStyleMonthYearHeader: TextStyle(fontSize: 15, color: Colors.white, fontWeight: FontWeight.bold), // Februari 2020
      paddingDatePicker: EdgeInsets.all(0),
      paddingMonthHeader: EdgeInsets.all(14),
      paddingActionBar: EdgeInsets.zero,
      // paddingDateYearHeader: EdgeInsets.all(32),
      // sizeArrow: 50,
      colorArrowNext: Colors.white,
      colorArrowPrevious: Colors.white,
      // marginLeftArrowPrevious: 16,
      // marginTopArrowPrevious: 16,
      // marginTopArrowNext: 16,
      // marginRightArrowNext: 32,
      textStyleButtonAction: TextStyle(fontSize: 14, color: Colors.white),
      textStyleButtonPositive: TextStyle(fontSize: 14, color: Colors.white),
      textStyleButtonNegative: TextStyle(fontSize: 14, color: Colors.white),
      // decorationDateSelected: BoxDecoration(color: Colors.orange[600], shape: BoxShape.circle),
      // backgroundPicker: Colors.pink[400],
      backgroundActionBar: THEME_COLOR, // batal ok
      backgroundHeaderMonth: THEME_COLOR,
    );
  }

  MaterialRoundedYearPickerStyle get yearPickerStyle {
    return MaterialRoundedYearPickerStyle(
      // textStyleYear: TextStyle(fontSize: 40, color: Colors.white),
      // textStyleYearSelected: TextStyle(fontSize: 56, color: Colors.white, fontWeight: FontWeight.bold),
      // heightYearRow: 100,
      // backgroundPicker: Colors.deepPurple[400],
    );
  }
}