import 'package:flutter/material.dart';
import 'package:outs_calculator/packing.dart';
import 'dart:ui' as ui;

typedef Style = ({
  Paint paintEdge,
  Paint paintFill,
  Paint paintBorder,
  Paint paintMeasure,
  TextPainter largeWidthText,
  TextPainter largeHeightText,
  TextPainter smallWidthText,
  TextPainter smallHeightText,
  Color measureColor,
  double measureLength
});

typedef TextSizes = ({
  double smallWidthText,
  double smallHeightText,
  double largeWidthText,
  double largeHeightText,
});

typedef Margins = ({
  double dxLeft,
  double dxRight,
  double dyTop,
  double dyBottom
});

TextStyle? _getAppMeasureStyle(BuildContext context, Color measureColor) {
  return Theme.of(context)
      .textTheme
      .titleLarge
      ?.copyWith(fontWeight: FontWeight.bold, color: measureColor);
}

Style _getAppStyle(Layout layout, BuildContext context) {
  var measureColor = Colors.red;
  return (
    paintEdge: Paint()
      ..strokeWidth = 3
      ..color = Theme.of(context).primaryColor
      ..style = PaintingStyle.stroke,
    paintFill: Paint()
      ..style = PaintingStyle.fill
      ..color = Theme.of(context).primaryColorLight,
    largeWidthText: TextPainter(
        text: TextSpan(
            text: layout.largeWidth.toString(),
            style: _getAppMeasureStyle(context, measureColor)),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center)
      ..layout(),
    largeHeightText: TextPainter(
        text: TextSpan(
            text: layout.largeHeight.toString(),
            style: _getAppMeasureStyle(context, measureColor)),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center)
      ..layout(),
    smallWidthText: TextPainter(
        text: TextSpan(
            text: layout.rects.first.width.toString(),
            style: _getAppMeasureStyle(context, measureColor)),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center)
      ..layout(),
    smallHeightText: TextPainter(
        text: TextSpan(
            text: layout.rects.first.height.toString(),
            style: _getAppMeasureStyle(context, measureColor)),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center)
      ..layout(),
    measureColor: measureColor,
    paintBorder: Paint()
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..color = Colors.black,
    paintMeasure: Paint()
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square
      ..color = measureColor,
    measureLength: 40,
  );
}

class OutsLayoutWidget extends StatelessWidget {
  const OutsLayoutWidget(this._packing, this._decorKey, this._layoutKey,
      {super.key});

  final Packing? _packing;
  final Key _decorKey;
  final Key _layoutKey;

  @override
  Widget build(BuildContext context) {
    if (_packing != null) {
      final layout = _packing.layout;
      final appStyle = _getAppStyle(layout, context);

      TextSizes sizes = (
        smallWidthText: appStyle.smallWidthText.height,
        smallHeightText: appStyle.smallHeightText.width,
        largeWidthText: appStyle.largeWidthText.height,
        largeHeightText: appStyle.largeHeightText.width,
      );

      final dxLeft = sizes.smallHeightText + appStyle.measureLength;
      final dxRight = sizes.largeHeightText + appStyle.measureLength;
      final dyTop = sizes.smallWidthText + appStyle.measureLength;
      final dyBottom = sizes.largeWidthText + appStyle.measureLength;

      final largeWidth = _packing.layout.largeWidth;
      final largeHeight = _packing.layout.largeHeight;
      final aspectRatio = largeWidth / largeHeight;

      return CustomPaint(
        key: _decorKey,
        painter: DecorationPainter(layout, appStyle, sizes),
        size: const Size(double.infinity, double.infinity),
        child: Padding(
          padding: EdgeInsets.fromLTRB(dxLeft, dyTop, dxRight, dyBottom),
          child: AspectRatio(
              aspectRatio: aspectRatio,
              child: CustomPaint(
                  key: _layoutKey,
                  painter: LayoutPainter(layout, appStyle, sizes),
                  size: const Size(double.infinity, double.infinity))),
        ),
      );
    } else {
      return Container();
    }
  }
}

abstract class StyledPainter extends CustomPainter {
  final Layout layout;
  final Style style;
  final TextSizes sizes;

  StyledPainter(this.layout, this.style, this.sizes);

  @override
  void paint(Canvas canvas, Size size) {
    paintStyled(canvas, size, style);
  }

  void paintStyled(Canvas canvas, Size size, Style customStyle);

  Future<ui.Image> renderCustomPainterToImage(
      double imageWidth, double imageHeight, Style style) async {
    final recorder = ui.PictureRecorder();
    final canvas =
        Canvas(recorder, Rect.fromLTWH(0, 0, imageWidth, imageHeight));

    paintStyled(canvas, Size(imageWidth, imageHeight), style);

    final picture = recorder.endRecording();
    return picture.toImage(imageWidth.ceil(), imageHeight.ceil());
  }
}

class DecorationPainter extends StyledPainter {
  DecorationPainter(super.layout, super.style, super.sizes);

  @override
  void paintStyled(Canvas canvas, Size size, Style customStyle) {
    var layoutOffset = Offset(sizes.smallHeightText + customStyle.measureLength,
        sizes.smallWidthText + customStyle.measureLength);
    var layoutCanvasSize = size +
        Offset(
            -2 * customStyle.measureLength -
                sizes.smallHeightText -
                sizes.largeHeightText,
            -2 * customStyle.measureLength -
                sizes.smallWidthText -
                sizes.largeWidthText);

    var widthFactor = layoutCanvasSize.width / layout.largeWidth;
    var heightFactor = layoutCanvasSize.height / layout.largeHeight;
    var smallSize = Size(layout.rects.first.width.toDouble() * widthFactor,
        layout.rects.first.height.toDouble() * heightFactor);

    _paintSmallDimensions(canvas, layoutOffset, smallSize, style, sizes);
    _paintLargeDimensions(canvas, layoutOffset, layoutCanvasSize, style, sizes);
  }

  void _paintLargeDimensions(Canvas canvas, Offset offset, Size layoutsize,
      Style style, TextSizes sizes) {
    // Draw Text
    var widthTextPlacementOffset = Offset(
            layoutsize.width / 2 - sizes.largeWidthText / 2,
            layoutsize.height + style.measureLength) +
        offset;
    style.largeWidthText.paint(canvas, widthTextPlacementOffset);
    var heightTextPlacementOffset = Offset(
            layoutsize.width + style.measureLength,
            layoutsize.height / 2 - sizes.largeHeightText / 2) +
        offset;
    style.largeHeightText.paint(canvas, heightTextPlacementOffset);
    // Draw brackets
    // Width
    var quarter = style.measureLength / 4;
    var threequarter = style.measureLength * 3 / 4;
    var half = style.measureLength / 2;
    canvas.drawLine(
        Offset(layoutsize.width + quarter, 0) + offset,
        Offset(layoutsize.width + threequarter, 0) + offset,
        style.paintMeasure);
    canvas.drawLine(
        Offset(layoutsize.width + quarter, layoutsize.height) + offset,
        Offset(layoutsize.width + threequarter, layoutsize.height) + offset,
        style.paintMeasure);
    canvas.drawLine(
        Offset(layoutsize.width + half, 0) + offset,
        Offset(layoutsize.width + half, layoutsize.height) + offset,
        style.paintMeasure);
    // Height
    canvas.drawLine(
        Offset(0, layoutsize.height + quarter) + offset,
        Offset(0, layoutsize.height + threequarter) + offset,
        style.paintMeasure);
    canvas.drawLine(
        Offset(layoutsize.width, layoutsize.height + quarter) + offset,
        Offset(layoutsize.width, layoutsize.height + threequarter) + offset,
        style.paintMeasure);
    canvas.drawLine(
        Offset(0, layoutsize.height + half) + offset,
        Offset(layoutsize.width, layoutsize.height + half) + offset,
        style.paintMeasure);
  }

  void _paintSmallDimensions(Canvas canvas, Offset offset, Size smallSize,
      Style style, TextSizes sizes) {
    // Draw Text
    var widthTextPlacementOffset = Offset(
        offset.dx + smallSize.width / 2 - style.smallWidthText.width / 2, 0);
    style.smallWidthText.paint(canvas, widthTextPlacementOffset);
    var heightTextPlacementOffset = Offset(
        0, offset.dy + smallSize.height / 2 - style.smallHeightText.height / 2);
    style.smallHeightText.paint(canvas, heightTextPlacementOffset);
    // Draw brackets
    // Width
    var quarter = style.measureLength / 4;
    var threequarter = style.measureLength * 3 / 4;
    var half = style.measureLength / 2;
    canvas.drawLine(Offset(0, -quarter) + offset,
        Offset(0, -threequarter) + offset, style.paintMeasure);
    canvas.drawLine(Offset(smallSize.width, -quarter) + offset,
        Offset(smallSize.width, -threequarter) + offset, style.paintMeasure);
    canvas.drawLine(Offset(0, -half) + offset,
        Offset(smallSize.width, -half) + offset, style.paintMeasure);
    // Height
    canvas.drawLine(Offset(-quarter, 0) + offset,
        Offset(-threequarter, 0) + offset, style.paintMeasure);
    canvas.drawLine(Offset(-quarter, smallSize.height) + offset,
        Offset(-threequarter, smallSize.height) + offset, style.paintMeasure);
    canvas.drawLine(Offset(-half, 0) + offset,
        Offset(-half, smallSize.height) + offset, style.paintMeasure);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

class LayoutPainter extends StyledPainter {
  TextPainter? errorPainter;
  LayoutPainter(super.layout, super.style, super.sizes);

  @override
  void paintStyled(Canvas canvas, Size size, Style customStyle) {
    canvas.drawRect(
        Offset.zero & size,
        Paint()
          ..strokeWidth = 2
          ..color = Color.fromARGB(100, 232, 228, 201));

    _paintLayout(canvas, Offset.zero, size, customStyle, sizes);
    _paintBorder(canvas, Offset.zero, size, customStyle, sizes);
  }

  Margins getMargins(Style customStyle) {
    return (
      dxLeft: sizes.smallHeightText + customStyle.measureLength,
      dxRight: sizes.largeHeightText + customStyle.measureLength,
      dyTop: sizes.smallWidthText + customStyle.measureLength,
      dyBottom: sizes.largeWidthText + customStyle.measureLength
    );
  }

  void _paintLayout(Canvas canvas, Offset offset, Size layoutsize,
      Style appStyle, TextSizes sizes) {
    var widthFactor = layoutsize.width / layout.largeWidth;
    var heightFactor = layoutsize.height / layout.largeHeight;
    // Render Layout
    for (var item in layout.rects) {
      var itemRect = Rect.zero;

      itemRect =
          (offset + Offset(item.left * widthFactor, item.top * heightFactor)) &
              Size(item.width * widthFactor, item.height * heightFactor);

      canvas.drawRect(itemRect, appStyle.paintFill);
      canvas.drawRect(itemRect, appStyle.paintEdge);
    }
  }

  void _paintBorder(Canvas canvas, Offset offset, Size layoutsize, Style style,
      TextSizes sizes) {
    // Draw border
    canvas.drawRect((Offset.zero + offset) & layoutsize, style.paintBorder);
  }

  // bool _isWithinRenderBounds(Canvas canvas, Size size, TextSizes sizes) {
  //   // Get the available space on the canvas
  //   var layoutCanvasSize = size +
  //       Offset(
  //           -2 * style.measureLength -
  //               sizes.smallHeightText -
  //               sizes.largeHeightText,
  //           -2 * style.measureLength -
  //               sizes.smallWidthText -
  //               sizes.largeHeightText);
  //   var layoutRect = Offset.zero & layoutCanvasSize;

  //   // canvas.drawRect(
  //   //     layoutRect,
  //   //     Paint()
  //   //       ..color = Colors.blue.shade100
  //   //       ..style = PaintingStyle.fill);

  //   // Get the smallest rectangle to contain the packed rectangles
  //   var widthFactor = layoutCanvasSize.width / layout.largeWidth;
  //   var heightFactor = layoutCanvasSize.height / layout.largeHeight;
  //   Rect bb = Rect.zero;
  //   for (var item in layout.rects) {
  //     var itemRect = Offset(item.left * widthFactor, item.top * heightFactor) &
  //         Size(item.width * widthFactor, item.height * heightFactor);
  //     var newRect = bb.expandToInclude(itemRect);
  //     if (!(bb == newRect)) {
  //       bb = newRect;
  //     }

  //     // canvas.drawRect(
  //     //     bb,
  //     //     Paint()
  //     //       ..strokeWidth = 3
  //     //       ..style = PaintingStyle.stroke);
  //   }

  //   // Finally, determine whether this rectangle will exceed the available space. True if within, false otherwise.
  //   return bb.expandToInclude(layoutRect) == layoutRect;
  // }

  // TextPainter _getErrorRender(BuildContext context) {
  //   return TextPainter(
  //       text: TextSpan(
  //           text:
  //               "Screen size too small to display layout accurately,\nplease either export to pdf or print!",
  //           style: Theme.of(context).textTheme.titleLarge?.copyWith(
  //               fontWeight: FontWeight.bold,
  //               color: Colors.black,
  //               backgroundColor: Colors.transparent)),
  //       textDirection: TextDirection.ltr,
  //       maxLines: 3,
  //       textWidthBasis: TextWidthBasis.parent,
  //       textAlign: TextAlign.center)
  //     ..layout();
  // }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
