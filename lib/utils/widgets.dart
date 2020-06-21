import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_html/style.dart';
import 'package:flutter_rounded_date_picker/rounded_picker.dart';
import 'package:intl/intl.dart';
import 'package:line_icons/line_icons.dart';
import '../extensions/string.dart';
import '../plugins/datetime_picker_formfield.dart';
import 'api.dart';
import 'constants.dart';
import 'helpers.dart';
import 'styles.dart' as style;

enum UiInputType {
  TEXT,
  NAME,
  PASSWORD,
  DATE,
  DATE_OF_BIRTH,
  CURRENCY,
  PHONE,
  EMAIL,
  PIN,
  NOTE,
  SEARCH,
  TAG,
}

class UiInput extends StatefulWidget {
  UiInput(this.label, {
    Key key,
    this.icon,
    this.maxLength,
    this.textStyle,
    this.textAlign = TextAlign.start,
    this.showLabel = true,
    this.showHint = true,
    this.labelStyle,
    this.info,
    this.prefix,
    this.height = THEME_INPUT_HEIGHT,
    this.contentPadding,
    this.color,
    this.borderColor,
    this.borderWidth = 1.0,
    this.type = UiInputType.TEXT,
    this.caps,
    this.controller,
    this.focusNode,
    this.autoFocus = false,
    this.initialValue,
    this.isRequired = false,
    this.readOnly = false,
    this.onSubmit,
    this.onTap,
    this.cancelAction,
    this.onChanged,
    this.margin,
    this.borderRadius,
    this.dateFormat = "dd/MM/yyyy",
    this.isClearable = true,
    this.elevation = THEME_ELEVATION_INPUT,
    this.error,
    // this.onValidate,
  }) : super(key: key);
  final IconData icon;
  final String label;
  final int maxLength;
  final TextStyle textStyle;
  final TextAlign textAlign;
  final String info;
  final String prefix;
  final bool showLabel;
  final bool showHint;
  final TextStyle labelStyle;
  final double height;
  final EdgeInsetsGeometry contentPadding;
  final Color color;
  final Color borderColor;
  final double borderWidth;
  final UiInputType type;
  final TextCapitalization caps;
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool autoFocus;
  final dynamic initialValue;
  final bool isRequired;
  final bool isClearable;
  final bool readOnly;
  final void Function(String) onSubmit;
  final void Function() onTap;
  final void Function() cancelAction;
  final void Function(dynamic) onChanged;
  final EdgeInsets margin;
  final BorderRadius borderRadius;
  final double elevation;
  final String dateFormat;
  final String error;
  // final void Function(String) onValidate;

  @override
  _UiInputState createState() => _UiInputState();
}

class _UiInputState extends State<UiInput> {
  EdgeInsetsGeometry _contentPadding;
  TextStyle _prefixStyle;
  TextStyle _textStyle;
  TextCapitalization _textCapitalization;
  String Function(String) _validator;
  String Function(DateTime) _validatorDate;
  Widget _input;
  double _fontSize;
  FontWeight _fontWeight;
  Color _fontColor;
  String _hintText;
  TextStyle _hintStyle;
  double _iconSize;
  Widget _icon;
  bool _viewText;
  int _maxLength;
  VoidCallback _onTap;

  @override
  void initState() {
    super.initState();
    _contentPadding = widget.contentPadding ?? EdgeInsets.zero;
    _textStyle = widget.textStyle ?? style.textInput;
    _fontSize = _textStyle.fontSize;
    _fontWeight = _textStyle.fontWeight;
    _fontColor = _textStyle.color;
    _viewText = widget.type != UiInputType.PASSWORD && widget.type != UiInputType.PIN;
    _hintText = widget.showHint ? widget.label : '';
    _hintStyle = TextStyle(fontSize: _fontSize, color: style.textHint.color, fontWeight: FontWeight.normal);
    _iconSize = _fontSize * 1.3;
    _maxLength = widget.maxLength;
    _textCapitalization = widget.caps;
    _onTap = widget.onTap == null ? null : () {
      FocusScope.of(context).requestFocus(FocusNode());
      widget.onTap();
    };
    switch (widget.type) {
      case UiInputType.NAME:
        if (_textCapitalization == null) _textCapitalization = TextCapitalization.words;
        break;
      case UiInputType.CURRENCY:
        if (_maxLength == null || _maxLength > 15) _maxLength = 15;
        break;
      case UiInputType.TAG:
        if (_textCapitalization == null) _textCapitalization = TextCapitalization.words;
        if (_maxLength == null) _maxLength = 50;
        break;
      case UiInputType.NOTE:
        if (_textCapitalization == null) _textCapitalization = TextCapitalization.sentences;
        break;
      default:
        if (_textCapitalization == null) _textCapitalization = TextCapitalization.none;
    }
    _validatorDate = (val) {
      DateTime date = val;
      String result;
      switch (widget.type) {
        case UiInputType.DATE_OF_BIRTH:
          var now = DateTime.now();
          var min = now.subtract(Duration(days: SETUP_MAX_PERSON_AGE * 365));
          var max = now.subtract(Duration(days: SETUP_MIN_PERSON_AGE * 365));
          if (date.isBefore(min) || date.isAfter(max)) {
            result = "Tanggal lahir tidak valid";
          }
          break;
        default:
      }
      return result;
    };
    _validator = (val) {
      String value = val;
      String result;
      if (widget.isRequired && value.isEmpty) {
        result = "${widget.label ?? 'Kolom ini'} harus diisi";
      }
      if (widget.type == UiInputType.EMAIL && value.isNotEmpty && !value.isValidEmail) {
        result = "${widget.label ?? 'Alamat email'} tidak valid";
      }
      // widget.onValidate(result);
      return result;
      // return null;
    };
  }

  @override
  Widget build(BuildContext context) {
    _textStyle = TextStyle(color: widget.readOnly ? Colors.white : _fontColor, fontSize: _fontSize, fontWeight: _fontWeight);
    _prefixStyle = TextStyle(color: widget.readOnly ? Colors.white : _fontColor, fontSize: _fontSize, fontWeight: FontWeight.bold);
    _icon = widget.icon == null ? SizedBox() : Padding(padding: EdgeInsets.only(left: 20), child: Icon(widget.icon, size: _iconSize, color: widget.readOnly ? Colors.white70 : Colors.grey));
    switch (widget.type) {
      case UiInputType.TEXT:
      case UiInputType.NAME:
      case UiInputType.NOTE:
      case UiInputType.SEARCH:
      case UiInputType.EMAIL:
      case UiInputType.TAG:
        _input = Stack(alignment: Alignment.topRight, children: <Widget>[
          Padding(
            padding: EdgeInsets.only(right: widget.cancelAction == null ? 16.0 : 40.0),
            child: TextFormField(
              // initialValue: widget.initialValue,
              keyboardType: widget.type == UiInputType.EMAIL ? TextInputType.emailAddress : TextInputType.text,
              textCapitalization: _textCapitalization,
              style: _textStyle,
              textAlign: widget.textAlign,
              readOnly: widget.readOnly,
              decoration: InputDecoration(
                isDense: true,
                contentPadding: _contentPadding,
                hintStyle: _hintStyle,
                hintText: _hintText,
                icon: _icon,
                border: InputBorder.none
              ),
              textInputAction: TextInputAction.go,
              controller: widget.controller,
              focusNode: widget.focusNode,
              inputFormatters: _maxLength != null ? <TextInputFormatter>[
                LengthLimitingTextInputFormatter(_maxLength),
              ] : null,
              maxLines: widget.type == UiInputType.NOTE ? null : 1,
              enableInteractiveSelection: _onTap == null,
              onTap: _onTap,
              onFieldSubmitted: widget.onSubmit,
              // onChanged: widget.onChanged,
              onChanged: (val) {
                if (widget.controller != null) {
                  if (widget.type == UiInputType.TAG && val.contains(' ')) {
                    widget.controller.text = val.replaceAll(' ', '');
                  }
                }
                widget.onChanged(val);
              },
              validator: _validator,
            ),
          ),
          widget.cancelAction == null ? SizedBox() : IconButton(icon: Icon(LineIcons.close), iconSize: _iconSize, color: Colors.grey, onPressed: widget.cancelAction,),
        ],);
        break;
      case UiInputType.PHONE:
        _input = Padding(
          padding: EdgeInsets.only(right: 20.0),
          child: TextFormField(
            keyboardType: TextInputType.phone,
            maxLines: 1,
            style: _textStyle,
            readOnly: widget.readOnly,
            decoration: InputDecoration(
              contentPadding: _contentPadding,
              prefixStyle: _prefixStyle,
              prefix: Text(widget.prefix ?? "+62 ", style: _prefixStyle),
              hintStyle: _hintStyle,
              hintText: _hintText,
              icon: _icon,
              border: InputBorder.none,
              isDense: true,
            ),
            textInputAction: TextInputAction.go,
            controller: widget.controller,
            focusNode: widget.focusNode,
            //onSubmitted: widget.onSubmit,
            autofocus: widget.autoFocus,
            onChanged: (val) {
              if (widget.controller != null) {
                if (val[0] == '0') {
                  widget.controller.text = val.substring(1);
                }
              }
              widget.onChanged(val);
            },
            validator: _validator,
          ),
        );
        break;
      case UiInputType.CURRENCY:
        _input = Padding(
          padding: EdgeInsets.only(right: 20.0),
          child: TextFormField(
            initialValue: widget.initialValue,
            keyboardType: TextInputType.number,
            maxLines: 1,
            style: _textStyle,
            textAlign: widget.textAlign,
            readOnly: widget.readOnly,
            decoration: InputDecoration(
              contentPadding: _contentPadding,
              prefixStyle: _prefixStyle,
              prefix: Text(widget.prefix ?? "Rp ",
              style: _prefixStyle),
              hintStyle: _hintStyle,
              hintText: _hintText,
              icon: _icon,
              border: InputBorder.none,
              isDense: true,
            ),
            textInputAction: TextInputAction.go,
            controller: widget.controller,
            focusNode: widget.focusNode,
            enableInteractiveSelection: _onTap == null,
            onTap: _onTap,
            inputFormatters: <TextInputFormatter>[
              WhitelistingTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(_maxLength),
              CurrencyInputFormatter()
            ],
            onChanged: widget.onChanged,
            //onSubmitted: widget.onSubmit,
            validator: _validator,
          ),
        );
        break;
      case UiInputType.PASSWORD:
      case UiInputType.PIN:
        _input = Stack(children: <Widget>[
          Center(
            child: Padding(
              padding: EdgeInsets.only(right: 40.0),
              child: TextFormField(
                obscureText: !_viewText,
                enableInteractiveSelection: false,
                keyboardType: widget.type == UiInputType.PIN ? TextInputType.number : null,
                inputFormatters: widget.type == UiInputType.PIN ? <TextInputFormatter>[
                  LengthLimitingTextInputFormatter(_maxLength ?? 6),
                  WhitelistingTextInputFormatter.digitsOnly,
                ] : <TextInputFormatter>[
                  LengthLimitingTextInputFormatter(_maxLength ?? 32),
                ],
                maxLines: 1,
                style: _textStyle,
                decoration: InputDecoration(
                  contentPadding: _contentPadding,
                  hintStyle: _hintStyle,
                  hintText: _hintText,
                  icon: _icon,
                  border: InputBorder.none,
                  isDense: true,
                ),
                textInputAction: TextInputAction.go,
                controller: widget.controller,
                focusNode: widget.focusNode,
                validator: _validator,
              ),
            ),
          ),
          Align(
            alignment: Alignment.topRight,
            child: IconButton(icon: Icon(_viewText ? Icons.visibility_off : Icons.visibility), iconSize: _iconSize, color: Colors.grey, onPressed: () {
              setState(() { _viewText = !_viewText; });
            },),
          ),
        ],);
        break;
      case UiInputType.DATE:
      case UiInputType.DATE_OF_BIRTH:
        _input = DateTimeField(
          textAlign: widget.textAlign,
          readOnly: true,
          showCursor: false,
          format: DateFormat(widget.dateFormat, APP_LOCALE),
          initialValue: widget.initialValue == null ? null : (widget.initialValue is DateTime ? widget.initialValue : DateTime.parse(widget.initialValue.toString())),
          style: _textStyle,
          maxLines: 1,
          decoration: InputDecoration(
            contentPadding: _contentPadding,
            hintStyle: _hintStyle,
            hintText: _hintText,
            icon: _icon,
            border: InputBorder.none,
            isDense: true,
          ),
          resetIcon: widget.isClearable ? Icon(LineIcons.close, size: _fontSize,) : null,
          onShowPicker: (context, currentValue) {
            DateTime now = DateTime.now();
            DateTime min = DateTime(2020);
            DateTime max = now;
            if (widget.type == UiInputType.DATE_OF_BIRTH) {
              min = now.subtract(Duration(days: SETUP_MAX_PERSON_AGE * 365));
              max = now.subtract(Duration(days: SETUP_MIN_PERSON_AGE * 365));
            }
            return showRoundedDatePicker(
              context: context,
              initialDate: currentValue ?? max,
              firstDate: min,
              lastDate: max,
              borderRadius: THEME_BORDER_RADIUS,
              locale: Locale('id', 'ID'),
              initialDatePickerMode: widget.type == UiInputType.DATE_OF_BIRTH ? DatePickerMode.year : DatePickerMode.day,
              theme: Theme.of(context),
              customWeekDays: ["Min", "Sen", "Sel", "Rab", "Kam", "Jum", "Sab"],
              onTapDay: (dateTime, available) => available,
              styleDatePicker: h.datePickerStyle,
              styleYearPicker: h.yearPickerStyle
            );
          },
          onChanged: widget.onChanged,
          validator: _validatorDate,
        );
        break;
    }

    return Padding(
      padding: widget.margin ?? EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          widget.showLabel
            ? Padding(padding: EdgeInsets.only(bottom: 8.0), child: Text(widget.label + ((widget.info ?? "").isEmpty ? ":" : " (${widget.info}):"), style: widget.labelStyle ?? style.textLabel,),)
            : SizedBox(),
          IgnorePointer(
            ignoring: widget.readOnly,
            child: Card(
              color: (widget.color ?? Theme.of(context).cardColor).withOpacity(widget.readOnly ? 0.8 : 1),
              shape: RoundedRectangleBorder(borderRadius: widget.borderRadius ?? BorderRadius.circular(THEME_BORDER_RADIUS),),
              elevation: widget.elevation,
              clipBehavior: Clip.antiAlias,
              margin: EdgeInsets.zero,
              // TODO input note autosize height
              child: widget.height == null ? _input : SizedBox(height: widget.height, child: Padding(padding: EdgeInsets.symmetric(vertical: 15), child: _input,),),
            ),
          ),
          widget.error.isEmptyOrNull ? SizedBox() : ErrorText(widget.error)
        ],
      ),
    );
  }
}

class UiSelect extends StatefulWidget {
  UiSelect({Key key, this.icon, this.listMenu, this.initialValue, this.value, this.placeholder, this.fontSize, this.margin, this.onSelect, this.error = '', this.simple = false, this.isDense = false}) : super(key: key);
  final IconData icon;
  final List<dynamic> listMenu;
  final dynamic initialValue;
  final dynamic value;
  final String placeholder;
  final double fontSize;
  final EdgeInsetsGeometry margin;
  final void Function(dynamic) onSelect;
  final String error;
  final bool simple;
  final bool isDense;

  @override
  _UiSelectState createState() => _UiSelectState();
}

class _UiSelectState extends State<UiSelect> {
  var _val;

  @override
  void initState() {
    _val = widget.initialValue;
    super.initState();
  }

  @override
  void didUpdateWidget(UiSelect oldWidget) {
    _val = widget.initialValue;
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    Widget card = Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(THEME_BORDER_RADIUS),),
      elevation: 1.0,
      margin: widget.margin ?? EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: widget.isDense ? EdgeInsets.all(10) : EdgeInsets.symmetric(horizontal: 15, vertical: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SizedBox(width: 4,),
            widget.icon == null ? SizedBox() : Padding(
              padding: EdgeInsets.only(right: widget.isDense ? 12 : 15),
              child: Icon(widget.icon, size: 19.5, color: Colors.grey,),
            ),
            Theme(
              data: Theme.of(context),
              // data: Theme.of(context).copyWith(canvasColor: Colors.white,),
              child: DropdownButton<dynamic>(
                isDense: true,
                underline: SizedBox(),
                value: widget.value ?? _val,
                hint: Text(widget.placeholder),
                style: TextStyle(fontFamily: THEME_FONT_MAIN, fontSize: widget.fontSize ?? 16, color: Theme.of(context).textTheme.bodyText1.color),
                onChanged: (dynamic val) {
                  setState(() { _val = val; });
                  widget.onSelect(val);
                },
                items: widget.listMenu.map<DropdownMenuItem<dynamic>>((dynamic val) {
                  return DropdownMenuItem<dynamic>(
                    value: val,
                    child: Text(val.toString(), style: TextStyle(fontWeight: FontWeight.normal),),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
    return widget.simple ? card : Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        card,
        (widget.error ?? '').isEmpty ? SizedBox() : ErrorText(widget.error)
      ],
    );
  }
}

class CurrencyInputFormatter extends TextInputFormatter {
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.selection.baseOffset == 0) return newValue;
    double value = double.parse(newValue.text);
    String newText = NumberFormat("###,###.###", APP_LOCALE).format(value);
    return newValue.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length)
    );
  }
}

class ErrorText extends StatefulWidget {
  ErrorText(this.error, {Key key}) : super(key: key);
  final String error;

  @override
  _ErrorTextState createState() => _ErrorTextState();
}

class _ErrorTextState extends State<ErrorText> with SingleTickerProviderStateMixin {
  AnimationController _animationController;
  Animation _animation1;

  @override
  void initState() {
    _animationController = AnimationController(duration: Duration(milliseconds: 500), vsync: this);
    _animation1 = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack
    ));
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 5),
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (BuildContext context, Widget child) {
          return Transform.scale(
            scale: _animation1.value,
            child: Container(
              child: Row(
                children: <Widget>[
                  Icon(LineIcons.exclamation_circle, color: Colors.red),
                  SizedBox(width: 5,),
                  Text(widget.error, style: TextStyle(fontSize: 13, color: Colors.red)),
                ],
              ),
            ),
          );
        }
      ),
    );
  }
}

class UiLoader extends StatelessWidget {
  UiLoader({Key key, this.loaderColor = THEME_COLOR, this.textStyle, this.label = "Tunggu sebentar ..."}) : super(key: key);
  final Color loaderColor;
  final TextStyle textStyle;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        SizedBox(width: 50, height: 50, child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(loaderColor), strokeWidth: 5.0,)),
        SizedBox(height: 20,),
        Text(label, textAlign: TextAlign.center, style: textStyle ?? style.textMuted,)
      ],
    );
  }
}

class UiButton extends StatelessWidget {
  UiButton(this.label, {
    this.btnKey,
    this.color = THEME_COLOR,
    // this.borderColor,
    this.icon,
    this.iconSize,
    this.iconColor,
    this.iconPadding = 8.0,
    this.iconRight = false,
    this.onPressed,
    this.borderRadius,
    this.elevation = THEME_ELEVATION_BUTTON,
    this.textStyle,
    this.alignment,
    this.padding,
    this.width,
    this.height
  });
  final Color color;
  // final Color borderColor;
  final IconData icon;
  final String label;
  final TextStyle textStyle;
  final double iconSize;
  final Color iconColor;
  final double iconPadding;
  final bool iconRight;
  final BorderRadius borderRadius;
  final double elevation;
  final Key btnKey;
  final MainAxisAlignment alignment;
  final void Function() onPressed;
  final EdgeInsetsGeometry padding;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    var _textStyle = textStyle ?? style.textButton;
    // var _borderColor = borderColor ?? color;
    var _fontSize = _textStyle.fontSize;
    var _fontColor = _textStyle.color;
    var _fontWeight = _textStyle.fontWeight;
    var _icon = Icon(icon, color: iconColor ?? _fontColor, size: iconSize ?? (_fontSize * 1.2),);
    return SizedBox(
      width: width ?? double.infinity,
      height: height ?? style.heightButton,
      child: IgnorePointer(
        ignoring: onPressed == null,
        child: Opacity(
          opacity: onPressed == null ? 0.5 : 1,
          child: RaisedButton(
            padding: padding ?? Theme.of(context).buttonTheme.padding,
            key: btnKey,
            color: color,
            elevation: elevation,
            hoverElevation: elevation,
            focusElevation: elevation,
            highlightElevation: elevation,
            shape: RoundedRectangleBorder(borderRadius: borderRadius ?? BorderRadius.circular(THEME_BORDER_RADIUS)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: alignment ?? MainAxisAlignment.center,
              children: <Widget>[
                icon == null || iconRight ? SizedBox() : Padding(padding: EdgeInsets.only(right: iconPadding), child: _icon,),
                label == null ? SizedBox() : Text(label, style: TextStyle(color: _fontColor, fontWeight: _fontWeight, fontSize: _fontSize),),
                icon == null || !iconRight ? SizedBox() : Padding(padding: EdgeInsets.only(left: iconPadding), child: _icon,),
              ],
            ),
            onPressed: onPressed ?? () {},
          ),
        ),
      ),
    );
  }
}

class UiButtonIcon extends StatelessWidget {
  UiButtonIcon(this.icon, {Key key, this.iconSize = 25.0, this.size = THEME_INPUT_HEIGHT, this.radius, this.color, this.iconColor, this.elevation = THEME_ELEVATION_BUTTON, this.onPressed}) : super(key: key);
  final IconData icon;
  final double size;
  final double iconSize;
  final double radius;
  final Color color;
  final Color iconColor;
  final double elevation;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return UiButton("", width: size, height: size, elevation: elevation, borderRadius: BorderRadius.circular(radius ?? (size / 2)), padding: EdgeInsets.zero, icon: icon, iconPadding: 0, iconSize: iconSize, iconColor: iconColor, color: color, onPressed: onPressed,);
  }
}

class UiMapMarker extends StatefulWidget {
  UiMapMarker({Key key, this.size = 50.0, this.onTap}) : super(key: key);
  final double size;
  final VoidCallback onTap;

  @override
  _UiMapMarkerState createState() => _UiMapMarkerState();
}

class _UiMapMarkerState extends State<UiMapMarker> with SingleTickerProviderStateMixin {
  AnimationController _animationController;
  Animation _animation;

  @override
  void initState() {
    _animationController = AnimationController(duration: Duration(milliseconds: 1500), vsync: this)..repeat(reverse: true);
    _animation = Tween(begin: 1.0, end: 0.0).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.bounceOut,
    ));
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(Duration(milliseconds: 1000), () {
        if (mounted) _animationController.forward();
      });
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, widget.size * -0.5 + -100.0 * _animation.value),
        child: GestureDetector(
          onTap: widget.onTap,
          child: Image.asset("images/marker.png", width: widget.size, height: widget.size,)
        ),
      ),
    );
  }
}

class UiMenuList extends StatelessWidget {
  UiMenuList({Key key, this.menuPaddingVertical = 14, this.menuPaddingHorizontal = 16, this.isFirst = false, this.isLast = false, this.isLocked = false, this.icon, @required this.teks, @required this.value, @required this.aksi}): super(key: key);
  final double menuPaddingVertical;
  final double menuPaddingHorizontal;
  final bool isFirst;
  final bool isLast;
  final bool isLocked;
  final IconData icon;
  final String teks;
  final dynamic value;
  final void Function(dynamic) aksi;

  @override
  Widget build(BuildContext context) {
    var _textTheme = Theme.of(context).textTheme;
    return Container(
      decoration: isLast ? null : BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey[300], width: 1.0,))),
      width: double.infinity,
      child: InkWell(onTap: isLocked || aksi == null ? null : () => aksi(value), child: Padding(
        padding: EdgeInsets.symmetric(vertical: menuPaddingVertical, horizontal: menuPaddingHorizontal),
        child: Row(children: <Widget>[
          Icon(icon, color: isLocked || aksi == null ? Colors.grey : Colors.blueGrey, size: 22,),
          SizedBox(width: 8,),
          Expanded(child: Text(teks, style: TextStyle(fontSize: 15, color: isLocked || aksi == null ? Colors.grey : _textTheme.bodyText1.color),),),
          isLocked ? Icon(LineIcons.lock, color: THEME_COLOR, size: 17,) : SizedBox(),
        ],),
      )),
    );
  }
}

class UiAvatar extends StatelessWidget {
  UiAvatar(this.pic, {Key key, this.size = 100.0, this.heroTag, this.onPressed, this.strokeWidth = 3}) : super(key: key);
  final String pic;
  final double size;
  final String heroTag;
  final void Function() onPressed;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    final _imageDefault = Image.asset(DEFAULT_USER_IMAGE, width: size, height: size, fit: BoxFit.cover);
    final _imageWidget = pic == null ? _imageDefault : CachedNetworkImage(
      imageUrl: Uri.encodeFull(pic),
      placeholder: (context, url) => SizedBox(width: size, height: size, child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator())),
      errorWidget: (context, url, error) => _imageDefault,
      width: size, height: size,
      fit: BoxFit.cover,
    );
    final _image = ClipOval(child: InkWell(onTap: onPressed, child: _imageWidget));
    return Card(
      elevation: 1,
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: CircleBorder(),
      child: Padding(
        padding: EdgeInsets.all(strokeWidth),
        child: heroTag == null ? _image : Hero(
          tag: heroTag,
          child: _image,
        ),
      ),
    );
  }
}

class Copyright extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
      Text("Hak cipta ©${DateTime.now().year} $APP_COPYRIGHT", style: style.textWhiteS),
      SizedBox(height: 12,),
      Html(
        data: 'Menggunakan aplikasi ini berarti menyetujui <a href="${APP_TERMS_URL}">Syarat Penggunaan</a> & <a href="${APP_PRIVACY_URL}">Kebijakan Privasi</a>.',
        style: {
          "body": Style(
            margin: EdgeInsets.zero,
            fontSize: FontSize(13.0),
            textAlign: TextAlign.start,
            color: Colors.white70,
          ),
          "a": Style(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        },
        onLinkTap: (url) async {
          print("OPENING URL: $url");
          print("OPENING PAGE: ${url.replaceAll(APP_HOST, '')}");
          h.loadAlert();
          Map pageApi = await api('page', type: url.replaceAll(APP_HOST, ''));
          Map pageRes = pageApi['result'];
          h.closeDialog();
          h.showAlert(title: pageRes['JUDUL'], body: h.html(pageRes['ISI'], textStyle: TextStyle(fontSize: 14)));
        },
      )
    ],);
  }
}

class UiCaption extends StatelessWidget {
  UiCaption(this.title, {Key key, this.no, this.total, this.icon, this.stepAction, this.tool}) : super(key: key);
  final int no;
  final int total;
  final Widget icon;
  final String title;
  final void Function(int) stepAction;
  final Widget tool;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: <Widget>[
        icon ?? SizedBox(),
        Text(title, style: TextStyle(fontSize: 15.0, fontWeight: FontWeight.bold, color: Colors.white),),
        Spacer(),
        no == null ? SizedBox() : Padding(
          padding: EdgeInsets.only(right: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(total, (index) {
              double _scale = no == index + 1 ? 1.1 : 0.9;
              Color _backgroundColor = no == index + 1 ? Colors.white : Colors.white30;
              Color _textColor = no == index + 1 ? THEME_COLOR : THEME_COLOR;
              return Transform.scale(
                scale: _scale,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: CircleAvatar(backgroundColor: _backgroundColor, child: Text("${index + 1}", style: TextStyle(fontWeight: FontWeight.bold, color: _textColor),),),
                  onPressed: stepAction == null ? null : () => stepAction(index),
                ),
              );
            }),
          ),
        ),
        tool ?? SizedBox(),
      ],),
    );
  }
}

class UiIconButton extends StatelessWidget {
  UiIconButton(this.icon, {Key key, this.color, this.size, this.onPressed}) : super(key: key);
  final Widget icon;
  final double size;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: FlatButton(
        splashColor: Colors.grey.withOpacity(0.2),
        highlightColor: Colors.grey.withOpacity(0.2),
        visualDensity: VisualDensity.compact,
        child: icon,
        color: color ?? Colors.transparent,
        shape: CircleBorder(),
        padding: EdgeInsets.zero,
        onPressed: onPressed,
      ),
    );
  }
}