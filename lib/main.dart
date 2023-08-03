import 'package:flutter/material.dart';

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:outs_calculator/layout_widget.dart';
import 'package:outs_calculator/packing.dart';
import 'package:reactive_forms/reactive_forms.dart';

void showLayoutGuidelines() {
  debugPaintSizeEnabled = true;
}

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

Map<String, dynamic>? _dimensionValidate(AbstractControl<dynamic> control) {
  return control.isNotNull && control.value is double && control.value! > 0.0
      ? null
      : {"dimension": true};
}

Map<String, dynamic>? paperSizesValidate(AbstractControl<dynamic> control) {
  final formGroup = control as FormGroup;

  double? largeWidth =
      formGroup.control('${PaperSize.large.name}${Dimension.short.name}').value;
  double? largeHeight =
      formGroup.control('${PaperSize.large.name}${Dimension.long.name}').value;
  double? smallWidth =
      formGroup.control('${PaperSize.small.name}${Dimension.short.name}').value;
  double? smallHeight =
      formGroup.control('${PaperSize.small.name}${Dimension.long.name}').value;

  bool largeValueCheck = largeWidth != null && largeHeight != null;
  bool smallValueCheck = smallWidth != null && smallHeight != null;

  if (largeValueCheck) {
    if (largeWidth > largeHeight) {
      return {PaperSize.large.name: true};
    }
  }

  if (smallValueCheck) {
    if (smallWidth > smallHeight) {
      return {PaperSize.small.name: true};
    }
  }

  if (largeValueCheck && smallValueCheck) {
    var smallArea = smallWidth * smallHeight;
    var largeArea = largeWidth * largeHeight;
    if (smallArea > largeArea) {
      return {"area": true};
    }
  }

  return null;
}

FormControl<double> _inputFormControl() {
  return FormControl<double>(validators: [
    Validators.required,
    Validators.pattern(r'[0-9]*\.?[0-9]*'),
    Validators.delegate(_dimensionValidate),
  ]);
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
  final formGroup = FormGroup({
    "${PaperSize.large.name}${Dimension.short.name}": _inputFormControl(),
    "${PaperSize.large.name}${Dimension.long.name}": _inputFormControl(),
    "${PaperSize.small.name}${Dimension.short.name}": _inputFormControl(),
    "${PaperSize.small.name}${Dimension.long.name}": _inputFormControl()
  }, validators: [
    Validators.delegate(paperSizesValidate)
  ]);

  double? largeWidth;
  double? largeHeight;
  double? smallWidth;
  double? smallHeight;

  Packing? packing;

  void _dimensionChanged(
      PaperSize paperSize, Dimension dimension, double? mag) {
    switch ((paperSize, dimension)) {
      case (PaperSize.large, Dimension.short):
        largeWidth = mag;
        break;
      case (PaperSize.large, Dimension.long):
        largeHeight = mag;
        break;
      case (PaperSize.small, Dimension.short):
        smallWidth = mag;
        break;
      case (PaperSize.small, Dimension.long):
        smallHeight = mag;
        break;
    }
  }

  Widget _inputField(PaperSize paperSize, Dimension dimension) {
    return Expanded(
        child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ReactiveTextField(
        formControlName: "${paperSize.name}${dimension.name}",
        onChanged: (control) =>
            _dimensionChanged(paperSize, dimension, control.value as double?),
        decoration: InputDecoration(labelText: dimension.name),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9]*\.?[0-9]*'))
        ],
        keyboardType:
            const TextInputType.numberWithOptions(signed: false, decimal: true),
        maxLines: 1,
        validationMessages: {
          ValidationMessage.required: (error) => 'Please input dimension',
          "dimension": (error) => 'Cannot be zero'
        },
      ),
    ));
  }

  Widget _inputAreaContainer(PaperSize size) {
    return ReactiveFormConsumer(
        builder: (context, form, child) => Container(
              padding: const EdgeInsets.symmetric(vertical: 4),
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                  color: form.hasError('area') || form.hasError(size.name)
                      ? Theme.of(context).colorScheme.error.withAlpha(20)
                      : null,
                  borderRadius: BorderRadius.circular(4)),
              child: Column(children: [
                Text(
                  '${size.name} Size',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _inputField(size, Dimension.short),
                      _inputField(size, Dimension.long)
                    ]),
              ]),
            ));
  }

  String _getErrorText(FormGroup form) {
    if (form.hasError('area')) {
      return 'Parent sheet is too small for item';
    } else if (form.hasError(PaperSize.large.name)) {
      return 'Parent sheet must have a height greater than width';
    } else if (form.hasError(PaperSize.small.name)) {
      return 'Item sheet must have a height greater than width';
    }

    return '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(title: const Text("Outs Calculator")),
        body: ReactiveForm(
          formGroup: formGroup,
          child: Column(children: [
            _inputAreaContainer(PaperSize.large),
            _inputAreaContainer(PaperSize.small),
            ReactiveFormConsumer(builder: (context, form, child) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: double.infinity,
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _getErrorText(form),
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                            color: Theme.of(context).colorScheme.error),
                      ),
                      ElevatedButton(
                          onPressed: () {
                            if (form.valid) {
                              setState(() {
                                packing = getBestPack(largeWidth!, largeHeight!,
                                    smallWidth!, smallHeight!);
                              });
                            }
                          },
                          style: TextButton.styleFrom(
                              foregroundColor:
                                  Theme.of(context).colorScheme.primary),
                          child: const Text('Calculate Outs'))
                    ]),
              );
            }),
            Container(
                margin: const EdgeInsets.all(4),
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
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.5),
                        spreadRadius: 5,
                        blurRadius: 7,
                        offset:
                            const Offset(0, 3), // changes position of shadow
                      ),
                    ],
                  ),
                  child: OutsLayoutWidget(packing),
                )),
          ]),
        ));
  }
}
