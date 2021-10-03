import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import '../utils/constants.dart';

class Toast {
  static const DEFAULT_SHOWUP_DURATION = 300;
  static const DEFAULT_DURATION = 2000;
  static const BOTTOM = 0;
  static const CENTER = 1;
  static const TOP = 2;

  static void show(String message, BuildContext context, {
    int duration = DEFAULT_DURATION,
    int gravity = BOTTOM,
    Color backgroundColor = const Color(0xAA000000),
    TextStyle textStyle = const TextStyle(fontFamily: APP_UI_FONT_MAIN, fontSize: 15, color: Colors.white),
    double backgroundRadius = APP_UI_BORDER_RADIUS,
    Border border = const Border(),
  }) {
    ToastView.dismiss();
    ToastView.createView(message, context, duration, gravity, backgroundColor, textStyle, backgroundRadius, border);
  }
}

class ToastView {
  static final ToastView _singleton = ToastView._internal();

  factory ToastView() {
    return _singleton;
  }

  ToastView._internal();

  static OverlayState? overlayState;
  static OverlayEntry? _overlayEntry;
  static bool _isVisible = false;

  static void createView(
    String message,
    BuildContext context,
    int duration,
    int gravity,
    Color background,
    TextStyle textStyle,
    double backgroundRadius,
    Border border
  ) async {
    try {
      overlayState = Overlay.of(context);
    } catch (e) {
      overlayState = null;
    }

    if (overlayState == null) return;

    Paint paint = Paint();
    paint.strokeCap = StrokeCap.square;
    paint.color = background;

    _overlayEntry = OverlayEntry(
      builder: (BuildContext context) => ToastWidget(
        gravity: gravity,
        widget: SizedBox(
          width: MediaQuery.of(context).size.width,
          child: Container(
            alignment: Alignment.center,
            width: MediaQuery.of(context).size.width,
            child: Container(
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(backgroundRadius),
                border: border,
              ),
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              child: Text(message, softWrap: true, style: textStyle),
            ),
          ),
        ),
      ),
    );
    _isVisible = true;
    overlayState?.insert(_overlayEntry!);
    await Future.delayed(Duration(milliseconds: duration));
    dismiss();
  }

  static dismiss() async {
    if (!_isVisible) return;
    _isVisible = false;
    _overlayEntry?.remove();
  }
}

class ToastWidget extends StatefulWidget {
  const ToastWidget({Key? key, required this.widget, required this.gravity}) : super(key: key);
  final Widget widget;
  final int gravity;

  @override
  _ToastWidgetState createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<ToastWidget> with TickerProviderStateMixin {
  AnimationController? _animationController;
  Animation? _animation;
  var _opacity = 0.0;

  @override
  void initState() {
    _animationController = AnimationController(duration: const Duration(milliseconds: Toast.DEFAULT_SHOWUP_DURATION), vsync: this);
    _animation = Tween(begin: 1.0, end: 0.0).animate(CurvedAnimation(
      parent: _animationController!,
      curve: Curves.easeOutBack
    ));
    super.initState();
    WidgetsBinding.instance?.addPostFrameCallback((_) {
      _animationController?.forward();
      setState(() {
        _opacity = 1.0;
      });
    });
  }

  @override
  void dispose() {
    _animationController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: widget.gravity == Toast.TOP ? MediaQuery.of(context).viewInsets.top + 50 : null,
      bottom: widget.gravity == Toast.BOTTOM ? MediaQuery.of(context).viewInsets.bottom + 50 : null,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: Toast.DEFAULT_SHOWUP_DURATION),
        opacity: _opacity,
        child: AnimatedBuilder(
          animation: _animationController!,
          builder: (BuildContext context, Widget? child) => Transform.translate(
            offset: Offset(0, _animation?.value * 100),
            child: Material(
              color: Colors.transparent,
              child: widget.widget,
            ),
          ),
        ),
      )
    );
  }
}
