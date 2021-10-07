import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_html/style.dart';
import 'package:flutter_rounded_date_picker/flutter_rounded_date_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fab_circular_menu/fab_circular_menu.dart';
import 'package:line_icons/line_icons.dart';
import 'package:theme_provider/theme_provider.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';
import 'package:wechat_camera_picker/wechat_camera_picker.dart';
import '../plugins/datetime_picker_formfield.dart';
import '../plugins/image_gallery_viewer.dart';
import '../plugins/image_viewer.dart';
import 'constants.dart';
import 'curves.dart';
import 'models.dart';
import 'variables.dart';

enum MyInputType {
  TEXT,
  PASSWORD,
  NAME,
  EMAIL,
  ADDRESS,
  PHONE,
  NOTE,
  URL,
  DATE,
  DATETIME,
  BIRTHDATE,
  NUMBER,
  CURRENCY,
  PIN,
  QTY,
  SEARCH,
}

enum MyButtonSize {
  SMALLEST,
  SMALLER,
  SMALL,
  MEDIUM,
  LARGE,
}

enum MyLogoType {
  logo,
  icon,
  iconFull,
  splash,
  text,
  inverted,
}

class MyAppLogo extends StatelessWidget {
  const MyAppLogo({ this.size = 100.0, this.type = MyLogoType.logo, this.fit = BoxFit.contain, Key? key }) : super(key: key);
  final double size;
  final MyLogoType type;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    String path;
    switch (type) {
      case MyLogoType.icon:
        path = "assets/images/logo/icon.png";
        break;
      case MyLogoType.iconFull:
        path = "assets/images/logo/icon-full.png";
        break;
      case MyLogoType.splash:
        path = "assets/images/logo/splash.png";
        break;
      case MyLogoType.text:
        path = "assets/images/logo/text.png";
        break;
      case MyLogoType.inverted:
        path = "assets/images/logo/logo-inverted.png";
        break;
      default:
        path = "assets/images/logo/logo.png";
        break;
    }
    return Semantics(
      label: "$APP_NAME logo",
      image: true,
      child: Image.asset(path, width: size, height: size, fit: fit),
    );
  }
}

class MyInputCheck extends StatelessWidget {
  const MyInputCheck({ required this.onChanged, required this.value, required this.label, Key? key }) : super(key: key);
  final void Function(bool?) onChanged;
  final bool value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      activeColor: APP_UI_COLOR_SUCCESS,
      controlAffinity: ListTileControlAffinity.leading,
      dense: true,
      title: Text(label, style: const TextStyle(fontSize: 16)),
      value: value,
      onChanged: onChanged,
    );
  }
}

class MyButton extends StatelessWidget {
  const MyButton(this.text, {
    Key? key,
    this.color,
    this.textColor,
    this.textColorPressed,
    this.highlightColor,
    this.border,
    this.radius,
    this.fullWidth = false,
    this.iconRight = false,
    this.icon,
    this.size,
    this.onPressed,
    this.disabled = false
  }) : super(key: key);
  final Color? color;
  final Color? textColor;
  final Color? textColorPressed;
  final Color? highlightColor;
  final BorderSide? border;
  final double? radius;
  final String text;
  final VoidCallback? onPressed;
  final bool fullWidth;
  final bool iconRight;
  final IconData? icon;
  final MyButtonSize? size;
  final bool disabled;

  double get fontSize {
    switch (size) {
      case MyButtonSize.SMALLEST: return 14;
      case MyButtonSize.SMALLER: return 16;
      case MyButtonSize.SMALL: return 18;
      case MyButtonSize.LARGE: return 22;
      default: return 20;
    }
  }

  EdgeInsets get padding {
    switch (size) {
      case MyButtonSize.SMALLEST: return const EdgeInsets.symmetric(horizontal: 12, vertical: 4);
      case MyButtonSize.SMALLER: return const EdgeInsets.symmetric(horizontal: 18, vertical: 7);
      case MyButtonSize.SMALL: return const EdgeInsets.symmetric(horizontal: 24, vertical: 10);
      case MyButtonSize.LARGE: return const EdgeInsets.symmetric(horizontal: 36, vertical: 16);
      default: return const EdgeInsets.symmetric(horizontal: 30, vertical: 13);
    }
  }

  @override
  Widget build(BuildContext context) {
    var buttonChilds = [
      icon == null ? const SizedBox() : Icon(icon, color: Colors.white),
      icon == null || text.isEmpty ? const SizedBox() : const SizedBox(width: 8),
      Text(text),
    ];
    if (iconRight) buttonChilds = buttonChilds.reversed.toList();
    return SizedBox(
      width: fullWidth ? double.infinity : null,
      child: Opacity(
        opacity: disabled || onPressed == null ? 0.7 : 1.0,
        child: ElevatedButton(
          onPressed: disabled ? null : onPressed,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
            children: buttonChilds,
          ),
          style: ButtonStyle(
            foregroundColor: MaterialStateProperty.all(textColor ?? Colors.white),
            backgroundColor: MaterialStateProperty.all(color ?? APP_UI_COLOR_MAIN),
            overlayColor: MaterialStateProperty.all(highlightColor ?? Colors.white24),
            padding: MaterialStateProperty.all(padding),
            textStyle: MaterialStateProperty.resolveWith<TextStyle>((Set<MaterialState> states) {
              if (states.contains(MaterialState.pressed)) {
                return TextStyle(
                  fontFamily: APP_UI_FONT_MAIN,
                  fontSize: fontSize,
                  fontWeight: FontWeight.w600,
                  color: textColorPressed ?? Colors.white
                );
              }
              return TextStyle(
                fontFamily: APP_UI_FONT_MAIN,
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
                color: textColor ?? Colors.white
              );
            },),
            shape: MaterialStateProperty.all<RoundedRectangleBorder>(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(radius ?? APP_UI_BORDER_RADIUS),
                side: border ?? BorderSide(color: color ?? APP_UI_COLOR_MAIN)
              ),
            ),
            elevation: MaterialStateProperty.all(0),
          ),
        ),
      ),
    );
  }
}

class MyInputField extends StatefulWidget {
  const MyInputField({
    Key? key,
    required this.label,
    this.inputType = MyInputType.TEXT,
    this.inputAction = TextInputAction.done,
    this.size = MyButtonSize.MEDIUM,
    this.icon,
    this.color,
    this.maxLength,
    this.showLabel = true,
    this.readOnly = false,
    this.isClearable = false,
    this.browseIcon,
    this.onBrowse,
    this.onSubmitted,
    this.dateFormat = "dd/MM/yyyy",
    this.controller,
    this.focusNode,
    this.error,
    this.editMode = false,
  }) : super(key: key);
  final String label;
  final MyInputType inputType;
  final TextInputAction? inputAction;
  final MyButtonSize size;
  final IconData? icon;
  final Color? color;
  final int? maxLength;
  final bool showLabel;
  final bool readOnly;
  final bool isClearable;
  final IconData? browseIcon;
  final VoidCallback? onBrowse;
  final void Function(String)? onSubmitted;
  final String dateFormat;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? error;
  final bool editMode;

  @override
  State<MyInputField> createState() => _MyInputFieldState();
}

class _MyInputFieldState extends State<MyInputField> {
  var _viewText = false;
  var _editText = false;

  TextInputType get keyboardType {
    if (isNumberInput) return TextInputType.number;
    switch (widget.inputType) {
      case MyInputType.NAME: return TextInputType.name;
      case MyInputType.EMAIL: return TextInputType.emailAddress;
      case MyInputType.ADDRESS: return TextInputType.streetAddress;
      case MyInputType.PHONE: return TextInputType.phone;
      case MyInputType.NOTE: return TextInputType.multiline;
      case MyInputType.URL: return TextInputType.url;
      case MyInputType.DATETIME: return TextInputType.datetime;
      default: return TextInputType.text;
    }
  }

  TextCapitalization get textCapitalization {
    switch (widget.inputType) {
      case MyInputType.NAME: return TextCapitalization.words;
      case MyInputType.NOTE: return TextCapitalization.sentences;
      default: return TextCapitalization.none;
    }
  }

  Widget? get suffixIcon {
    if (widget.editMode) {
      return IconButton(icon: Icon(_editText ? Icons.lock : Icons.edit), iconSize: _editText ? 18 : 24, color: Colors.grey, onPressed: () {
        setState(() {
          _editText = !_editText;
        });
      },);
    }
    if (widget.onBrowse != null || widget.inputType == MyInputType.PIN) {
      var browseIcon = widget.browseIcon;
      if (widget.browseIcon == null) {
        switch (widget.inputType) {
          case MyInputType.PIN:
            browseIcon = Icons.keyboard;
            break;
          default:
            browseIcon = Icons.chevron_right;
        }
      }
      return IconButton(icon: Icon(browseIcon), iconSize: 24, color: Colors.grey, onPressed: onBrowse,);
    }
    if (widget.inputType == MyInputType.PASSWORD) {
      return IconButton(icon: Icon(_viewText ? Icons.visibility_off : Icons.visibility), iconSize: 24, color: Colors.grey, onPressed: () {
        setState(() { _viewText = !_viewText; });
      },);
    }
    if (widget.isClearable) {
      if (widget.controller?.text.isEmpty ?? false) return const SizedBox();
      return IconButton(icon: const Icon(Icons.close), iconSize: 24, color: Colors.grey, onPressed: () {
        widget.controller?.text = "";
      },);
    }
    return null;
  }

  EdgeInsetsGeometry get padding {
    switch (widget.size) {
      case MyButtonSize.SMALLEST: return const EdgeInsets.symmetric(horizontal: 14, vertical: 6.0);
      case MyButtonSize.SMALLER: return const EdgeInsets.symmetric(horizontal: 16, vertical: 8.0);
      case MyButtonSize.SMALL: return const EdgeInsets.symmetric(horizontal: 18, vertical: 10.0);
      case MyButtonSize.MEDIUM: return const EdgeInsets.symmetric(horizontal: 20, vertical: 12.0);
      case MyButtonSize.LARGE: return const EdgeInsets.symmetric(horizontal: 24, vertical: 14.0);
    }
  }

  double get fontSize {
    switch (widget.size) {
      case MyButtonSize.SMALLEST: return 13.0;
      case MyButtonSize.SMALLER: return 14.0;
      case MyButtonSize.SMALL: return 15.0;
      case MyButtonSize.MEDIUM: return 16.0;
      case MyButtonSize.LARGE: return 18.0;
    }
  }

  InputBorder inputBorder({String type = "normal"}) {
    return OutlineInputBorder(
      borderRadius: const BorderRadius.all(Radius.circular(APP_UI_BORDER_RADIUS),),
      borderSide: BorderSide(
        color: {"focus": APP_UI_COLOR[600], "error": APP_UI_COLOR_DANGER}[type] ?? APP_UI_BORDER_COLOR,
        width: {"focus": 2.0}[type] ?? 1.0,
      ),
      gapPadding: 0
    );
  }

  InputDecoration get inputDecoration {
    Widget? prefix;
    switch (widget.inputType) {
      case MyInputType.CURRENCY:
        prefix = Text("Rp ", style: inputStyle);
        break;
      case MyInputType.PHONE:
        prefix = Text("$APP_PHONE_CODE ", style: inputStyle);
        break;
      default:
    }
    return InputDecoration(
      errorBorder: inputBorder(type: "error"),
      focusedBorder: inputBorder(type: "focus"),
      focusedErrorBorder: inputBorder(type: "error"),
      labelStyle: TextStyle(color: h!.pickColor(APP_UI_COLOR[700], APP_UI_COLOR[400])),
      labelText: widget.showLabel ? widget.label : null,
      prefix: prefix,
      prefixIcon: widget.icon == null ? null : Icon(widget.icon, color: Colors.grey,),
      suffixIcon: suffixIcon,
      border: inputBorder(),
      enabledBorder: inputBorder(),
      contentPadding: padding,
      hintText: widget.label,
      hintMaxLines: widget.inputType == MyInputType.NOTE ? null : 1,
      hintStyle: const TextStyle(color: Colors.grey),
      filled: true,
      // fillColor: widget.color ?? (widget.editMode && !_editText ? APP_UI_COLOR_ACCENT.withOpacity(.1) : Colors.white.withOpacity(.2)),
      fillColor: widget.color ?? (widget.editMode && !_editText ? APP_UI_COLOR_ACCENT.withOpacity(.1) : h!.backgroundColor(Colors.white)),
      isDense: true,
    );
  }

  bool get isNumberInput => widget.inputType == MyInputType.CURRENCY || widget.inputType == MyInputType.NUMBER || widget.inputType == MyInputType.PIN || widget.inputType == MyInputType.QTY;
  bool get isDateInput => widget.inputType == MyInputType.DATE || widget.inputType == MyInputType.BIRTHDATE;

  List<TextInputFormatter> get inputFormatters {
    var formatters = <TextInputFormatter>[];
    if (widget.maxLength != null) {
      formatters.add(LengthLimitingTextInputFormatter(widget.maxLength));
    } else if (widget.inputType == MyInputType.CURRENCY) {
      formatters.add(LengthLimitingTextInputFormatter(SETUP_MAX_LENGTH_CURRENCY));
    } else if (widget.inputType == MyInputType.PIN) {
      formatters.add(LengthLimitingTextInputFormatter(SETUP_MAX_LENGTH_PIN));
    }
    if (isNumberInput) {
      // formatters.add(FilteringTextInputFormatter.allow(RegExp(r'[1-9]')));
      formatters.add(FilteringTextInputFormatter.digitsOnly);
    }
    if (widget.inputType == MyInputType.CURRENCY) {
      formatters.add(MyCurrencyInputFormatter(context));
    }
    return formatters;
  }

  VoidCallback? get onBrowse {
    if (widget.onBrowse != null) widget.onBrowse;
    switch (widget.inputType) {
      case MyInputType.PIN:
        return () => widget.focusNode?.requestFocus();
      default:
        return null;
    }
  }

  TextStyle get inputStyle {
    return TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.w600,
      color: h!.textColor(),
    );
  }

  Widget get inputField {

    if (isDateInput) {
      final datePickerStyle = MaterialRoundedDatePickerStyle(
        backgroundActionBar: h!.pickColor(APP_UI_COLOR[400]!, Colors.grey[800]!), // footer
        backgroundHeader: h!.pickColor(APP_UI_COLOR[400]!, Colors.grey[800]!), // header
        backgroundHeaderMonth: h!.pickColor(APP_UI_COLOR[400]!, Colors.grey[850]!),
        colorArrowNext: Colors.white,
        colorArrowPrevious: Colors.white,
        paddingActionBar: EdgeInsets.zero,
        paddingDatePicker: EdgeInsets.zero,
        paddingMonthHeader: const EdgeInsets.all(14),
        textStyleButtonAction: const TextStyle(fontSize: 14, color: Colors.white),
        textStyleButtonPositive: const TextStyle(fontSize: 14, color: Colors.white),
        textStyleButtonNegative: const TextStyle(fontSize: 14, color: Colors.white),
        textStyleCurrentDayOnCalendar: TextStyle(fontSize: 16, color: h!.pickColor(APP_UI_COLOR_MAIN, APP_UI_COLOR[300]!)),
        textStyleDayButton: TextStyle(fontSize: 18, color: h!.textColor()), // header tanggal
        textStyleDayHeader: TextStyle(fontSize: 11, color: h!.textColor().withOpacity(0.54)), // M S S R K J S
        textStyleDayOnCalendar: TextStyle(fontSize: 16, color: h!.textColor()),
        textStyleDayOnCalendarSelected: TextStyle(fontSize: 17, color: h!.backgroundColor(), fontWeight: FontWeight.bold),
        textStyleMonthYearHeader: const TextStyle(fontSize: 15, color: Colors.white, fontWeight: FontWeight.bold), // Februari 2020
        textStyleYearButton: const TextStyle(fontSize: 45, color: Colors.white), // header tahun
      );

      final yearPickerStyle = MaterialRoundedYearPickerStyle(
        textStyleYear: TextStyle(fontSize: 20, color: h!.textColor(Colors.grey[700])),
        textStyleYearSelected: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: APP_UI_COLOR_MAIN),
      );

      return DateTimeField(
        textAlign: TextAlign.start,
        readOnly: widget.readOnly,
        controller: widget.controller,
        showCursor: false,
        format: DateFormat(widget.dateFormat, context.locale.toString()),
        // initialValue: widget.initialValue == null ? null : (widget.initialValue is DateTime ? widget.initialValue : DateTime.parse(widget.initialValue.toString())),
        style: inputStyle,
        decoration: inputDecoration,
        onShowPicker: (context, currentValue) {
          DateTime now = DateTime.now();
          DateTime min = DateTime(2019);
          DateTime max = now;
          if (widget.inputType == MyInputType.BIRTHDATE) {
            min = now.subtract(const Duration(days: SETUP_MAX_USER_AGE * 365)); // umur maksimal
            max = now.subtract(const Duration(days: SETUP_MIN_USER_AGE * 365)); // umur minimal
          }
          return showRoundedDatePicker(
            context: context,
            initialDate: currentValue ?? max,
            firstDate: min,
            lastDate: max,
            borderRadius: 16, //APP_UI_BORDER_RADIUS,
            locale: context.locale,
            initialDatePickerMode: widget.inputType == MyInputType.BIRTHDATE ? DatePickerMode.year : DatePickerMode.day,
            theme: ThemeProvider.themeOf(context).data,
            customWeekDays: context.locale.languageCode == "id"
              ? ["Min", "Sen", "Sel", "Rab", "Kam", "Jum", "Sab"]
              : ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"],
            onTapDay: (dateTime, available) => available,
            styleDatePicker: datePickerStyle,
            styleYearPicker: yearPickerStyle
          );
        },
        // onChanged: widget.onChanged,
        // validator: _validator,
      );
    }

    final readOnly = widget.editMode ? !_editText : widget.readOnly;

    return TextField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      obscureText: widget.inputType == MyInputType.PASSWORD && !_viewText,
      decoration: inputDecoration,
      maxLines: widget.inputType == MyInputType.NOTE ? 3 : 1,
      inputFormatters: inputFormatters,
      style: inputStyle,
      textInputAction: widget.inputAction,
      onSubmitted: widget.onSubmitted,
      enableInteractiveSelection: !readOnly && widget.onBrowse == null && !isDateInput,
      readOnly: readOnly,
      onTap: onBrowse,
      onChanged: (val) {
        if (widget.controller != null) {
          switch (widget.inputType) {
            case MyInputType.PHONE:
              if (val[0] == '0') {
                widget.controller!.text = val.substring(1);
              }
              break;
            default:
          }
        }
        // widget.onChanged(val);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        inputField,
        widget.error == null ? const SizedBox() : MyInputError(widget.error!),
      ],
    );
  }
}

class MyInputPIN extends StatefulWidget {
  const MyInputPIN({this.title, this.showForgot = true, this.showUsePassword = true, Key? key}) : super(key: key);
  final String? title;
  final bool showForgot;
  final bool showUsePassword;

  @override
  _MyInputPINState createState() => _MyInputPINState();
}

class _MyInputPINState extends State<MyInputPIN> {
  var _usePassword = false;
  var _isSendingRecoveryEmail = false;
  var _pressKey = 0;
  String? _passwordError;

  final TextEditingController textController = TextEditingController();
  final FocusNode textFocus = FocusNode();

  _submitPassword(String password) {
    if (textController.text.isEmpty) {
      setState(() {
        _passwordError = "Masukkan kata sandi";
      });
    } else {
      Navigator.of(context).pop(password);
    }
  }

  @override
  void initState() {
    textController.addListener(() {
      setState(() {
        _passwordError = null;
      });
    });
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
    Widget _makeButton(int angka) {
      bool isPencetTombol = _pressKey == angka;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 100),
          opacity: isPencetTombol ? 0.5 : 1,
          child: SizedBox(width: 64, height: 64, child: Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              side: BorderSide(color: APP_UI_COLOR_MAIN.withOpacity(0.5), width: isPencetTombol ? 4.0 : 1.0,),
              borderRadius: BorderRadius.circular(50.0),
            ),
            clipBehavior: Clip.antiAlias,
            child: Material(
              color: isPencetTombol ? APP_UI_COLOR_MAIN : Colors.transparent,
              child: InkWell(
                highlightColor: Colors.transparent,
                splashColor: Colors.transparent,
                onHighlightChanged: (val) => setState(() { _pressKey = val ? angka : 0; }),
                onTap: () {
                  if (textController.text.length < SETUP_MAX_LENGTH_PIN) {
                    textController.text = "${textController.text}$angka";
                    if (textController.text.length == SETUP_MAX_LENGTH_PIN) Navigator.of(context).pop(textController.text);
                  }
                },
                child: Center(child: Text("$angka", style: const TextStyle(fontSize: 20),),),
              ),
            ),
          ),),
        ),
      );
    }
    return Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
      Row(crossAxisAlignment: CrossAxisAlignment.center, children: <Widget>[
        Expanded(child: Text(widget.title ?? "Masukkan ${_usePassword ? 'Sandi' : 'PIN'}:", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700))),
        const SizedBox(width: 4,),
        widget.showForgot
        ? Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: _isSendingRecoveryEmail ? const MyMiniLoader() : Material(
            borderRadius: BorderRadius.circular(20),
            color: Colors.grey[300],
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
                child: Text('action_forgot'.tr(), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),),
              ),
              onTap: () async {
                setState(() { _isSendingRecoveryEmail = true; });
                await u!.forgotPassword();
                setState(() { _isSendingRecoveryEmail = false; });
              },
            ),
          ),
        )
        : const SizedBox(),
      ],),
      Column(
        mainAxisSize: MainAxisSize.min,
        children: _usePassword ? <Widget>[
          const SizedBox(height: 20,),
          MyInputField(
            label: 'placeholder.password'.tr(),
            inputType: MyInputType.PASSWORD,
            controller: textController,
            focusNode: textFocus,
            onSubmitted: (password) {
              _submitPassword(password);
            },
            error: _passwordError,
          ),
          const SizedBox(height: 12.0,),
          MyButton('action_login'.tr(), fullWidth: true, onPressed: () {
            _submitPassword(textController.text);
          },),
          const SizedBox(height: 20,),
          GestureDetector(
            child: Text('action_use_pin'.tr(), style: const TextStyle(color: APP_UI_COLOR_MAIN, fontSize: 15, fontWeight: FontWeight.w600),),
            onTap: () {
              setState(() {
                _passwordError = null;
                _usePassword = false;
              });
              textController.text = '';
            },
          ),
        ] : <Widget>[
          Stack(
            alignment: Alignment.centerRight,
            children: <Widget>[
              IgnorePointer(
                child: TextFormField(
                  obscureText: true,
                  readOnly: true,
                  // inputFormatters: <TextInputFormatter>[
                  //   WhitelistingTextInputFormatter.digitsOnly,
                  //   FilteringTextInputFormatter.allow(RegExp(r'[1-9]')),
                  //   LengthLimitingTextInputFormatter(6),
                  // ],
                  maxLines: 1,
                  decoration: const InputDecoration(border: InputBorder.none),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontFamily: APP_UI_FONT_MAIN, fontSize: 30, letterSpacing: 5, color: APP_UI_COLOR_MAIN),
                  controller: textController,
                  focusNode: textFocus,
                ),
              ),
              IconButton(
                onPressed: () {
                  if (textController.text.isNotEmpty) textController.text = textController.text.substring(0, textController.text.length - 1);
                },
                icon: const Icon(Icons.backspace, color: Colors.grey, size: 18,),
              )
            ],
          ),
          Row(mainAxisSize: MainAxisSize.max, mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: <Widget>[
            for (var n = 1; n <= 3; n++) _makeButton(n)
          ],),
          Row(mainAxisSize: MainAxisSize.max, mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: <Widget>[
            for (var n = 4; n <= 6; n++) _makeButton(n)
          ],),
          Row(mainAxisSize: MainAxisSize.max, mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: <Widget>[
            for (var n = 7; n <= 9; n++) _makeButton(n)
          ],),
          widget.showUsePassword ? Padding(
            padding: const EdgeInsets.only(top: 20.0),
            child: GestureDetector(
              child: Text("action_use_password".tr(), style: const TextStyle(color: APP_UI_COLOR_MAIN, fontSize: 15, fontWeight: FontWeight.w600),),
              onTap: () {
                setState(() { _usePassword = true; });
                textController.text = '';
                textFocus.requestFocus();
              },
            ),
          ) : const SizedBox(),
        ],
      ),
    ],);
  }
}

class MyInputSelect extends StatefulWidget {
  const MyInputSelect({
    Key? key,
    this.icon,
    required this.listMenu,
    required this.onSelect,
    this.value,
    this.color,
    this.placeholder,
    this.size = MyButtonSize.MEDIUM,
    this.margin,
    this.error = ''
  }) : super(key: key);
  final IconData? icon;
  final List<MenuModel> listMenu;
  final MenuModel? value;
  final Color? color;
  final String? placeholder;
  final EdgeInsetsGeometry? margin;
  final MyButtonSize size;
  final void Function(MenuModel?) onSelect;
  final String error;

  @override
  _MyInputSelectState createState() => _MyInputSelectState();
}

class _MyInputSelectState extends State<MyInputSelect> {
  MenuModel? _val;

  EdgeInsetsGeometry get padding {
    switch (widget.size) {
      case MyButtonSize.SMALLEST: return const EdgeInsets.symmetric(vertical: 1, horizontal: 0);
      case MyButtonSize.SMALLER: return const EdgeInsets.symmetric(vertical: 2, horizontal: 3);
      case MyButtonSize.SMALL: return const EdgeInsets.symmetric(vertical: 4, horizontal: 6);
      case MyButtonSize.MEDIUM: return const EdgeInsets.symmetric(vertical: 8, horizontal: 10);
      case MyButtonSize.LARGE: return const EdgeInsets.symmetric(vertical: 12, horizontal: 14);
    }
  }

  double get fontSize {
    switch (widget.size) {
      case MyButtonSize.SMALLEST: return 10;
      case MyButtonSize.SMALLER: return 12;
      case MyButtonSize.SMALL: return 14;
      case MyButtonSize.MEDIUM: return 16;
      case MyButtonSize.LARGE: return 18;
    }
  }


  @override
  void initState() {
    _val = widget.value;
    super.initState();
  }

  @override
  void didUpdateWidget(MyInputSelect oldWidget) {
    if (widget.value != oldWidget.value) _val = widget.value;
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(APP_UI_BORDER_RADIUS),),
          clipBehavior: Clip.antiAlias,
          margin: widget.margin ?? const EdgeInsets.only(bottom: 8),
          elevation: 0,
          color: widget.color ?? Colors.white,
          child: Padding(
            padding: padding,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const SizedBox(width: 4,),
                widget.icon == null ? const SizedBox() : Padding(
                  padding: const EdgeInsets.only(right: 14.0),
                  child: Icon(widget.icon, size: 19.5, color: Colors.grey,),
                ),
                DropdownButtonHideUnderline(
                  child: DropdownButton<MenuModel>(
                    isDense: true,
                    underline: null,
                    value: widget.value ?? _val,
                    hint: Text(widget.placeholder ?? "Pilih satu"),
                    style: TextStyle(
                      fontFamily: APP_UI_FONT_MAIN,
                      fontSize: fontSize,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                      // color: Theme.of(context).textTheme.bodyText1!.color
                    ),
                    onChanged: (MenuModel? val) {
                      setState(() { _val = val; });
                      widget.onSelect(val);
                    },
                    items: widget.listMenu.map<DropdownMenuItem<MenuModel>>((MenuModel val) {
                      return DropdownMenuItem<MenuModel>(
                        value: val,
                        child: Text(val.label),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
        widget.error.isEmpty ? const SizedBox() : MyInputError(widget.error)
      ],
    );
  }
}

class MyToggleButton extends StatelessWidget {
  const MyToggleButton({ Key? key, required this.options, required this.onSelect, required this.selected }) : super(key: key);
  final List<MenuModel> options;
  final Function(int) onSelect;
  final MenuModel selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(APP_UI_BORDER_RADIUS),
        border: Border.all(
          color: APP_UI_BORDER_COLOR,
        ),
      ),
      child: LayoutBuilder(builder: (context, constraints) {
        return ToggleButtons(
          selectedColor: APP_UI_COLOR[800],
          fillColor: APP_UI_COLOR_MAIN.withOpacity(0.2),
          splashColor: APP_UI_COLOR[300]!.withOpacity(0.3),
          renderBorder: false,
          constraints: BoxConstraints.expand(width: constraints.maxWidth / options.length),
          borderRadius: BorderRadius.circular(APP_UI_BORDER_RADIUS),
          children: options.map<Widget>((item) {
            return Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  item.icon == null ? const SizedBox() : Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Icon(item.icon, size: 20,),
                  ),
                  Text(item.label, style: const TextStyle(fontSize: 16),),
                ],
              ),
            );
          }).toList(),
          isSelected: options.map((t) => t == selected).toList(),
          onPressed: onSelect,
        );
      }),
    );
  }
}

class MyAvatar extends StatelessWidget {
  const MyAvatar(this.image, {
    Key? key,
    this.heroTag,
    this.onPressed,
    this.onTapEdit,
    this.strokeWidth = 4,
    this.elevation = 1,
    this.size = 50.0,
    this.cached = false,
  }) : super(key: key);
  final dynamic image;
  final String? heroTag;
  final VoidCallback? onPressed;
  final VoidCallback? onTapEdit;
  final double strokeWidth;
  final double elevation;
  final double size;
  final bool cached;

  @override
  Widget build(BuildContext context) {

    Widget imageWidget;
    if (image is Widget) {
      imageWidget = image;
    } else if (cached && image is String) {
      final fallbackImage = Image.asset(DEFAULT_USER_PIC_ASSET, width: size, height: size, fit: BoxFit.cover);
      return image == null ? fallbackImage : CachedNetworkImage(
        imageUrl: Uri.encodeFull(image!),
        placeholder: (context, url) => SizedBox(width: size, height: size, child: const Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: APP_UI_COLOR_MAIN))),
        errorWidget: (context, url, error) => fallbackImage,
        width: size, height: size,
        fit: BoxFit.cover,
      );
    } else {
      imageWidget = Image(
        image: a.imageProvider(image, fallbackAsset: DEFAULT_USER_PIC_ASSET),
        width: size,
        height: size,
        fit: BoxFit.cover
      );
    }

    final clipWidget = ClipOval(
      child: InkWell(
        onTap: onPressed ?? () => Navigator.push(context, MaterialPageRoute(builder: (context) => ImageViewer(image))),
        child: imageWidget,
      )
    );

    final cardWidget = Card(
      elevation: elevation,
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: const CircleBorder(),
      child: Padding(
        padding: EdgeInsets.all(strokeWidth),
        child: heroTag == null ? clipWidget : Hero(
          tag: heroTag!,
          child: clipWidget,
        ),
      ),
    );

    return onTapEdit == null ? cardWidget : Stack(
      alignment: Alignment.bottomRight,
      children: [
        cardWidget,
        IconButton(icon: const Icon(Icons.add_a_photo), onPressed: onTapEdit,)
      ],
    );
  }
}

class MyMiniLoader extends StatelessWidget {
  const MyMiniLoader({Key? key, this.size = 40.0}) : super(key: key);
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: size, height: size, child: const Card(
      shape: CircleBorder(),
      child: Padding(
        padding: EdgeInsets.all(4),
        child: CircularProgressIndicator(strokeWidth: 2, color: APP_UI_COLOR_MAIN,),
      ),
    ),);
  }
}

class MyLoader extends StatelessWidget {
  const MyLoader({ Key? key, this.isLoading = true, this.message, this.progress }) : super(key: key);
  final bool isLoading;
  final String? message;
  final double? progress;

  @override
  Widget build(BuildContext context) {
    String caption = "";

    if (message != null && message!.isNotEmpty) caption += "$message ...";
    if (progress != null && progress! > 0) caption += f!.formatPercentage(progress!, 1);

    return IgnorePointer(
      ignoring: !isLoading,
      child: AnimatedOpacity(
        opacity: isLoading ? 1 : 0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          width: double.infinity,
          color: h!.backgroundColor(),
          child: isLoading ? Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(
                width: 60,
                height: 60,
                child: CircularProgressIndicator(strokeWidth: 4, color: APP_UI_COLOR_MAIN,)
              ),
              caption.isEmpty ? const SizedBox() : Padding(
                padding: const EdgeInsets.only(top: 20.0),
                child: Text(caption, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
              ),
            ],
          ) : const SizedBox(),
        ),
      ),
    );
  }
}

class MyPlaceholder extends StatelessWidget {
  const MyPlaceholder({ required this.content, this.onRetry, this.retryLabel, Key? key }) : super(key: key);
  final ContentModel content;
  final VoidCallback? onRetry;
  final String? retryLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset(content.image ?? 'assets/images/onboarding/2.png', width: MediaQuery.of(context).size.width * .69),
        const SizedBox(height: 30,),
        Text(content.title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600),),
        const SizedBox(height: 12,),
        Text(content.description!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, color: Colors.grey,),),
        onRetry == null ? const SizedBox() : Padding(
          padding: const EdgeInsets.only(top: 30.0),
          child: MyButton(retryLabel ?? tr('action_retry'), onPressed: onRetry),
        ),
      ]
    );
  }
}

class MyMenuList extends StatelessWidget {
  const MyMenuList({
    Key? key,
    this.menuPaddingVertical = 16,
    this.menuPaddingHorizontal = 16,
    this.isFirst = false,
    this.isLast = false,
    this.isActive = false,
    this.isLocked = false,
    this.separatorColor,
    required this.menu,
  }): super(key: key);

  final double menuPaddingVertical;
  final double menuPaddingHorizontal;
  final bool isFirst;
  final bool isLast;
  final bool isActive;
  final bool isLocked;
  final Color? separatorColor;
  final MenuModel menu;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isActive ? APP_UI_COLOR_MAIN.withOpacity(0.3) : Colors.transparent,
        border: Border(
          bottom: isLast ? BorderSide.none : BorderSide(color: separatorColor ?? APP_UI_COLOR_LIGHT, width: 1.0,)
        )
      ),
      width: double.infinity,
      child: InkWell(onTap: isLocked ? null : menu.onPressed, child: Padding(
        padding: EdgeInsets.symmetric(vertical: menuPaddingVertical, horizontal: menuPaddingHorizontal),
        child: Row(children: <Widget>[
          Icon(menu.icon, color: isLocked ? Colors.grey : Colors.blueGrey, size: 20,),
          const SizedBox(width: 8,),
          Expanded(child: Text(menu.label, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: isLocked ? Colors.grey : Colors.grey[800]),),),
          isLocked ? const Icon(Icons.lock, color: APP_UI_COLOR_MAIN, size: 20,) : const SizedBox(),
        ],),
      )),
    );
  }
}

class MyTooltip extends StatelessWidget {
  const MyTooltip({Key? key, required this.label, this.color = Colors.red}) : super(key: key);
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: ShapeDecoration(
        color: color,
        shape: const TooltipShapeBorder(arrowArc: 0.5),
        shadows: const [BoxShadow(color: Colors.black26, blurRadius: 4.0, offset: Offset(2, 2))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(label, style: const TextStyle(color: Colors.white)),
      ),
    );
  }
}

class MyFooter extends StatelessWidget {
  const MyFooter({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.center, children: <Widget>[
      Html(
        data: context.locale.languageCode == "id"
          ? 'Menggunakan aplikasi ini berarti menyetujui <a href="$APP_URL_TERMS"><strong>Syarat & Aturan</strong></a> dan <a href="$APP_URL_PRIVACY"><strong>Kebijakan Privasi</strong></a>.'
          : 'Using this application means agreeing to the <a href="$APP_URL_TERMS"><strong>Terms of Use</strong></a> and <a href="$APP_URL_PRIVACY"><strong>Privacy Policy</strong></a>.',
        style: {
          "body": Style(
            margin: EdgeInsets.zero,
            fontSize: const FontSize(13.0),
            textAlign: TextAlign.center,
            color: Colors.grey[700],
          ),
          "a": Style(
            fontWeight: FontWeight.w500,
            color: APP_UI_COLOR_MAIN,
          ),
        },
      ),
      Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.only(top: 12.0),
        child: Text("Hak cipta ©${DateTime.now().year} $APP_COPYRIGHT", textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
      ),
    ],);
  }
}

class MyInputError extends StatefulWidget {
  const MyInputError(this.error, {Key? key}) : super(key: key);
  final String error;

  @override
  _MyInputErrorState createState() => _MyInputErrorState();
}

class _MyInputErrorState extends State<MyInputError> with SingleTickerProviderStateMixin {
  AnimationController? _animationController;
  Animation<double>? _animation1;

  @override
  void initState() {
    _animationController = AnimationController(duration: const Duration(milliseconds: 100), vsync: this);
    _animation1 = Tween(begin: -10.0, end: 0.0).animate(CurvedAnimation(
      parent: _animationController!,
      curve: Curves.easeOut
    ));
    super.initState();
    WidgetsBinding.instance?.addPostFrameCallback((_) {
      _animationController?.forward();
    });
  }

  @override
  void dispose() {
    _animationController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 5),
      child: AnimatedBuilder(
        animation: _animationController!,
        builder: (BuildContext context, Widget? child) {
          return Transform.translate(
            offset: Offset(0.0, _animation1!.value),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
              decoration: BoxDecoration(
                color: Colors.red[400],
                borderRadius: BorderRadius.circular(APP_UI_BORDER_RADIUS)
              ),
              child: Row(
                children: <Widget>[
                  const Icon(LineIcons.exclamationCircle, color: Colors.white),
                  const SizedBox(width: 5,),
                  Expanded(child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Text(widget.error, style: const TextStyle(fontSize: 13, color: Colors.white)),
                  )),
                ],
              ),
            ),
          );
        }
      ),
    );
  }
}

class MyStepIndicator extends StatelessWidget {
  const MyStepIndicator({required this.count, required this.step, this.dotSize = 30.0, this.color, this.activeColor, Key? key }) : super(key: key);
  final int count;
  final int step;
  final double dotSize;
  final Color? color;
  final Color? activeColor;

  @override
  Widget build(BuildContext context) {
    final secondaryColor = color ?? APP_UI_COLOR[300]!;
    final primaryColor = activeColor ?? APP_UI_COLOR_MAIN;
    return Stack(
      alignment: Alignment.center,
      children: [
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            return SizedBox(
              child: Divider(color: secondaryColor, thickness: 2,),
              width: constraints.maxWidth - dotSize,
            );
          },
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (int i = 0; i < count; i++) Transform.scale(
              scale: i == step ? 1.8 : (i < step ? 1.0 : 0.8),
              child: Stack(
                children: [
                  Icon(Icons.circle, size: dotSize, color: Colors.white),
                  Icon(i < step ? Icons.check_circle : Icons.circle, size: dotSize, color: i < step ? primaryColor : secondaryColor),
                ],
              ),
            )
          ],
        ),
      ],
    );
  }
}

class MyCurrencyInputFormatter extends TextInputFormatter {
  MyCurrencyInputFormatter(this.context);
  final BuildContext context;

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.selection.baseOffset == 0) return newValue;
    double value = double.parse(newValue.text);
    String newText = NumberFormat("###,###.###", context.locale.toString()).format(value);
    return newValue.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length)
    );
  }
}

class MyFabCircular extends StatelessWidget {
  const MyFabCircular(this.icon, this.listActions, this.onAction, {Key? key, this.getOffset, this.getSize}) : super(key: key);
  final IconData icon;
  final List<MenuModel> listActions;
  final void Function(String) onAction;
  final Offset Function(int)? getOffset;
  final double Function(int)? getSize;

  @override
  Widget build(BuildContext context) {
    return FabCircularMenu(
      fabOpenIcon: Icon(icon, color: Colors.white,),
      fabCloseIcon: const Icon(Icons.close, color: Colors.white,),
      fabOpenColor: Colors.teal[300],
      fabCloseColor: APP_UI_COLOR_MAIN,
      ringColor: APP_UI_COLOR_MAIN.withOpacity(.8),
      ringWidth: 120,
      ringDiameter: 300,
      children: listActions.asMap().map((i, action) {
        return MapEntry(i, Transform.translate(
          offset: getOffset == null ? const Offset(0, 0) : getOffset!(i),
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: <Widget>[
              Material(
                shape: const CircleBorder(),
                color: Colors.transparent,
                clipBehavior: Clip.antiAlias,
                child: IconButton(
                  splashColor: action.color,
                  padding: const EdgeInsets.only(left: 20, right: 20, bottom: 28, top: 12),
                  icon: Icon(action.icon),
                  iconSize: getSize == null ? 24.0 : getSize!(i),
                  color: Colors.white,
                  tooltip: action.label,
                  onPressed: () {
                    onAction(action.value);
                  }
                ),
              ),
              IgnorePointer(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Text(action.label, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 12),),
                ),
              )
            ],
          ),
        ));
      }).values.toList(),
    );
  }
}

class MySearchBar extends StatefulWidget {
  const MySearchBar({
    Key? key,
    this.tool,
    this.height,
    this.backgroundColor,
    this.actionColor,
    this.searchController,
    this.searchFocusNode,
    this.searchPlaceholder,
    this.dataType,
    this.filterValues = const {},
    this.onFilter,
  }) : super(key: key);
  
  final TextEditingController? searchController;
  final FocusNode? searchFocusNode;
  final String? searchPlaceholder;
  final Widget? tool;
  final double? height;
  final Color? backgroundColor;
  final Color? actionColor;
  final String? dataType;
  final Map<String, dynamic> filterValues;
  final void Function(Map<String, dynamic>)? onFilter;

  @override
  _MySearchBarState createState() => _MySearchBarState();
}

class _MySearchBarState extends State<MySearchBar> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height ?? (APP_UI_INPUT_HEIGHT + 20),
      child: Material(
        color: widget.backgroundColor ?? APP_UI_COLOR_LIGHT,
        elevation: 0,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 15, top: 10),
                child: MyInputField(
                  // color: h!.backgroundColor(Colors.white),
                  label: widget.searchPlaceholder ?? tr("placeholder.search"),
                  key: ValueKey(widget.searchPlaceholder),
                  size: MyButtonSize.SMALL,
                  isClearable: true,
                  showLabel: false,
                  icon: LineIcons.search,
                  inputType: MyInputType.SEARCH,
                  controller: widget.searchController,
                  focusNode: widget.searchFocusNode,
                ),
              ),
            ),
            widget.onFilter == null ? const SizedBox() : Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.sort),
                color: widget.actionColor ?? Colors.grey[850]!,
                tooltip: tr('action_filter'),
                onPressed: () async {
                  final filter = await h!.showDialog(
                    MySearchFilter(
                      dataType: widget.dataType,
                      initialValues: widget.filterValues,
                    ),
                    showCloseButton: false
                  );
                  if (filter != null) widget.onFilter!(filter);
                },
              ),
            ),
            widget.tool ?? const SizedBox(),
            const SizedBox(width: 8,),
          ],
        ),
      ),
    );
  }
}

class MySearchFilter extends StatefulWidget {
  const MySearchFilter({Key? key, this.dataType, this.initialValues = const {}}) : super(key: key);
  final String? dataType;
  final Map<String, dynamic> initialValues;

  @override
  _MySearchFilterState createState() => _MySearchFilterState();
}

class _MySearchFilterState extends State<MySearchFilter> {
  late bool _isCanDeliver;

  @override
  void initState() {
    _isCanDeliver = widget.initialValues['isCanDeliver'] ?? false;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        widget.dataType == 'listing' ? Row(
          children: <Widget>[
            const Expanded(child: Text("Melayani antar")),
            Switch(
              activeTrackColor: APP_UI_COLOR_MAIN,
              activeColor: APP_UI_COLOR_LIGHT,
              value: _isCanDeliver,
              onChanged: (value) {
                setState(() {
                  _isCanDeliver = value;
                });
              },
            ),
          ],
        ) : const SizedBox(),
        const Divider(),
        MyButton(
          tr("action_apply"),
          size: MyButtonSize.SMALL,
          icon: Icons.check,
          onPressed: () => Navigator.of(context).pop({
            'isCanDeliver': _isCanDeliver,
          }),
        ),
      ],
    );
  }
}

class MySection extends StatelessWidget {
  const MySection({Key? key, required this.children, this.title, this.titleSpacing, this.tool}) : super(key: key);
  final List<Widget> children;
  final String? title;
  final double? titleSpacing;
  final Widget? tool;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Container(
        width: double.infinity,
        color: Colors.white,
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          title == null && tool == null ? const SizedBox() : Padding(
            padding: EdgeInsets.only(bottom: titleSpacing ?? 12.0),
            child: Row(children: <Widget>[
              Expanded(child: title == null ? const SizedBox() : Text(title!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),),),
              tool == null ? const SizedBox() : Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: tool,
              ),
            ],),
          ),
          ...children
        ],),
      ),
    );
  }
}

class MyImageUpload extends StatelessWidget {
  const MyImageUpload({
    this.imageList = const [],
    this.imageEditList = const [],
    this.placeholder,
    required this.onDelete,
    required this.maximum,
    Key? key
  }) : super(key: key);
  final List<AssetEntity> imageList;
  final List<String> imageEditList;
  final String? placeholder;
  final void Function(dynamic) onDelete;
  final int maximum;

  @override
  Widget build(BuildContext context) {

    List<Widget> _makeList(List images) {
      final deleteButton = Container(
        child: const Icon(Icons.close_rounded, color: Colors.black, size: 22,),
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white
        ),
      );
      final galleryItems = images.map((image) => ImageGalleryItem(src: image)).toList();
      return images.asMap().map((index, asset) {
        return MapEntry(index, Stack(
          alignment: Alignment.topRight,
          children: <Widget>[
            GestureDetector(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(
                  builder: (context) => ImageGalleryViewer(
                    galleryItems: galleryItems,
                    backgroundDecoration: const BoxDecoration(color: Colors.black,),
                    initialIndex: index,
                    scrollDirection: Axis.horizontal,
                  ),
                ));
              },
              child: asset is AssetEntity
                ? Image(
                  image: AssetEntityImageProvider(asset, isOriginal: false),
                  width: 300,
                  height: 300,
                  fit: BoxFit.cover,
                )
                : Image.network(asset,
                  width: 300,
                  height: 300,
                  fit: BoxFit.cover,
                )
            ),
            GestureDetector(
              onTap: () {
                onDelete(asset);
              },
              child: deleteButton,
            ),
          ]
        ));
      }).values.toList();
    }

    var listImages = _makeList([...imageEditList, ...imageList]);
    var gridCount = 3;
    var gridHeight = (MediaQuery.of(context).size.width - 80) / gridCount;
    var totalHeight = gridHeight * (listImages.length / gridCount).ceil();

    return listImages.isEmpty ? Text(
      placeholder ?? "Silakan unggah maksimal $maximum foto.",
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: Colors.grey,
      )
    ) : SizedBox(
      height: totalHeight,
      child: GridView.count(
        mainAxisSpacing: 2.0,
        crossAxisSpacing: 2.0,
        // physics: listImages.length > gridCount ? AlwaysScrollableScrollPhysics() : NeverScrollableScrollPhysics(),
        physics: const NeverScrollableScrollPhysics(),
        // scrollDirection: Axis.horizontal,
        crossAxisCount: gridCount,
        children: listImages,
      ),
    );
  }
}

class MyWizard extends StatelessWidget {
  const MyWizard({
    required this.body,
    required this.steps,
    required this.step,
    this.scrollController,
    Key? key
  }) : super(key: key);
  final List<Widget> body;
  final List<ContentModel> steps;
  final int step;
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    final stepTotal = steps.length;
    final stepIndicator = MyStepIndicator(count: stepTotal, step: step);
    final stepContent = steps[step];

    return NestedScrollView(
      controller: scrollController,
      headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
        return <Widget>[
          SliverAppBar(
            leading: Container(),
            actions: <Widget>[
              Container(),
            ],
            automaticallyImplyLeading: false,
            backgroundColor: APP_UI_COLOR[100]!,
            elevation: 0,
            expandedHeight: 160,
            floating: false,
            pinned: true,
            flexibleSpace: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final height = constraints.biggest.height;
                return FlexibleSpaceBar(
                  centerTitle: true,
                  title: AnimatedOpacity(
                    duration: const Duration(milliseconds: 300),
                    opacity: height > 60 ? 0.0 : 1.0,
                    child: Opacity(
                      opacity: height > 75 ? 0.0 : 1.0,
                      child: Row(
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          const SizedBox(width: 30,),
                          Text(stepContent.title, style: TextStyle(color: Colors.grey[800], fontSize: 20, fontWeight: FontWeight.w600)),
                          const Spacer(),
                          SizedBox(
                            width: MediaQuery.of(context).size.width * 0.4,
                            child: MyStepIndicator(count: stepTotal, step: step, dotSize: 25),
                          ),
                          const SizedBox(width: 30,),
                        ],
                      ),
                    ),
                  ),
                  background: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20,),
                        stepIndicator,
                        const SizedBox(height: 20,),
                        Text(stepContent.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 10,),
                        Text(stepContent.description!, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w400)),
                      ],
                    ),
                  ),
                );
              }
            ),
          ),
        ];
      },
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
        child: body[step],
      ),
    );
  }
}

class MyProfileCard extends StatelessWidget {
  const MyProfileCard({ this.avatarSize, this.backgroundColor, Key? key }) : super(key: key);
  final double? avatarSize;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor ?? h!.backgroundColor(),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          MyAvatar(
            profile!.image,
            size: avatarSize ?? 80,
            strokeWidth: 4,
            elevation: 0,
          ),
          const SizedBox(width: 12,),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(profile!.name, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: APP_UI_COLOR[600]),),
            const SizedBox(height: 4,),
            Text("No. SIM: ${profile!.email}", style: TextStyle(fontSize: 14, color: h!.textColor(),),),
          ],))
        ],
      ),
    );
  }
}