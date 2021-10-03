import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:flutter_native_image/flutter_native_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart' show DateFormat, NumberFormat;
import 'package:intl/date_symbol_data_local.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:theme_provider/theme_provider.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';
import 'package:wechat_camera_picker/wechat_camera_picker.dart';
import '../plugins/toast.dart';
import 'constants.dart';
import 'models.dart';
import 'variables.dart';
import 'widgets.dart';

const ENABLE_GALLERY_UPLOAD = true;
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
      return _makeButton(button.label, action: button.onPressed);
    }).toList() ?? [];

    if (showCloseButton) actions.add(_makeButton(closeButtonText ?? "Tutup", color: closeButtonColor, action: closeDialog));

    return showGeneralDialog(
      barrierColor: Colors.black.withOpacity(0.5),
      barrierDismissible: isDismissible,
      transitionDuration: const Duration(milliseconds: 600),
      transitionBuilder: (context, a1, a2, widget) {
        final _curvedValue = Curves.easeInOutBack.transform(a1.value);
        return Theme(
          data: Theme.of(context),
          child: Transform(
            transform: Matrix4.identity()..scale(1.0, 0.5 + _curvedValue / 2, 1.0),
            child: Opacity(
              opacity: a1.value,
              child: SafeArea(
                child: AlertDialog(
                  backgroundColor: Colors.white,
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
  Future<bool?> showConfirmDialog(String message, {String? title}) async {
    return await showDialog(
      Text(message, style: const TextStyle(fontSize: 16),),
      title: title,
      buttonSize: MyButtonSize.SMALL,
      buttons: [
        MenuModel("Ya", true, onPressed: () => Navigator.of(context).pop(true)),
        MenuModel("Tidak", false, onPressed: () => Navigator.of(context).pop(false)),
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
  showToast(String message, {int duration = Toast.DEFAULT_DURATION}) {
    Toast.show(message, context, duration: duration);
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

  /// pilih warna berdasarkan tema yang aktif
  bool isLightMode() => ThemeProvider.themeOf(context).id == APP_UI_THEME_LIGHT;
  Color pickColor(Color light, Color dark) => isLightMode() ? light : dark;
  Color textColor([Color? defaultColor]) => pickColor(defaultColor ?? Colors.black, Colors.white);
  Color bgColor() => pickColor(Colors.white, Colors.black);
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
  // String formatTimeago(DateTime date) => timeago.format(date, locale: localeString());
  String formatJson(dynamic data) => const JsonEncoder.withIndent('  ').convert(data is String ? json.decode(data) : data);
  String formatNumber(num nominal) => NumberFormat("###,###.###", localeString()).format(nominal.toDouble());
  String formatPrice(dynamic nominal, {String symbol = 'Rp '}) => NumberFormat.currency(locale: localeString(), symbol: symbol).format(double.tryParse(nominal.toString()) ?? 0);
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
      return await h!.showCallbackDialog(
        "Harap aktifkan GPS untuk dapat menggunakan aplikasi ini.",
        title: "GPS Tidak Aktif",
        type: MyCallbackType.warning,
      );
    }

    callbackMessage() async => await h!.showCallbackDialog(
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
      await openAppSettings();
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
}

class AppHelper {
  ImageProvider<Object> imageProvider(src, {String? fallbackAsset}) {
    final fallback = AssetImage(fallbackAsset ?? DEFAULT_NONE_PIC_ASSET);
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
      if (image is String) {
        if (await File(image).exists()) return File(image); // path
        // else return ""; // TODO base64
      }
      if (image is File) return image; // file
      return null;
    }
    File? file = await getFile();
    if (file != null) {
      // final fileName = file.path.split('/').last;
      final properties = await FlutterNativeImage.getImageProperties(file.path);
      final imageResized = await FlutterNativeImage.compressImage(
        file.path,
        quality: SETUP_IMAGE_COMPRESS_QUALITY,
        targetWidth: SETUP_IMAGE_COMPRESS_RESIZE,
        targetHeight: (properties.height! * SETUP_IMAGE_COMPRESS_RESIZE / properties.width!).round()
      );
      String result = imageResized.path;
      if (toBase64) {
        result = fileToBase64(imageResized);
      }
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
  }) async {
    final maxSelect = maximum ?? MAX_IMAGE_UPLOAD;
    final numImages = selectedList.length;
    final numImagesEdit = uploadedList.length;
    if (numImages + numImagesEdit == maxSelect) {
      h!.showCallbackDialog(
        "Anda sudah memilih maksimal $maxSelect foto!",
        title: "Maksimal Foto",
        type: MyCallbackType.warning,
      );
      return null;
    }

    ImageSource? source = ImageSource.camera;

    if (ENABLE_GALLERY_UPLOAD) {
      source = await h!.showDialog(
        Column(
          children: pickImageOptions.map((menu) {
            final ImageSource source = menu.value;
            return MyMenuList(
              isLast: source == ImageSource.camera,
              menu: MenuModel(menu.label, source, icon: menu.icon),
              onPressed: (menu) {
                Navigator.of(context).pop(menu.value);
              },
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
    if (source == ImageSource.camera) {
      final AssetEntity? entity = await CameraPicker.pickFromCamera(
        context,
        enableAudio: false,
        shouldDeletePreviewFile: true,
        textDelegate: EnglishCameraPickerTextDelegate(),
      );
      if (entity != null) {
        resultList.add(entity);
      }
    } else {
      resultList = await AssetPicker.pickAssets(
        context,
        textDelegate: EnglishTextDelegate(),
        maxAssets: maxSelect,
        selectedAssets: selected,
        requestType: RequestType.image,
      ) ?? [];
    }
    return resultList;
  }

  Future<String?> promptPIN({String? title, bool showForgot = true, bool showUsePassword = true}) async {
    return await h!.showDialog(
      MyInputPIN(
        title: title ?? "Masukkan PIN",
        showForgot: showForgot,
        showUsePassword: showUsePassword,
      ),
      closeButtonText: "Batal",
      isDismissible: false,
    );
  }

  Future<void> forgotPassword() async {

  }

  logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('login_user_id');
    await prefs.remove('login_email');
    await FacebookAuth.instance.logOut();
    Navigator.of(context).popUntil((route) => route.isFirst);
  }
}