import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter/rendering.dart';
import 'package:outs_calculator/layout_widget.dart';
import 'package:outs_calculator/packing/packing.dart';

void showLayoutGuidelines() {
  debugPaintSizeEnabled = true;
}

void main() {
  runApp(const MyApp());
}

enum SizeType {
  large(name: "Parent Sheet"),
  small(name: "Item");

  final String name;

  const SizeType({required this.name});
}

enum DimensionType {
  long(name: "Width"),
  short(name: "Height");

  final String name;

  const DimensionType({required this.name});
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
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String msg = '';

  final largeShortControl = TextEditingController();
  final largeLongControl = TextEditingController();
  final smallShortControl = TextEditingController();
  final smallLongControl = TextEditingController();

  Packing? packing;

  Widget _textField(
      BuildContext context, SizeType sizeType, DimensionType dimensionType) {
    return Expanded(
        child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            child: TextFormField(
                keyboardType: TextInputType.number,
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 1,
                textAlignVertical: TextAlignVertical.top,
                textAlign: TextAlign.right,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9]*\.?[0-9]*'))
                ],
                decoration: InputDecoration(
                    label: Text(dimensionType.name,
                        style: Theme.of(context).textTheme.bodyMedium),
                    suffixText: 'in', // Those are Americans...
                    floatingLabelAlignment: FloatingLabelAlignment.start),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please input dimension';
                  }
                  return null;
                },
                controller: switch ((sizeType, dimensionType)) {
                  (SizeType.large, DimensionType.short) => largeShortControl,
                  (SizeType.large, DimensionType.long) => largeLongControl,
                  (SizeType.small, DimensionType.short) => smallShortControl,
                  (SizeType.small, DimensionType.long) => smallLongControl
                })));
  }

  Widget _dimensionField(BuildContext context, SizeType sizeType) {
    return Container(
      margin: const EdgeInsets.all(8.0),
      child: Column(children: [
        Text(
          '${sizeType.name} Dimension',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        Row(children: [
          _textField(context, sizeType, DimensionType.short),
          _textField(context, sizeType, DimensionType.long),
        ])
      ]),
    );
  }

  void _parseDimensions() {
    if (_formKey.currentState!.validate()) {
      double largeLong = double.tryParse(largeLongControl.text)!;
      double largeShort = double.tryParse(largeShortControl.text)!;
      double smallLong = double.tryParse(smallLongControl.text)!;
      double smallShort = double.tryParse(smallShortControl.text)!;

      double largeArea = largeLong * largeShort;
      double smallArea = smallLong * smallShort;

      if (largeArea > 0 && smallArea > 0 && largeArea > smallArea) {
        setState(() {
          msg = '';
          packing = getBestPack(largeLong, largeShort, smallLong, smallShort);
        });
      } else {
        setState(() {
          msg = 'Parent sheet dimensions smaller than item dimensions';
          packing = null;
        });
      }
    } else {
      setState(() {
        packing = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(title: const Text("Outs Calculator")),
        body: Form(
          key: _formKey,
          child: Column(mainAxisAlignment: MainAxisAlignment.start, children: [
            _dimensionField(context, SizeType.large),
            _dimensionField(context, SizeType.small),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              width: double.infinity,
              child: ElevatedButton(
                  onPressed: _parseDimensions,
                  style: TextButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.primary),
                  child: const Text('Calculate Outs')),
            ),
            Container(
                margin: const EdgeInsets.all(8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Text('Outs: ${packing?.outs ?? ''}',
                        style: Theme.of(context).textTheme.bodyLarge),
                    Text(
                      'Efficency: ${packing?.fill.toStringAsPrecision(3) ?? ''}%',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                )),
            Flexible(
                fit: FlexFit.loose,
                child: Container(
                  margin: const EdgeInsets.all(16),
                  child: OutsLayoutWidget(packing),
                )),
          ]),
        ));
  }
}
