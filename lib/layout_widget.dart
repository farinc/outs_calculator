import 'dart:math';

import 'package:flutter/material.dart';
import 'package:outs_calculator/packing/packing.dart';

class OutsLayoutWidget extends StatelessWidget {
  const OutsLayoutWidget(this._packing, {super.key});

  final Packing? _packing;

  @override
  Widget build(BuildContext context) {
    return _packing != null
        ? LayoutBuilder(builder: (_, BoxConstraints contraints) {
            var largeWidth = _packing!.layout.largeWidth;
            var largeHeight = _packing!.layout.largeHeight;
            var maxScaledWidth =
                contraints.maxWidth - (contraints.maxWidth % largeWidth);
            var maxScaledHeight =
                contraints.maxHeight - (contraints.maxHeight % largeHeight);

            return CustomPaint(
              painter: LayoutPainter(_packing?.layout),
              child: Container(
                width: maxScaledWidth,
                height: maxScaledHeight,
              ),
            );
          })
        : Container();
  }
}

class LayoutPainter extends CustomPainter {
  final Layout? layout;

  LayoutPainter(this.layout);

  @override
  void paint(Canvas canvas, Size size) {
    if (layout != null) {
      var paintRects = Paint()
        ..strokeWidth = 3
        ..color = Colors.blue
        ..style = PaintingStyle.stroke;
      var paintBack = Paint()
        ..style = PaintingStyle.fill
        ..color = Colors.black;

      var widthFactor = size.width / layout!.largeWidth;
      var heightFactor = size.height / layout!.largeHeight;
      canvas.drawRect(Offset.zero & Size(size.width, size.height), paintBack);

      for (var item in layout!.rects) {
        canvas.drawRect(
            Rect.fromLTWH(item.left * widthFactor, item.top * heightFactor,
                item.width * widthFactor, item.height * heightFactor),
            paintRects);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
