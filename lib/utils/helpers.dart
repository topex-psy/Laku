import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:flutter_native_image/flutter_native_image.dart';
import 'package:flash/flash.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart' show DateFormat, NumberFormat;
import 'package:intl/date_symbol_data_local.dart';
import 'package:line_icons/line_icons.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:theme_provider/theme_provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:wechat_assets_picker/wechat_assets_picker.dart';
// import 'package:wechat_camera_picker/wechat_camera_picker.dart';
import '../plugins/toast.dart';
import 'api.dart';
import 'constants.dart';
import 'models.dart';
import 'providers.dart';
import 'variables.dart';
import 'widgets.dart';

const MAX_IMAGE_UPLOAD = 10;
enum MyCallbackType {
  success,
  warning,
  error,
  info,
}
enum ImageSource {
  gallery,
  camera
}

class UIHelper {
  final BuildContext context;
  UIHelper(this.context);

  BuildContext get currentContext => context;

    /// fungsi untuk menampilkan notifikasi flashbar
  Future<dynamic> showFlashBar(String title, String message, {Widget? icon, int? duration, bool showDismiss = true, String? actionLabel, VoidCallback? action}) {
    return showFlash(
      context: context,
      duration: Duration(milliseconds: duration??4000),
      persistent: true,
      builder: (_, controller) {
        return Flash(
          controller: controller,
          backgroundColor: h.backgroundColor(),
          brightness: ThemeProvider.themeOf(context).data.brightness,
          boxShadows: [BoxShadow(color: Colors.grey[800]!, blurRadius: 8.0)],
          barrierBlur: 3.0,
          barrierColor: Colors.black38,
          barrierDismissible: true,
          behavior: FlashBehavior.fixed,
          position: FlashPosition.top,
          child: FlashBar(
            title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),),
            content: Text(message, style: const TextStyle(fontSize: 15)),
            icon: icon,
            showProgressIndicator: false,
            primaryAction: showDismiss ? FlatButton(
              child: Text(actionLabel ?? 'TUTUP', style: const TextStyle(color: APP_UI_COLOR_MAIN)),
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
  showFlashbarSuccess(String title, String message, {int? duration = 5000, IconData? icon, Color? iconColor}) {
    showFlashBar(title, message, duration: duration, showDismiss: false, icon: Padding(
      padding: const EdgeInsets.only(left: 15, right: 8),
      child: Icon(icon ?? LineIcons.checkCircle, color: iconColor ?? Colors.green, size: 40,),
    ));
  }

  /// fungsi untuk menampilkan pesan singkat di bawah layar
  showSnackbar(String message, {String actionText = "OK", VoidCallback? action}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
      action: SnackBarAction(
        onPressed: action ?? () {},
        label: actionText,
      ),
    ));
  }

  /// fungsi untuk menampilkan popup dialog berisi pesan atau konten apapun
  Future showDialog(Widget? body, {
    String? title,
    bool isDismissible = true,
    bool showCloseButton = true,
    String? closeButtonText,
    Color? closeButtonColor,
    List<MenuModel>? buttons,
    MyButtonSize? buttonSize,
  }) {
    _makeButton(String label, {Color? color, VoidCallback? action}) {
      return Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.all(4),
        child: MyButton(
          label,
          size: buttonSize,
          color: color,
          onPressed: action
        ),
      );
    }
    List<Widget> actions = buttons?.map((button) {
      return _makeButton(button.label, color: button.color, action: button.onPressed);
    }).toList() ?? [];

    if (showCloseButton) actions.add(_makeButton(closeButtonText ?? "Tutup", color: closeButtonColor, action: closeDialog));

    return showGeneralDialog(
      barrierColor: Colors.black.withOpacity(0.5),
      barrierDismissible: isDismissible,
      transitionDuration: const Duration(milliseconds: 600),
      transitionBuilder: (context, a1, a2, widget) {
        final _curvedValue = Curves.easeInOutBack.transform(a1.value);
        return Theme(
          // data: Theme.of(context),
          data: ThemeProvider.themeOf(context).data,
          child: Transform(
            transform: Matrix4.identity()..scale(1.0, 0.5 + _curvedValue / 2, 1.0),
            child: Opacity(
              opacity: a1.value,
              child: SafeArea(
                child: AlertDialog(
                  backgroundColor: h.backgroundColor(),
                  shape: ContinuousRectangleBorder(borderRadius: BorderRadius.circular(30.0)),
                  title: title == null ? const SizedBox() : Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18.0),),
                  titlePadding: title == null ? const EdgeInsets.only(top: 24) : const EdgeInsets.only(left: 24, right: 24, top: 24, bottom: 12),
                  content: SingleChildScrollView(padding: EdgeInsets.only(left: 24, right: 24, bottom: actions.isEmpty ? 24 : 8), child: body,),
                  contentPadding: EdgeInsets.zero,
                  actions: actions.isEmpty ? null : actions,
                ),
              ),
            ),
          ),
        );
      },
      barrierLabel: '',
      context: context,
      pageBuilder: (context, animation1, animation2) => Container()
    );
  }

  /// fungsi untuk menampilkan popup dialog konfirmasi
  Future<dynamic> showConfirmDialog(String message, {String? title, String? approveText, String? rejectText, Color? rejectColor, List<MenuModel> additionalButtons = const []}) async {
    return await showDialog(
      Text(message, style: const TextStyle(fontSize: 16),),
      title: title,
      buttonSize: MyButtonSize.SMALL,
      buttons: [
        MenuModel(approveText ?? "Ya", true, onPressed: () => Navigator.of(context).pop(true)),
        MenuModel(rejectText ?? "Tidak", false, color: rejectColor ?? Colors.grey[600], onPressed: () => Navigator.of(context).pop(false)),
        ...additionalButtons,
      ],
      showCloseButton: false,
    );
  }

  /// fungsi untuk menampilkan popup dialog sukses, error, warning, atau info
  Future showCallbackDialog(String message, {String? title, MyCallbackType type = MyCallbackType.success, String? devNote}) {
    IconData? icon;
    Color? color;
    switch (type) {
      case MyCallbackType.success:
        icon = Icons.check_circle;
        color = APP_UI_COLOR_SUCCESS;
        break;
      case MyCallbackType.warning:
        icon = Icons.warning_rounded;
        color = APP_UI_COLOR_WARNING;
        break;
      case MyCallbackType.error:
        icon = Icons.error;
        color = APP_UI_COLOR_DANGER;
        break;
      case MyCallbackType.info:
        icon = Icons.info;
        color = APP_UI_COLOR_INFO;
        break;
    }
    return showDialog(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Icon(icon, size: 60, color: color)),
          const SizedBox(height: 12,),
          title == null ? const SizedBox() : Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(title, textAlign: TextAlign.start, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.grey[800])),
          ),
          Text(message, textAlign: TextAlign.start, style: TextStyle(fontWeight: FontWeight.w500, color: Colors.grey[800])),
          isDebugMode && devNote != null ? Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(devNote, style: const TextStyle(fontSize: 12)),
          ) : const SizedBox(),
        ],
      ),
      // title: title,
      closeButtonText: "OK",
      closeButtonColor: color,
    );
  }

  /// fungsi untuk menampilkan notifikasi toast
  showToast(String message, {int duration = MyToast.DEFAULT_DURATION}) {
    MyToast.show(message, context, duration: duration);
  }

  /// fungsi untuk menampilkan loading
  showLoader([String? label]) => showDialog(
    Row(children: <Widget>[
      const SizedBox(width: 30, height: 30, child: Padding(
        padding: EdgeInsets.all(4),
        child: CircularProgressIndicator(strokeWidth: 3, color: APP_UI_COLOR_MAIN,),
      )),
      const SizedBox(width: 12,),
      Text(label ?? "Harap tunggu ...", style: const TextStyle(fontWeight: FontWeight.w500),),
    ],),
    showCloseButton: false,
    isDismissible: false,
  );

  /// fungsi untuk menutup dialog
  closeDialog() => Navigator.of(context, rootNavigator: true).pop();

  /// fungsi untuk parsing html
  Html html(String htmlString, {TextStyle? textStyle}) {
    textStyle ??= Theme.of(context).textTheme.bodyText1;
    return Html(
      data: htmlString,
      style: {
        "body": Style(
          fontFamily: textStyle?.fontFamily,
          fontSize: FontSize(textStyle?.fontSize),
          fontStyle: textStyle?.fontStyle,
          fontWeight: textStyle?.fontWeight,
          color: textStyle?.color,
          textAlign: TextAlign.start,
          margin: EdgeInsets.zero
        ),
      },
    );
  }

  closeDrawer() {
    if (screenScaffoldKey.currentState?.isEndDrawerOpen ?? false) Navigator.of(context).pop();
  }

  /// pilih warna berdasarkan tema yang aktif
  bool isLightMode() => ThemeProvider.themeOf(context).id == APP_UI_THEME_LIGHT;
  bool isDarkMode() => ThemeProvider.themeOf(context).id == APP_UI_THEME_DARK;
  Color? pickColor(Color? light, Color? dark) => isLightMode() ? light : dark;
  Color backgroundColor([Color? lightColor]) => pickColor(lightColor ?? APP_UI_BACKGROUND_LIGHT, APP_UI_BACKGROUND_DARK)!;
  Color textColor([Color? lightColor]) => pickColor(lightColor ?? Colors.black, Colors.white)!;
}

class FormatHelper {
  final BuildContext context;

  FormatHelper(BuildContext ctx) : this.initialize(ctx);

  // docs: https://api.flutter.dev/flutter/intl/DateFormat-class.html
  FormatHelper.initialize(this.context) {
    var format = initializeDateFormatting(localeString());
    Future.wait([format]);
  }

  String localeString() => context.locale.toString();

  String formatDate(dynamic date, {String format = "MMM dd, yyyy HH:mm"}) {
    if (date is String) date = DateTime.tryParse(date);
    if (date == null) return '';
    return DateFormat(format).format(date);
  }
  String formatTimeago(DateTime date) => timeago.format(date, locale: localeString());
  String formatJson(dynamic data) => const JsonEncoder.withIndent('  ').convert(data is String ? json.decode(data) : data);
  String formatNumber(num nominal) => NumberFormat("###,###.###", localeString()).format(nominal.toDouble());
  String formatPrice(dynamic nominal, {String symbol = 'Rp '}) => NumberFormat.currency(locale: localeString(), symbol: symbol).format(double.tryParse(nominal.toString()) ?? 0);
  String formatPriceAbbr(dynamic nominal, {String symbol = 'Rp ', bool singkat = false}) {
    var nom = nominal;
    var suf = '';
    if (singkat) {
      if (nom > 999999999999) {
        nom /= 1000000;
        suf = 'JT';
      } else if (nom > 999999999) {
        nom /= 1000;
        suf = 'K';
      }
    }
    var res = NumberFormat.currency(locale: localeString(), symbol: symbol, decimalDigits: 0).format(nom);
    return "$res$suf";
  }
  String formatPercentage(num nominal, num total, {int decimal = 1}) => "${percentage(nominal, total).toStringAsFixed(decimal)}%";
  String formatDistance(double meter) {
    if (meter > 999) return "${roundNumber(meter / 1000)} km";
    return "${roundNumber(meter)} m";
  }

  bool isNumeric(String? s) => s != null && num.tryParse(s) != null;
  bool isValidEmail(String? email) => email != null && RegExp(r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?)*$").hasMatch(email);
  bool isValidURL(String? url) => url != null && Uri.parse(url).isAbsolute;

  double percentage(num nominal, num total) => total == 0 ? 0 : nominal * 100 / total;
  num roundNumber(num nominal, {int maxDecimal = 1}) => num.parse(nominal.toStringAsFixed(maxDecimal));
  int generateHash() => DateTime.now().millisecondsSinceEpoch;
}

class LocationHelper {
  Future<dynamic> checkGPS() async {
    LocationPermission permission;
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return await h.showCallbackDialog(
        "Harap aktifkan GPS untuk dapat menggunakan aplikasi ini.",
        title: "GPS Tidak Aktif",
        type: MyCallbackType.warning,
      );
    }

    callbackMessage() async => await h.showCallbackDialog(
      "Izin akses lokasi dibutuhkan untuk dapat menggunakan aplikasi ini.",
      title: "Izin Dibutuhkan",
      type: MyCallbackType.warning,
    );

    permission = await Geolocator.checkPermission();
    print("location permission 1: $permission");
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    print("location permission 2: $permission");
    if (permission == LocationPermission.deniedForever) {
      await callbackMessage();
      print("location permission: will open app settings");
      await Geolocator.openAppSettings();
      permission = await Geolocator.checkPermission();
    }
    print("location permission 3: $permission");
    if ([LocationPermission.whileInUse, LocationPermission.always].contains(permission)) return await myPosition();
    return await callbackMessage();
  }

  Future<Position> myPosition() async {
    return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.bestForNavigation);
  }
  Future<Position?> lastPosition() async {
    return await Geolocator.getLastKnownPosition();
  }
  Future<Position?> pickPosition([Position? currentPosition]) async {
    return await h.showDialog(
      Container(), // TODO google map
      closeButtonText: 'action_cancel'.tr(),
      isDismissible: false,
    );
  }
}

class AppHelper {
  ImageProvider<Object> imageProvider(src, {String? fallbackAsset}) {
    final fallback = AssetImage(fallbackAsset ?? SETUP_IMAGE_NONE);
    if (src is AssetEntity) return AssetEntityImageProvider(src, isOriginal: true);
    if (src is File) return FileImage(src);
    if (src is String) {
      if (src.isEmpty) return fallback;
      if (src.startsWith("http") || src.startsWith("data:image/")) return NetworkImage(src);
      return AssetImage(src);
    }
    return fallback;
  }

  Future<String?> compressImage(dynamic image, {bool toBase64 = false}) async {
    Future<File?> getFile() async {
      if (image is AssetEntity) return await image.file; // asset entity
      if (image is String) return File(image); // path
      if (image is File) return image; // file
      return null;
    }
    File? file = await getFile();
    if (file != null && await file.exists()) {
      // final fileName = file.path.split('/').last;
      final properties = await FlutterNativeImage.getImageProperties(file.path);
      final imageResized = await FlutterNativeImage.compressImage(
        file.path,
        quality: SETUP_IMAGE_COMPRESS_QUALITY,
        targetWidth: SETUP_IMAGE_COMPRESS_RESIZE,
        targetHeight: (properties.height! * SETUP_IMAGE_COMPRESS_RESIZE / properties.width!).round()
      );
      String result = toBase64 ? fileToBase64(imageResized) : imageResized.path;
      return result;
    }
    return null;
  }

  String fileToBase64(File file) {
    final imageBytes = file.readAsBytesSync();
    final base64Image = base64Encode(imageBytes);
    // final base64 = 'data:image/jpg;base64,' + base64Image;
    return base64Image;
  }
}

class UserHelper {
  final BuildContext context;
  UserHelper(this.context);

  Future<List<AssetEntity>?> browsePicture({
    int? maximum,
    List<AssetEntity> selectedList = const [],
    List<String> uploadedList = const [],
    bool withGallery = true,
  }) async {
    final maxSelect = maximum ?? MAX_IMAGE_UPLOAD;
    final numImages = selectedList.length;
    final numImagesEdit = uploadedList.length;
    if (numImages + numImagesEdit == maxSelect) {
      h.showCallbackDialog(
        "Anda sudah memilih maksimal $maxSelect foto!",
        title: "Maksimal Foto",
        type: MyCallbackType.warning,
      );
      return null;
    }

    ImageSource? source = ImageSource.camera;

    if (withGallery) {
      source = await h.showDialog(
        Column(
          children: pickImageOptions.map((menu) {
            final ImageSource source = menu.value;
            return MyMenuList(
              isLast: source == ImageSource.camera,
              menu: MenuModel(menu.label, source, icon: menu.icon, onPressed: () {
                Navigator.of(context).pop(source);
              }),
            );
          }).toList(),
        ),
        closeButtonText: "Batal",
        buttonSize: MyButtonSize.SMALL
      );
      if (source == null) return null;
    }

    var resultList = await takePicture(source, maxSelect: maxSelect - uploadedList.length, selected: selectedList);

    print("resultList = $resultList");
    return resultList;
  }

  Future<List<AssetEntity>> takePicture(ImageSource source, {
    int maxSelect = MAX_IMAGE_UPLOAD,
    selected = const <AssetEntity>[],
  }) async {
    var resultList = <AssetEntity>[...selected];
    // TODO FIXME camera source
    // if (source == ImageSource.camera) {
    //   final AssetEntity? entity = await CameraPicker.pickFromCamera(
    //     context,
    //     enableAudio: false,
    //     shouldDeletePreviewFile: true,
    //     textDelegate: EnglishCameraPickerTextDelegate(),
    //   );
    //   if (entity != null) {
    //     resultList.add(entity);
    //   }
    // } else {
      resultList = await AssetPicker.pickAssets(
        context,
        textDelegate: EnglishTextDelegate(),
        maxAssets: maxSelect,
        selectedAssets: selected,
        requestType: RequestType.image,
      ) ?? [];
    // }
    return resultList;
  }

  Future<String?> promptPIN({String? title, bool showForgot = true, bool showUsePassword = true}) async {
    return await h.showDialog(
      MyInputPIN(
        title: title ?? 'placeholder.pin'.tr(),
        showForgot: showForgot,
        showUsePassword: showUsePassword,
      ),
      closeButtonText: 'action_cancel'.tr(),
      isDismissible: false,
    );
  }

  Future<void> firebaseUpdateProfile({String? name, String? image}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (name != null) await user?.updateDisplayName(name);
    if (image != null) await user?.updatePhotoURL(image);
  }

  Future<void> firebaseUpdatePhoneNumber(PhoneAuthCredential credential) async {
    final user = FirebaseAuth.instance.currentUser;
    return user?.updatePhoneNumber(credential);
  }

  Future<void> firebaseUpdateEmail(String email) async {
    final user = FirebaseAuth.instance.currentUser;
    return user?.updateEmail(email);
  }

  Future<void> forgotPassword() async {
    // TODO forgot password
  }

  navigatePage(int page) {
    h.closeDrawer();
    screenPageController.animateToPage(page, duration: const Duration(milliseconds: 500), curve: Curves.ease);
    firebaseAnalytics.setCurrentScreen(
      screenName: screenNames[page],
    );
  }

  openProfile() => navigatePage(tabProfile);

  Future<bool> loadNotif() async {
    if (session?.id == null) return false;
    final notifResult = await ApiProvider(context).api("user/notif", method: "get", withLog: true);
    if (notifResult.isSuccess) {
      Provider.of<SettingsProvider>(context, listen: false).setSettings(
        notif: NotifModel.fromJson(notifResult.data.first)
      );
    }
    return notifResult.isSuccess;
  }

  openMyListings() {
    // TODO go to my listings
  }

  /// store user data to shared prefs and put last position to provider
  Future<void> login() async {
    if (profile == null) return;
    session = SessionModel.fromUserModel(profile!);
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('login_user_id', session!.id);
    await prefs.setString('login_email', session!.email);
    print("user session: $session");
    if (profile!.lastLatitude != null && profile!.lastLongitude != null) {
      Provider.of<SettingsProvider>(context, listen: false).setSettings(
        lastLatitude: profile!.lastLatitude,
        lastLongitude: profile!.lastLongitude,
      );
    }
    await firebaseAnalytics.setUserId(profile!.id.toString());
    await firebaseAnalytics.setUserProperty(name: 'email', value: profile!.email);
    await firebaseAnalytics.logLogin();
  }

  Future<void> logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('login_id');
    await prefs.remove('login_email');
    await FacebookAuth.instance.logOut();
    Navigator.of(context).popUntil((route) => route.isFirst);
  }
}