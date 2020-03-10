import 'package:flutter/material.dart';

class CurveBackground extends StatelessWidget {
  CurveBackground({Key key, this.color, this.height}) : super(key: key);
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: height,
      child: CustomPaint(
        painter: CurvePainter(color: color),
      ),
    );
  }
}

class CurvePainter extends CustomPainter {
  CurvePainter({this.color = Colors.pink});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint();
    paint.color = color;
    paint.style = PaintingStyle.fill; // Change this to fill

    var path = Path();

    // path.moveTo(0, size.height * 0.25);
    // path.quadraticBezierTo(
    //     size.width / 2, size.height / 2, size.width, size.height * 0.25);
    // path.lineTo(size.width, 0);
    // path.lineTo(0, 0);

    path.moveTo(0, size.height * 0.32);
    path.quadraticBezierTo(
        size.width / 3, size.height / 2, size.width, size.height * 0.5);
    path.lineTo(size.width, 0);
    path.lineTo(0, 0);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}