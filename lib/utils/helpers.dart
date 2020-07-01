import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_html/style.dart';
import 'package:flutter_rounded_date_picker/src/material_rounded_date_picker_style.dart';
import 'package:flutter_rounded_date_picker/src/material_rounded_year_picker_style.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flash/flash.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:laku/models/iklan.dart';
import 'package:line_icons/line_icons.dart';
import 'package:preload_page_view/preload_page_view.dart';
import 'package:provider/provider.dart';
import '../components/forms/input_pin.dart';
import '../extensions/string.dart';
import '../models/user.dart';
import '../plugins/toast.dart';
import '../providers/person.dart';
import '../providers/settings.dart';
import '../utils/api.dart';
import 'constants.dart';

final firebaseAuth = FirebaseAuth.instance;
final screenScaffoldKey = GlobalKey<ScaffoldState>();
final screenPageController = PreloadPageController();
// PreloadPageController screenPageController;
UserSessionModel userSession = UserSessionModel();
bool isTour1Completed = false;
bool isTour2Completed = false;
bool isTour3Completed = false;
bool isDebugMode = false;
bool isFirstRun = true;

UIHelper h;
UserHelper a;
FormatHelper f;

class FormatHelper {
  FormatHelper() : this.initialize();

  // inisiasi intl date format untuk locale indonesia
  FormatHelper.initialize() {
    var format = initializeDateFormatting(APP_LOCALE);
    Future.wait([format]);
  }

  int randomNumber(int min, int max) => min + Random().nextInt(max - min);
  String formatNumber(num nominal) => nominal == null ? null : NumberFormat("###,###.###", APP_LOCALE).format(nominal.toDouble());
  String formatDate(DateTime date, {String format = 'dd/MM/yyyy'}) => date == null ? null : DateFormat(format).format(date);
  String formatPrice(dynamic nominal, {String symbol = 'Rp '}) => nominal == null ? null : NumberFormat.currency(locale: APP_LOCALE, symbol: symbol).format(nominal);
  bool isValidURL(String url) => Uri.parse(url).isAbsolute;
  bool isValidEmail(String email) => !email.isEmptyOrNull && RegExp(r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?)*$").hasMatch(email);
  num roundNumber(num nominal, {int maxDecimal = 1}) => num.parse((nominal / 1000).toStringAsFixed(maxDecimal));
  String distanceLabel(double meter) {
    if (meter > 999) return "${roundNumber(meter / 1000)} km";
    return "${roundNumber(meter)} m";
  }
}

class UserHelper {
  final BuildContext context;
  UserHelper(this.context);

  Future<bool> loadNotif() async {
    var notifApi = await api('user_notif', data: {'uid': userSession.uid});
    if (notifApi.isSuccess) {
      final settings = Provider.of<SettingsProvider>(context, listen: false);
      settings.setSettings(notif: UserNotifModel.fromJson(notifApi.result.first));
    }
    return notifApi.isSuccess;
  }

  Future<dynamic> openProfile() async {
    final results = await Navigator.of(context).pushNamed(ROUTE_PROFIL) as Map;
    print(" ... ROUTE PROFIL result: $results");
    if (screenScaffoldKey.currentState.isEndDrawerOpen) Navigator.of(context).pop();
    return results;
  }

  Future<dynamic> openMyShop() async {
    final results = await Navigator.of(context).pushNamed(ROUTE_DATA, arguments: {'tipe': 'shop', 'mode': 'mine'});
    print(" ... ROUTE MY SHOP result: $results");
    if (screenScaffoldKey.currentState.isEndDrawerOpen) Navigator.of(context).pop();
    return results;
  }

  Future<dynamic> openListing(IklanModel item) async {
    final results = await Navigator.of(context).pushNamed(ROUTE_LISTING, arguments: {'item': item});
    print(" ... ROUTE LISTING result: $results");
    return results;
  }

  Future<FirebaseUser> firebaseLoginEmailPassword(String email, String password) async {
    if (email.isEmptyOrNull || password.isEmptyOrNull) return null;
    FirebaseUser user;
    try {
      AuthResult result = await firebaseAuth.signInWithEmailAndPassword(email: email, password: password);
      user = result.user;
    } catch (error) {
      print(error.toString());
      switch (error.code) {
        case "ERROR_INVALID_EMAIL":
          h.failAlertLogin("Alamat email yang Anda masukkan salah!");
          break;
        case "ERROR_WRONG_PASSWORD":
          h.failAlertLogin("Nomor PIN yang Anda masukkan salah!");
          break;
        case "ERROR_USER_NOT_FOUND":
          h.failAlertLogin("Pengguna belum terdaftar!");
          break;
        case "ERROR_USER_DISABLED":
          h.failAlertLogin("Status akun Anda sedang diblokir!");
          break;
        case "ERROR_TOO_MANY_REQUESTS":
          h.failAlertLogin("Anda tidak dapat login untuk sementara waktu karena terlalu banyak salah memasukkan nomor PIN/kata sandi.");
          break;
        case "ERROR_OPERATION_NOT_ALLOWED":
        default:
          h.failAlertLogin();
      }
    }
    return user;
  }

  Future<bool> firebaseLinkWithCredential(AuthCredential credential) async {
    final user = await firebaseAuth.currentUser();
    try {
      await user.linkWithCredential(credential);
      print("LINK ACCOUNT SUCCEEEEEEEEEEEEEESS!");
      return true;
    } catch(e) {
      print("LINK ACCOUNT ERROOOOOOOOOOOOOOOOR: $e");
      return false;
    }
  }

  Future<bool> firebaseLinkWithEmail(String email, String password) async {
    final credential = EmailAuthProvider.getCredential(email: email, password: password);
    return await firebaseLinkWithCredential(credential);
  }

  Future<void> firebaseUpdateProfile({String namaLengkap, String foto}) async {
    final user = await firebaseAuth.currentUser();
    final info = UserUpdateInfo();
    if (namaLengkap != null) info.displayName = namaLengkap;
    if (foto != null) info.photoUrl = foto;
    return user.updateProfile(info);
  }

  Future<void> firebaseUpdatePhoneNumber(AuthCredential credential) async {
    final user = await firebaseAuth.currentUser();
    return user.updatePhoneNumberCredential(credential);
  }

  Future<void> firebaseUpdateEmail(String email) async {
    final user = await firebaseAuth.currentUser();
    return user.updateEmail(email);
  }

  Future<dynamic> forgotPIN(email) async {
    await firebaseAuth.sendPasswordResetEmail(email: email);
    return h.successAlert("Tautan Pemulihan Terkirim!", "Silakan periksa kotak masuk email Anda untuk membuat nomor PIN baru!");
  }

  Future<dynamic> inputPIN(UserModel me, {bool pinOnly = false, String title}) {
    return InputPIN(me, pinOnly: pinOnly, title: title).show();
  }

  Future<AuthCredential> inputOTP(String phone) async {
    AuthCredential credential = await Navigator.of(context).pushNamed(ROUTE_OTP, arguments: {'phone': phone});
    return credential;
  }

  logout() async {
    bool confirm = await h.showConfirm("Akhiri Sesi?", "Apakah kamu yakin ingin mengakhiri sesi?") ?? false;
    if (confirm) signOut();
  }

  signOut() async {
    final user = await firebaseAuth.currentUser();
    if (user != null) {
      auth('logout', {'uid': user.uid});
      await firebaseAuth.signOut();
    }
    final person = Provider.of<PersonProvider>(context, listen: false);
    person.clearPreferences();
    userSession.clear();
    Future.delayed(Duration.zero, () {
      // Navigator.of(context).popUntil((route) => route.settings.name == ROUTE_LOGIN);
      // Navigator.of(context).popUntil(ModalRoute.withName(ROUTE_LOGIN));
      Navigator.of(context).popUntil((route) => route.isFirst);
    });
  }
}

class UIHelper {
  final BuildContext context;
  UIHelper(this.context);

  BuildContext get currentContext => context;
  // Size get screenSize => MediaQuery.of(context).size;

  /// fungsi untuk menampilkan toast
  showToast(String message, {int duration = Toast.DEFAULT_DURATION}) {
    Toast.show(message, context, duration: duration);
  }

  /// fungsi untuk menampilkan popup dialog berisi pesan atau konten apapun
  Future showAlert({String title, Widget header, Widget dialog, Widget body, Widget listView, Color backgroundColor, EdgeInsetsGeometry contentPadding, bool barrierDismissible = true, bool showButton = true, String buttonText = "OK", Widget customButton, Color warnaAksen}) {
    return showGeneralDialog(
      barrierColor: Colors.black.withOpacity(0.5),
      barrierDismissible: barrierDismissible,
      transitionBuilder: (context, a1, a2, widget) {
        final _curvedValue = Curves.easeInOutBack.transform(a1.value) - 1.0;
        final _contentPadding = contentPadding ?? EdgeInsets.only(left: 24.0, top: (title ?? header) == null ? 24.0 : 16.0, right: 24.0, bottom: 24.0);
        return Theme(
          data: Theme.of(context),
          child: Transform(
            transform: Matrix4.identity()..scale(1.0, 1.0 + _curvedValue, 1.0),
            child: Opacity(
              opacity: a1.value,
              child: dialog ?? AlertDialog(
                backgroundColor: backgroundColor,
                shape: ContinuousRectangleBorder(borderRadius: BorderRadius.circular(30.0)),
                title: header ?? (title != null ? Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.0),) : null),
                titlePadding: header != null ? EdgeInsets.zero : EdgeInsets.only(left: 24.0, right: 24.0, top: 24.0),
                content: listView ?? SingleChildScrollView(padding: _contentPadding, child: body,),
                // contentPadding: _contentPadding,
                contentPadding: EdgeInsets.zero,
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
        final _curvedValue = Curves.easeInOutBack.transform(a1.value) - 1.0;
        return Theme(
          data: Theme.of(context),
          child: Transform(
            transform: Matrix4.identity()..scale(1.0, 1.0 + _curvedValue, 1.0),
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
    ) ?? false;
  }

  /// fungsi untuk menutup popup dialog
  // TODO FIXME seharusnya kalo nggak ada dialog lagi nggak perlu melakukan apa-apa
  closeDialog() => Navigator.of(context, rootNavigator: true).pop('dialog');

  /// fungsi untuk menampilkan popup dialog custom
  Future<dynamic> customAlert(String title, String message, {Widget icon, Axis direction = Axis.horizontal, void Function() onAction, actionLabel}) => showAlert(
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
  );

  /// fungsi untuk menampilkan popup pesan sukses
  Future<dynamic> successAlert(String title, String message, {void Function() onUndo, undoLabel}) => customAlert(
    title,
    message,
    icon: Icon(LineIcons.check_circle, color: Colors.green, size: 40,),
    onAction: onUndo,
    actionLabel: undoLabel ?? 'Batalkan',
  );

  /// fungsi untuk menampilkan popup pesan gagal
  Future<dynamic> failAlert(String title, String message, {Widget icon, Axis direction = Axis.horizontal, void Function() onRetry}) => customAlert(
    title,
    message,
    icon: icon,
    direction: direction,
    onAction: onRetry,
    actionLabel: 'Coba Lagi',
  );

  /// fungsi untuk menampilkan popup memuat data
  loadAlert([String label]) => showAlert(
    showButton: false,
    barrierDismissible: false,
    body: Row(children: <Widget>[
      SizedBox(width: 30, height: 30, child: Padding(
        padding: EdgeInsets.all(4),
        child: CircularProgressIndicator(strokeWidth: 4,),
      )),
      SizedBox(width: 12,),
      Text(label ?? "Tunggu sebentar ...")
    ],),
  );

  /// fungsi untuk menampilkan notifikasi flashbar
  Future<dynamic> showFlashBar(String title, String message, {Widget icon, int duration = 4000, bool showDismiss = true, String actionLabel, VoidCallback action}) {
    return showFlash(
      context: context,
      duration: Duration(milliseconds: duration),
      persistent: true,
      builder: (_, controller) {
        return Flash(
          controller: controller,
          backgroundColor: Colors.white,
          brightness: Brightness.light,
          boxShadows: [BoxShadow(color: Colors.grey[800], blurRadius: 8.0)],
          barrierBlur: 3.0,
          barrierColor: Colors.black38,
          barrierDismissible: true,
          style: FlashStyle.grounded,
          position: FlashPosition.top,
          child: FlashBar(
            title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),),
            // message: html(message),
            message: Text(message, style: TextStyle(fontSize: 15)),
            icon: icon,
            showProgressIndicator: false,
            primaryAction: showDismiss ? FlatButton(
              child: Text(actionLabel ?? 'TUTUP', style: TextStyle(color: THEME_COLOR)),
              onPressed: () {
                controller.dismiss();
                if (action != null) action();
              },
            ) : null,
          ),
        );
      },
    );
  }

  /// fungsi untuk menampilkan notifikasi flashbar sukses
  showFlashbarSuccess(String title, String message, {int duration = 5000}) {
    showFlashBar(title, message, duration: duration, showDismiss: false, icon: Padding(
      padding: EdgeInsets.only(left: 15, right: 4),
      child: Icon(LineIcons.check_circle, color: Colors.green, size: 40,),
    ));
  }

  /// fungsi untuk menampilkan popup pesan gagal login
  failAlertLogin([String message]) {
    failAlert("Login Gagal", message ?? "Terjadi masalah saat login. Coba kembali nanti!");
  }

  /// fungsi untuk menampilkan popup pesan gagal konek
  failAlertInternet({String message, void Function() onRetry, String onRetryLabel}) {
    showFlashBar(
      "Gagal Memuat",
      message ?? "Terjadi masalah saat memuat data. Harap periksa koneksi internet Anda!",
      actionLabel: onRetry == null ? 'TUTUP' : (onRetryLabel ?? 'REFRESH'),
      action: onRetry
    );
  }

  /// fungsi untuk menampilkan single image
  viewImage(dynamic image, {int page = 0}) {
    Navigator.of(context).pushNamed(ROUTE_IMAGE, arguments: {'image': image, 'page': page});
  }

  /// fungsi yang mengembalikan teks versi html
  Html html(String htmlString, {TextStyle textStyle}) {
    textStyle ??= Theme.of(context).textTheme.bodyText1;
    return Html(
      data: htmlString,
      style: {
        "body": Style(
          fontFamily: textStyle.fontFamily,
          fontSize: FontSize(textStyle.fontSize),
          fontStyle: textStyle.fontStyle,
          fontWeight: textStyle.fontWeight,
          color: textStyle.color,
          textAlign: TextAlign.start,
          margin: EdgeInsets.zero
        ),
      },
    );
  }

  MaterialRoundedDatePickerStyle get datePickerStyle {
    return MaterialRoundedDatePickerStyle(
      textStyleDayButton: TextStyle(fontSize: 18, color: Colors.white), //Rab, 19 Feb
      textStyleYearButton: TextStyle(fontSize: 45, color: Colors.white), //2020
      textStyleDayHeader: TextStyle(fontSize: 11), // M S S R K J S
      textStyleCurrentDayOnCalendar: TextStyle(fontSize: 16, color: THEME_COLOR),
      textStyleDayOnCalendar: TextStyle(fontSize: 16),
      textStyleDayOnCalendarSelected: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
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