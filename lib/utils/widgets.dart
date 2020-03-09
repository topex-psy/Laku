import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_rounded_date_picker/rounded_picker.dart';
import 'package:datetime_picker_formfield/datetime_picker_formfield.dart';
import 'package:intl/intl.dart';
import 'package:line_icons/line_icons.dart';
import 'constants.dart';
import 'helpers.dart';
import 'styles.dart' as style;

enum UiInputType {
  TEXT,
  PASSWORD,
  DATE,
  DATE_OF_BIRTH,
  CURRENCY,
  PHONE,
  EMAIL,
  PIN,
  NOTE,
  SEARCH,
}

class UiInput extends StatefulWidget {
  UiInput({Key key, this.icon, this.placeholder, this.fontSize = 16.0, this.textAlign = TextAlign.start, this.showLabel = true, this.labelStyle, this.info, this.prefiks, this.height = 45.0, this.color, this.borderColor, this.borderWidth = 1.0, this.type = UiInputType.TEXT, this.caps, this.controller, this.focusNode, this.autofocus = false, this.initialValue, this.isRequired = false, this.readOnly = false, this.aksi, this.klik, this.cancelAction, this.onChanged, this.margin, this.borderRadius, this.elevation, this.dateFormat = "dd/MM/yyyy", this.isClearable = true, this.error = ''}) : super(key: key);
  final IconData icon;
  final String placeholder;
  final double fontSize;
  final TextAlign textAlign;
  final String info;
  final String prefiks;
  final bool showLabel;
  final TextStyle labelStyle;
  final double height;
  final Color color;
  final Color borderColor;
  final double borderWidth;
  final UiInputType type;
  // final TextInputType tipe;
  final TextCapitalization caps;
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool autofocus;
  final dynamic initialValue;
  final bool isRequired;
  final bool isClearable;
  final bool readOnly;
  final void Function(String) aksi;
  final void Function() klik;
  final void Function() cancelAction;
  final void Function(dynamic) onChanged;
  final EdgeInsets margin;
  final BorderRadius borderRadius;
  final double elevation;
  final String dateFormat;
  final String error;

  @override
  _UiInputState createState() => _UiInputState();
}

class _UiInputState extends State<UiInput> {
  EdgeInsetsGeometry _contentPadding = EdgeInsets.symmetric(vertical: 10.0);
  bool _viewText;
  Widget _input;

  @override
  void initState() {
    super.initState();
    _viewText = widget.type != UiInputType.PASSWORD && widget.type != UiInputType.PIN;
  }

  @override
  Widget build(BuildContext context) {
    final _prefixStyle = TextStyle(fontWeight: FontWeight.bold, fontSize: widget.fontSize);
    final _validator = (value) {
      if (widget.isRequired && value.isEmpty) {
        return "Harap isi ${widget.placeholder ?? "kolom ini"}";
      }
      return null;
    };
    double _iconSize = widget.fontSize * 1.3;
    Widget _icon = widget.icon == null ? null : Icon(widget.icon, size: _iconSize, color: Colors.grey);
    if (_icon == null) _contentPadding = EdgeInsets.only(top: 10.0, bottom: 10.0, left: 20.0);

    switch (widget.type) {
      case UiInputType.TEXT:
      case UiInputType.NOTE:
      case UiInputType.SEARCH:
      case UiInputType.EMAIL:
        _input = Stack(alignment: Alignment.topRight, children: <Widget>[
          Padding(
            padding: EdgeInsets.only(right: widget.cancelAction == null ? 16.0 : 40.0),
            child: TextFormField(
              // initialValue: widget.initialValue,
              keyboardType: widget.type == UiInputType.EMAIL ? TextInputType.emailAddress : TextInputType.text,
              textCapitalization: widget.caps ?? TextCapitalization.none,
              style: TextStyle(fontSize: widget.fontSize),
              textAlign: widget.textAlign,
              readOnly: widget.readOnly,
              decoration: InputDecoration(contentPadding: _contentPadding, hintText: widget.placeholder, prefixIcon: _icon, border: InputBorder.none),
              textInputAction: TextInputAction.go,
              controller: widget.controller,
              focusNode: widget.focusNode,
              maxLines: widget.type == UiInputType.NOTE ? null : 1,
              enableInteractiveSelection: widget.klik == null,
              onTap: widget.klik == null ? null : () {
                FocusScope.of(context).requestFocus(FocusNode());
                widget.klik();
              },
              //onSubmitted: widget.aksi,
              onChanged: widget.onChanged,
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
            style: TextStyle(fontSize: widget.fontSize),
            decoration: InputDecoration(contentPadding: _contentPadding, prefixStyle: _prefixStyle, prefix: Text(widget.prefiks ?? "+62  ", style: _prefixStyle), hintText: widget.placeholder, prefixIcon: _icon, border: InputBorder.none),
            textInputAction: TextInputAction.go,
            controller: widget.controller,
            focusNode: widget.focusNode,
            //onSubmitted: widget.aksi,
            autofocus: widget.autofocus,
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
            style: TextStyle(fontSize: widget.fontSize),
            textAlign: widget.textAlign,
            readOnly: widget.readOnly,
            decoration: InputDecoration(contentPadding: _contentPadding, prefixStyle: _prefixStyle, prefix: Text(widget.prefiks ?? "Rp  ", style: _prefixStyle), hintText: widget.placeholder, prefixIcon: _icon, border: InputBorder.none),
            textInputAction: TextInputAction.go,
            controller: widget.controller,
            focusNode: widget.focusNode,
            enableInteractiveSelection: widget.klik == null,
            onTap: widget.klik == null ? null : () {
              FocusScope.of(context).requestFocus(FocusNode());
              widget.klik();
            },
            inputFormatters: <TextInputFormatter>[
              WhitelistingTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(15),
              CurrencyInputFormatter()
            ],
            onChanged: widget.onChanged,
            //onSubmitted: widget.aksi,
            validator: _validator,
          ),
        );
        break;
      case UiInputType.PASSWORD:
      case UiInputType.PIN:
        _input = Stack(alignment: Alignment.topRight, children: <Widget>[
          Padding(
            padding: EdgeInsets.only(right: 40.0),
            child: TextFormField(
              obscureText: !_viewText,
              enableInteractiveSelection: false,
              keyboardType: widget.type == UiInputType.PIN ? TextInputType.number : null,
              inputFormatters: widget.type == UiInputType.PIN ? <TextInputFormatter>[
                WhitelistingTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ] : null,
              maxLines: 1,
              style: TextStyle(fontSize: widget.fontSize),
              decoration: InputDecoration(contentPadding: _contentPadding, hintText: widget.placeholder, prefixIcon: _icon, border: InputBorder.none),
              textInputAction: TextInputAction.go,
              controller: widget.controller,
              focusNode: widget.focusNode,
              validator: _validator,
            ),
          ),
          IconButton(icon: Icon(_viewText ? Icons.visibility_off : Icons.visibility), iconSize: _iconSize, color: Colors.grey, onPressed: () {
            setState(() { _viewText = !_viewText; });
          },),
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
          style: TextStyle(fontSize: widget.fontSize),
          decoration: InputDecoration(contentPadding: _contentPadding, hintText: widget.placeholder, prefixIcon: _icon, border: InputBorder.none),
          resetIcon: widget.isClearable ? Icon(LineIcons.close, size: widget.fontSize,) : null,
          onShowPicker: (context, currentValue) {
            DateTime now = DateTime.now();
            DateTime min = DateTime(2019);
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
          validator: _validator,
        );
        break;
    }

    return Padding(
      padding: widget.margin ?? EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          widget.showLabel
            ? Padding(padding: EdgeInsets.only(bottom: 8.0), child: Text(widget.placeholder + ((widget.info ?? "").isEmpty ? ":" : " (${widget.info}):"), style: widget.labelStyle ?? style.textLabel,),)
            : SizedBox(),
          Card(
            color: widget.color ?? Theme.of(context).cardColor,
            shape: RoundedRectangleBorder(
              // side: BorderSide(color: widget.borderColor ?? Colors.grey[350], width: 1.0,),
              borderRadius: widget.borderRadius ?? BorderRadius.circular(50.0),
            ),
            elevation: widget.elevation ?? 1.0,
            margin: EdgeInsets.zero,
            // TODO input note autosize height
            child: widget.height == null ? _input : SizedBox(height: widget.height, child: Center(child: _input,),),
          ),
          (widget.error ?? '').isEmpty ? SizedBox() : ErrorText(widget.error)
        ],
      ),
    );
  }
}

class UiSelect extends StatefulWidget {
  UiSelect({Key key, this.icon, this.listMenu, this.initialValue, this.value, this.placeholder, this.fontSize, this.margin, this.onSelect, this.error = ''}) : super(key: key);
  final IconData icon;
  final List<dynamic> listMenu;
  final dynamic initialValue;
  final dynamic value;
  final String placeholder;
  final double fontSize;
  final EdgeInsetsGeometry margin;
  final void Function(dynamic) onSelect;
  final String error;

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50.0),),
          elevation: 1.0,
          margin: widget.margin ?? EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: EdgeInsets.all(10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                SizedBox(width: 4,),
                widget.icon == null ? SizedBox() : Icon(widget.icon, size: 19.5, color: Colors.grey,),
                widget.icon == null ? SizedBox() : SizedBox(width: 14,),
                DropdownButtonHideUnderline(
                  child: DropdownButton<dynamic>(
                    isDense: true,
                    underline: null,
                    value: widget.value ?? _val,
                    hint: Text(widget.placeholder),
                    style: TextStyle(fontSize: widget.fontSize ?? 16, color: Theme.of(context).textTheme.bodyText1.color),
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
        ),
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
    _animationController = AnimationController(duration: Duration(milliseconds: 1500), vsync: this);
    _animation1 = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut
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
                  Icon(LineIcons.warning, color: Colors.red),
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
  UiButton({
    this.btnKey,
    this.color = THEME_COLOR,
    this.borderColor,
    this.icon,
    this.iconSize,
    this.iconPadding = 8.0,
    this.iconRight = false,
    this.label,
    this.onPressed,
    this.borderRadius,
    this.elevation = 2.0,
    this.textStyle,
    this.alignment,
    this.padding
  });
  final Color color;
  final Color borderColor;
  final IconData icon;
  final String label;
  final TextStyle textStyle;
  final double iconSize;
  final double iconPadding;
  final bool iconRight;
  final BorderRadius borderRadius;
  final double elevation;
  final Key btnKey;
  final MainAxisAlignment alignment;
  final void Function() onPressed;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    var _textStyle = textStyle ?? style.textButton;
    var _borderColor = borderColor ?? color;
    var _fontSize = _textStyle.fontSize;
    var _fontColor = _textStyle.color;
    var _fontWeight = _textStyle.fontWeight;
    var _icon = Icon(icon, color: _fontColor, size: iconSize ?? (_fontSize * 1.2),);
    return IgnorePointer(
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
          shape: RoundedRectangleBorder(
            // side: BorderSide(color: onPressed == null ? Colors.grey : _borderColor, width: 2),
            side: BorderSide(color: _borderColor, width: 2),
            borderRadius: borderRadius ?? BorderRadius.circular(30)
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.center, mainAxisAlignment: alignment ?? MainAxisAlignment.center, children: <Widget>[
            icon == null || iconRight ? SizedBox() : Padding(padding: EdgeInsets.only(right: iconPadding), child: _icon,),
            label == null ? SizedBox() : Text(label, style: TextStyle(color: _fontColor, fontWeight: _fontWeight, fontSize: _fontSize),),
            icon != null && iconRight ? Padding(padding: EdgeInsets.only(left: iconPadding), child: _icon,) : SizedBox(),
          ],),
          onPressed: onPressed ?? () {},
        ),
      ),
    );
  }
}