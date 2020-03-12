import 'package:flutter/material.dart';

extension WidgetExtension on Widget {

  // fungsi untuk menambahkan padding pada widget
  // cara kerjanya mirip seperti padding pada CSS
  Widget withPadding(double t, [double r, double b, double l]) {
    if (r == null) return Padding(padding: EdgeInsets.all(t), child: this);
    if (b == null) { b = t; l = r; } l ??= r;
    return Padding(padding: EdgeInsets.only(top: t, right: r, bottom: b, left: l), child: this);
  }

  // fungsi untuk mengatur ukuran widget
  Widget withSize(double size, [double height]) {
    return SizedBox(width: size, height: height ?? size, child: this);
  }

  // fungsi untuk menggeser posisi widget
  Widget withOffset(double x, double y) {
    return Transform.translate(offset: Offset(x, y), child: this);
  }

  // fungsi untuk memanipulasi skala ukuran widget
  Widget withScale(double scale) {
    return Transform.scale(scale: scale, child: this);
  }

  // fungsi untuk mengatur transparansi widget
  Widget withOpacity(double opacity) {
    return Opacity(opacity: opacity, child: this);
  }

  // fungsi untuk menambahkan badge angka pada widget
  Widget withBadge(int num, {bool showNum = true, Alignment alignment = Alignment.topRight, Color bgColor = Colors.blue, double fontSize = 14.0, Color fontColor = Colors.white, Color borderColor = Colors.white, double borderWidth = 2.0, show = true}) {
    return Stack(alignment: alignment, children: <Widget>[
      this,
      show && num > 0 ? Card(
        shape: CircleBorder(side: BorderSide(color: borderColor, width: borderWidth),),
        color: bgColor,
        child: showNum ? Text("$num", style: TextStyle(fontSize: fontSize, color: fontColor),).withPadding(5) : SizedBox(width: 12, height: 12,)
      ).withOffset(8, -8) : SizedBox(),
    ],);
  }

  // fungsi untuk menambahkan badge icon pada widget
  Widget withSign(IconData icon, {Color bgColor = Colors.blue, Color iconColor = Colors.white, Color borderColor = Colors.white, double borderWidth = 2.0, double elevation = 1.0, double offsetX = 8.0, double offsetY = 8.0, bool show = true}) {
    if (show) return Stack(alignment: Alignment.bottomRight, children: <Widget>[
      this,
      Card(
        elevation: elevation,
        shape: CircleBorder(side: BorderSide(color: borderColor, width: borderWidth),),
        color: bgColor,
        child: Icon(icon, color: iconColor, size: 20,).withPadding(5)
      ).withOffset(offsetX, offsetY),
    ],);
    return this;
  }

  // fungsi untuk animasi shimmer pada widget
  Widget shimmerIt([bool shimmer = true, double opacity = 0.5]) {
    return shimmer ? ShimmerIt(child: this, opacity: opacity,) : this;
  }

  // fungsi untuk menampilkan widget hanya jika kondisi terpenuhi
  // jangan gunakan untuk widget yang besar, karena cara kerjanya
  // adalah widget benar-benar dimuat sebelum disembunyikan, tapi
  // bagus dipergunakan jika widget secara pasti akan ditampilkan
  Widget hideIf(bool cond) {
    // return cond ? this : SizedBox();
    return Visibility(child: this, visible: !cond);
  }

  // fungsi untuk memposisikan widget di tengah
  Widget toCenter() {
    return Center(child: this);
  }
}

class ShimmerIt extends StatefulWidget {
  ShimmerIt({Key key, this.child, this.shimmer = true, this.opacity = 0.5}) : super(key: key);
  final Widget child;
  final bool shimmer;
  final double opacity;

  @override
  _ShimmerItState createState() => _ShimmerItState();
}

class _ShimmerItState extends State<ShimmerIt> with SingleTickerProviderStateMixin {
  AnimationController _animationController;
  Animation _animation;

  @override
  void initState() {
    _animationController = AnimationController(duration: Duration(milliseconds: 1500), vsync: this)..repeat(reverse: true);
    _animation = Tween(begin: widget.opacity * 0.4, end: widget.opacity).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));
    super.initState();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.shimmer ? AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) => Opacity(opacity: _animation.value, child: widget.child,),
    ) : widget.child;
  }
}
