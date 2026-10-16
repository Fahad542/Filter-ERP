import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/LocalizedApiText.dart';
import '../utils/app_colors.dart';
import '../utils/ksa_vehicle_catalog.dart';

/// Same curated KSA make/model list as [PosAddCustomerView] autocomplete fields.
class PosKsaVehicleLookupController {
  List<String> makes = KsaVehicleCatalog.makes;
  final Map<String, List<String>> modelsByMake = {};

  bool hasExactMake(String value) => KsaVehicleCatalog.hasMake(value);

  void ensureMakes() {
    if (makes.isEmpty) makes = KsaVehicleCatalog.makes;
  }

  void ensureModelsForMake(String make) {
    final key = make.trim();
    if (key.isEmpty) return;
    modelsByMake[key] = KsaVehicleCatalog.modelsForMake(key);
  }

  List<String> makeSuggestions(String query) {
    ensureMakes();
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return makes.take(20).toList();
    return makes.where((m) => m.toLowerCase().contains(q)).take(20).toList();
  }

  List<String> modelSuggestions({required String make, required String query}) {
    final key = make.trim();
    ensureModelsForMake(key);
    final models = modelsByMake[key] ?? const <String>[];
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return models.take(20).toList();
    return models.where((m) => m.toLowerCase().contains(q)).take(20).toList();
  }
}

const Map<String, String> kPosKsaMakeArabicLabels = {
  'Toyota': 'تويوتا',
  'Nissan': 'نيسان',
  'Hyundai': 'هيونداي',
  'Kia': 'كيا',
  'Honda': 'هوندا',
  'Mazda': 'مازدا',
  'Mitsubishi': 'ميتسوبيشي',
  'Ford': 'فورد',
  'Chevrolet': 'شيفروليه',
  'GMC': 'جي إم سي',
  'Lexus': 'لكزس',
  'BMW': 'بي إم دبليو',
  'Mercedes-Benz': 'مرسيدس بنز',
  'Audi': 'أودي',
  'Volkswagen': 'فولكس واجن',
  'Isuzu': 'إيسوزو',
  'Suzuki': 'سوزوكي',
};

String posKsaVehicleMakeDisplayLabel(BuildContext context, String value) {
  final isAr = Localizations.maybeLocaleOf(context)?.languageCode == 'ar';
  if (!isAr) return value;
  final ar = kPosKsaMakeArabicLabels[value];
  if (ar == null || ar.isEmpty) return value;
  return '$ar - $value';
}

/// Make + model autocomplete row (Add Customer / KSA catalog).
class PosKsaVehicleMakeModelRow extends StatefulWidget {
  const PosKsaVehicleMakeModelRow({
    super.key,
    required this.makeController,
    required this.modelController,
    required this.decorationFor,
    required this.fieldStyle,
    this.readOnly = false,
    this.compact = true,
    this.spacing = 8,
  });

  final TextEditingController makeController;
  final TextEditingController modelController;
  final InputDecoration Function(
    String label, {
    bool optional,
    String optionalSuffix,
    bool compact,
  }) decorationFor;
  final TextStyle fieldStyle;
  final bool readOnly;
  final bool compact;
  final double spacing;

  @override
  State<PosKsaVehicleMakeModelRow> createState() =>
      _PosKsaVehicleMakeModelRowState();
}

class _PosKsaVehicleMakeModelRowState extends State<PosKsaVehicleMakeModelRow> {
  final PosKsaVehicleLookupController _lookup = PosKsaVehicleLookupController();
  int _modelFieldKey = 0;

  void _syncMakeField(String value, {required bool fromSelection}) {
    final previousMake = widget.makeController.text.trim();
    final hadExactMake = _lookup.hasExactMake(previousMake);
    widget.makeController.text = value;
    if (previousMake.toLowerCase() != value.trim().toLowerCase()) {
      final hadModel = widget.modelController.text.trim().isNotEmpty;
      widget.modelController.clear();
      if (hadModel) {
        _modelFieldKey++;
      }
    }
    _lookup.ensureMakes();
    final hasExactMake = _lookup.hasExactMake(value.trim());
    if (hadExactMake != hasExactMake || fromSelection) {
      setState(() {});
    } else if (_modelFieldKey > 0 &&
        previousMake.toLowerCase() != value.trim().toLowerCase()) {
      setState(() {});
    }
  }

  void _syncModelField(String value) {
    widget.modelController.text = value;
    final mk = widget.makeController.text.trim();
    if (_lookup.hasExactMake(mk)) {
      _lookup.ensureModelsForMake(mk);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final optionalSuffix = l10n.posSalesReturnOptional;
    final isAr = Localizations.maybeLocaleOf(context)?.languageCode == 'ar';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _makeField(context, isAr, optionalSuffix)),
        SizedBox(width: widget.spacing),
        Expanded(child: _modelField(context, isAr, optionalSuffix)),
      ],
    );
  }

  Widget _makeField(
    BuildContext context,
    bool isAr,
    String optionalSuffix,
  ) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _lookup.ensureMakes();
    });
    return Autocomplete<String>(
      initialValue: TextEditingValue(text: widget.makeController.text),
      optionsBuilder: (tev) => _lookup.makeSuggestions(tev.text),
      onSelected: widget.readOnly
          ? (_) {}
          : (selection) => _syncMakeField(selection, fromSelection: true),
      fieldViewBuilder: (context, textController, focusNode, onFieldSubmitted) {
        return TextFormField(
          controller: textController,
          focusNode: focusNode,
          readOnly: widget.readOnly,
          style: widget.fieldStyle,
          decoration: widget.decorationFor(
            AppLocalizations.of(context)!.posInvoiceDetailsMake,
            optional: true,
            optionalSuffix: optionalSuffix,
            compact: widget.compact,
          ),
          textCapitalization: TextCapitalization.words,
          textAlign: isAr ? TextAlign.right : TextAlign.left,
          textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
          onChanged: widget.readOnly
              ? null
              : (value) => _syncMakeField(value, fromSelection: false),
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return _optionsView(context, isAr, onSelected, options, isMake: true);
      },
    );
  }

  Widget _modelField(
    BuildContext context,
    bool isAr,
    String optionalSuffix,
  ) {
    final makeText = widget.makeController.text.trim();
    final hasMake = _lookup.hasExactMake(makeText);
    if (hasMake) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _lookup.ensureModelsForMake(makeText);
      });
    }
    return KeyedSubtree(
      key: ValueKey('ksa_model_$_modelFieldKey'),
      child: Autocomplete<String>(
        initialValue: TextEditingValue(text: widget.modelController.text),
      optionsBuilder: (tev) {
        final mk = widget.makeController.text.trim();
        if (!_lookup.hasExactMake(mk)) {
          return const Iterable<String>.empty();
        }
        return _lookup.modelSuggestions(make: mk, query: tev.text);
      },
      onSelected: widget.readOnly
          ? (_) {}
          : (selection) => _syncModelField(selection),
      fieldViewBuilder: (context, textController, focusNode, onFieldSubmitted) {
        return TextFormField(
          controller: textController,
          focusNode: focusNode,
          readOnly: widget.readOnly,
          style: widget.fieldStyle,
          decoration: widget
              .decorationFor(
                AppLocalizations.of(context)!.posInvoiceDetailsModel,
                optional: true,
                optionalSuffix: optionalSuffix,
                compact: widget.compact,
              )
              .copyWith(
                suffixIcon: !hasMake
                    ? Padding(
                        padding: const EdgeInsetsDirectional.only(end: 8),
                        child: Icon(
                          Icons.info_outline,
                          size: 18,
                          color: Colors.grey.shade400,
                        ),
                      )
                    : null,
              ),
          textCapitalization: TextCapitalization.words,
          textAlign: isAr ? TextAlign.right : TextAlign.left,
          textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
          onChanged: widget.readOnly ? null : _syncModelField,
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return _optionsView(context, isAr, onSelected, options, isMake: false);
      },
      ),
    );
  }

  Widget _optionsView(
    BuildContext context,
    bool isAr,
    void Function(String) onSelected,
    Iterable<String> options, {
    required bool isMake,
  }) {
    return Align(
      alignment: isAr ? Alignment.topRight : Alignment.topLeft,
      child: Material(
        elevation: 6,
        borderRadius: BorderRadius.circular(12),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400, maxHeight: 220),
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 6),
            shrinkWrap: true,
            itemCount: options.length,
            itemBuilder: (context, index) {
              final option = options.elementAt(index);
              return InkWell(
                onTap: () {
                  FocusManager.instance.primaryFocus?.unfocus();
                  onSelected(option);
                },
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: LocalizedApiText(
                    isMake
                        ? posKsaVehicleMakeDisplayLabel(context, option)
                        : option,
                    textAlign: isAr ? TextAlign.right : TextAlign.left,
                    textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.secondaryLight,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
