import 'dart:math';

import 'package:flutter/material.dart';

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:outs_calculator/layout_widget.dart';
import 'package:outs_calculator/packing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:ui' as ui;
import 'package:printing/printing.dart';

void main() {
  runApp(const MyApp());
}

enum PaperSize {
  small("Item"),
  large("Parent");

  final String name;

  const PaperSize(this.name);
}

enum Dimension {
  short("Width"),
  long("Height");

  final String name;

  const Dimension(this.name);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    // showLayoutGuidelines();
    return MaterialApp(
      title: 'Outs Calculator',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

/// Page for inputting dimensions of the parent sheet and the item dimensions
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _formKey = GlobalKey<FormState>();
  final _decorKey = GlobalKey();
  final _layoutKey = GlobalKey();
  final defaultPaper = PdfPageFormat.letter.copyWith(
      marginLeft: 0.25 * PdfPageFormat.inch,
      marginRight: 0.25 * PdfPageFormat.inch,
      marginBottom: 0.25 * PdfPageFormat.inch,
      marginTop: 0.25 * PdfPageFormat.inch);
  Packing? packing;
  String errorMessage = "";

  final TextEditingController largeLongController = TextEditingController();
  final TextEditingController largeShortController = TextEditingController();
  final TextEditingController smallLongController = TextEditingController();
  final TextEditingController smallShortController = TextEditingController();

  TextStyle? _getPdfMeasureStyle(Color measureColor, Color backgroudTextColor) {
    return TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: measureColor,
        backgroundColor: backgroudTextColor);
  }

  Style? _getPdfStyle() {
    var measureColor = Colors.red;
    var backgroudTextColor = Colors.transparent;
    if (packing == null) {
      return null;
    }
    return (
      paintEdge: Paint()
        ..strokeWidth = 5
        ..color = Theme.of(context).primaryColor
        ..style = PaintingStyle.stroke,
      paintFill: Paint()
        ..style = PaintingStyle.fill
        ..color = Theme.of(context).primaryColorLight,
      largeWidthText: TextPainter(
          text: TextSpan(
              text: packing!.layout.largeWidth.toString(),
              style: _getPdfMeasureStyle(measureColor, backgroudTextColor)),
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.center)
        ..layout(),
      largeHeightText: TextPainter(
          text: TextSpan(
              text: packing!.layout.largeHeight.toString(),
              style: _getPdfMeasureStyle(measureColor, backgroudTextColor)),
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.center)
        ..layout(),
      smallWidthText: TextPainter(
          text: TextSpan(
              text: packing!.layout.rects.first.width.toString(),
              style: _getPdfMeasureStyle(measureColor, backgroudTextColor)),
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.center)
        ..layout(),
      smallHeightText: TextPainter(
          text: TextSpan(
              text: packing!.layout.rects.first.height.toString(),
              style: _getPdfMeasureStyle(measureColor, backgroudTextColor)),
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.center)
        ..layout(),
      measureColor: measureColor,
      backgroudTextColor: backgroudTextColor,
      paintBorder: Paint()
        ..strokeWidth = 5
        ..style = PaintingStyle.stroke
        ..color = Colors.black,
      paintMeasure: Paint()
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.square
        ..color = measureColor,
      measureLength: 40
    );
  }

  DecorationPainter? _getDecorPainter() {
    final paintWidget = _decorKey.currentContext?.findRenderObject();
    if (paintWidget is RenderCustomPaint) {
      final painter = paintWidget.painter;
      if (painter != null && painter is DecorationPainter) {
        return painter;
      }
    }
    return null;
  }

  LayoutPainter? _getLayoutPainter() {
    final paintWidget = _layoutKey.currentContext?.findRenderObject();
    if (paintWidget is RenderCustomPaint) {
      final painter = paintWidget.painter;
      if (painter != null && painter is LayoutPainter) {
        return painter;
      }
    }
    return null;
  }

  PdfPageFormat _getOptimalPageFormat(PdfPageFormat original) {
    final aspectRatio =
        packing!.layout.largeWidth / packing!.layout.largeHeight;

    if (aspectRatio > 1) {
      // Width > Height -> landscape
      return original.landscape;
    } else {
      // Width <= Height -> protrait
      return original.portrait;
    }
  }

  Future<Uint8List> _generatePdf(PdfPageFormat pageFormat) async {
    final pdf = pw.Document(compress: true);

    // Render the CustomPainter to an image
    final decorPainter = _getDecorPainter();
    final layoutPainter = _getLayoutPainter();
    if (decorPainter != null && layoutPainter != null && packing != null) {
      final pdfStyle = _getPdfStyle()!;
      final margins = layoutPainter.getMargins(pdfStyle);
      final aspectRatio =
          packing!.layout.largeWidth / packing!.layout.largeHeight;

      final totalPixellWidth = pageFormat.availableWidth / PdfPageFormat.dp;
      final totalPixelHeight =
          0.95 * pageFormat.availableHeight / PdfPageFormat.dp;

      final layoutPixelWidth =
          totalPixellWidth - (margins.dxLeft + margins.dxRight);

      final layoutPixelHeight =
          totalPixelHeight - (margins.dyTop + margins.dyBottom);

      final actualLayoutPixelHeight =
          min(layoutPixelWidth / aspectRatio, layoutPixelHeight);

      final actualDecorPixelHeight = min(
          actualLayoutPixelHeight + margins.dyTop + margins.dyBottom,
          layoutPixelHeight);

      final decorImage = await decorPainter.renderCustomPainterToImage(
          totalPixellWidth, actualDecorPixelHeight, pdfStyle);
      final layoutImage = await layoutPainter.renderCustomPainterToImage(
          layoutPixelWidth, actualLayoutPixelHeight, pdfStyle);

      final byteDataDecor =
          await decorImage.toByteData(format: ui.ImageByteFormat.png);
      final byteDataLayout =
          await layoutImage.toByteData(format: ui.ImageByteFormat.png);
      if (byteDataDecor != null && byteDataLayout != null) {
        final byteDataDecorIntList = byteDataDecor.buffer.asUint8List();
        final byteDataLayoutIntList = byteDataLayout.buffer.asUint8List();

        final pdfImageDecor = pw.MemoryImage(byteDataDecorIntList);
        final pdfImageLayout = pw.MemoryImage(byteDataLayoutIntList);

        pdf.addPage(
          pw.Page(
            pageFormat: pageFormat,
            build: (context) {
              return pw.Column(
                children: [
                  pw.Stack(alignment: pw.Alignment.center, children: [
                    pw.Padding(
                        padding: pw.EdgeInsets.fromLTRB(
                            margins.dxLeft * PdfPageFormat.dp,
                            margins.dyTop * PdfPageFormat.dp,
                            margins.dxRight * PdfPageFormat.dp,
                            margins.dyBottom * PdfPageFormat.dp),
                        child: pw.Image(pdfImageLayout)),
                    pw.Image(pdfImageDecor)
                  ]),
                  pw.Text(
                      "Outs: ${packing!.outs}, Efficiency: ${packing!.fill.toStringAsFixed(2)}%",
                      style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.red)),
                  pw.Center()
                ],
              );
            },
          ),
        );
      }
    }

    return pdf.save();
  }

  TextEditingController? _getController(
      PaperSize paperSize, Dimension dimension) {
    if (paperSize == PaperSize.large && dimension == Dimension.long) {
      return largeLongController;
    } else if (paperSize == PaperSize.large && dimension == Dimension.short) {
      return largeShortController;
    } else if (paperSize == PaperSize.small && dimension == Dimension.long) {
      return smallLongController;
    } else if (paperSize == PaperSize.small && dimension == Dimension.short) {
      return smallShortController;
    }
    return null;
  }

  Widget _inputField(PaperSize paperSize, Dimension dimension) {
    return Expanded(
        child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: TextFormField(
        controller: _getController(paperSize, dimension),
        decoration: InputDecoration(labelText: dimension.name),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9]*\.?[0-9]*'))
        ],
        keyboardType:
            const TextInputType.numberWithOptions(signed: false, decimal: true),
        maxLines: 1,
        validator: (value) {
          if (value != null) {
            double? num = double.tryParse(value);
            if (num != null) {
              if (num > 0) {
                return null;
              } else {
                return "Must be greater than zero!";
              }
            } else {
              return "Not an number!";
            }
          }
          return "Please enter number";
        },
      ),
    ));
  }

  Widget _inputAreaContainer(PaperSize size) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(4)),
      child: Column(children: [
        Text(
          '${size.name} Size',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          _inputField(size, Dimension.short),
          _inputField(size, Dimension.long)
        ]),
      ]),
    );
  }

  String _validatePackingRequirements() {
    if (!_formKey.currentState!.validate()) return "Invalid Dimensions!";

    double largeLong = double.parse(largeLongController.text);
    double largeShort = double.parse(largeShortController.text);
    double smallLong = double.parse(smallLongController.text);
    double smallShort = double.parse(smallShortController.text);

    if (largeShort * largeLong < smallShort * smallLong) {
      return "Item is too big for parent!";
    }
    if (min(largeShort, largeLong) < min(smallShort, smallLong)) {
      return "Item is too big for parent!";
    }
    if (max(largeShort, largeLong) < max(smallShort, smallLong)) {
      return "Item is too big for parent!";
    }

    return "";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          title: const Text("Outs Calculator"),
          actions: [
            IconButton(
                onPressed: () {
                  if (packing != null) {
                    final pdf =
                        _generatePdf(_getOptimalPageFormat(defaultPaper));
                    final filename =
                        "${packing!.layout.smallWidth}x${packing!.layout.smallHeight}_in_${packing!.layout.largeWidth}x${packing!.layout.largeWidth}_layout.pdf";
                    pdf.then((Uint8List value) =>
                        Printing.sharePdf(filename: filename, bytes: value));
                  }
                },
                icon: Icon(Icons.share)),
            IconButton(
                onPressed: () {
                  if (packing != null) {
                    Printing.layoutPdf(
                        usePrinterSettings: false,
                        forceCustomPrintPaper: true,
                        format: _getOptimalPageFormat(defaultPaper),
                        onLayout: (_) =>
                            _generatePdf(_getOptimalPageFormat(defaultPaper)));
                  }
                },
                icon: Icon(Icons.print)),
          ],
        ),
        body: Form(
          key: _formKey,
          child: Column(children: [
            _inputAreaContainer(PaperSize.large),
            _inputAreaContainer(PaperSize.small),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              width: double.infinity,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Center(
                        child: Text(
                      errorMessage,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium!
                          .copyWith(color: Theme.of(context).colorScheme.error),
                    )),
                    ElevatedButton(
                        onPressed: () {
                          setState(() {
                            errorMessage = _validatePackingRequirements();
                          });
                          if (errorMessage.isEmpty) {
                            double largeLong =
                                double.parse(largeLongController.text);
                            double largeShort =
                                double.parse(largeShortController.text);
                            double smallLong =
                                double.parse(smallLongController.text);
                            double smallShort =
                                double.parse(smallShortController.text);
                            Packing? tempPacking = getBestPack(
                                largeShort, largeLong, smallShort, smallLong);
                            setState(() {
                              packing = tempPacking;
                            });
                          }
                        },
                        style: TextButton.styleFrom(
                            foregroundColor: Theme.of(context).primaryColor,
                            backgroundColor:
                                Theme.of(context).primaryColorLight),
                        child: const Text(
                          'Calculate Outs',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ))
                  ]),
            ),
            Container(
                margin: const EdgeInsets.all(8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Text(packing != null ? 'Outs: ${packing!.outs}' : '',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.bold, color: Colors.red)),
                    Text(
                      packing != null
                          ? 'Efficency: ${packing!.fill.toStringAsPrecision(3)}%'
                          : '',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold, color: Colors.red),
                    ),
                  ],
                )),
            Flexible(
                fit: FlexFit.loose,
                child: Container(
                  margin: const EdgeInsets.all(8),
                  child: OutsLayoutWidget(packing, _decorKey, _layoutKey),
                )),
          ]),
        ));
  }
}
