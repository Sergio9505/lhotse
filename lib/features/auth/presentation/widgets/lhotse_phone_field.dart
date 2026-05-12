import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/data/countries.dart';
import '../../../../core/theme/app_theme.dart';
import 'lhotse_country_picker.dart';

/// Phone capture with country selector + grouped local digits.
///
/// Layout: `[🇪🇸  +34  ▾]   [600 123 456]` — single underline. The local
/// number is grouped every 3 digits while typing for readability; the
/// E.164 export strips the spaces.
class LhotsePhoneField extends StatefulWidget {
  const LhotsePhoneField({
    super.key,
    required this.controller,
    this.label = 'TELÉFONO',
    this.textInputAction = TextInputAction.next,
    this.autofocus = false,
    this.onSubmitted,
    this.errorText,
  });

  final LhotsePhoneController controller;
  final String label;
  final TextInputAction textInputAction;
  final bool autofocus;
  final ValueChanged<String>? onSubmitted;
  final String? errorText;

  @override
  State<LhotsePhoneField> createState() => _LhotsePhoneFieldState();
}

class _LhotsePhoneFieldState extends State<LhotsePhoneField> {
  late final TextEditingController _textController;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(
      text: _format(widget.controller.localNumber),
    );
    _focusNode = FocusNode();
    _focusNode.addListener(() => setState(() {}));
    widget.controller.addListener(_onControllerChange);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChange);
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onControllerChange() {
    // External mutations (e.g. clearing) sync the visible text.
    final formatted = _format(widget.controller.localNumber);
    if (_textController.text != formatted) {
      _textController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
    setState(() {});
  }

  String _format(String digits) {
    final clean = digits.replaceAll(RegExp(r'\D'), '');
    final buf = StringBuffer();
    for (var i = 0; i < clean.length; i++) {
      if (i > 0 && i % 3 == 0) buf.write(' ');
      buf.write(clean[i]);
    }
    return buf.toString();
  }

  Future<void> _pickCountry() async {
    final picked = await showLhotseCountryPicker(
      context,
      selected: widget.controller.country,
    );
    if (picked != null) {
      widget.controller.setCountry(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isFocused = _focusNode.hasFocus;
    final underlineColor = isFocused
        ? AppColors.textPrimary
        : AppColors.textPrimary.withValues(alpha: 0.2);
    final underlineWidth = isFocused ? 1.0 : 0.5;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Text(
          widget.label.toUpperCase(),
          style: AppTypography.labelUppercaseSm.copyWith(
            color: AppColors.accentMuted,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 8),

        // Row: country selector + local number, sharing a single underline.
        Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: underlineColor,
                width: underlineWidth,
              ),
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Country tap-target
              InkWell(
                onTap: _pickCountry,
                child: Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.md),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.controller.country.flag,
                        style: const TextStyle(fontSize: 20),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        widget.controller.country.dialCode,
                        style: AppTypography.bodyInput.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const PhosphorIcon(
                        PhosphorIconsThin.caretDown,
                        size: 14,
                        color: AppColors.accentMuted,
                      ),
                    ],
                  ),
                ),
              ),
              // Local number
              Expanded(
                child: TextField(
                  controller: _textController,
                  focusNode: _focusNode,
                  autofocus: widget.autofocus,
                  keyboardType: TextInputType.phone,
                  textInputAction: widget.textInputAction,
                  onSubmitted: widget.onSubmitted,
                  onChanged: (v) =>
                      widget.controller.setLocalNumber(v.replaceAll(' ', '')),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    _ThreeDigitGroupFormatter(),
                  ],
                  style: AppTypography.bodyInput.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Error
        if (widget.errorText != null) ...[
          const SizedBox(height: 6),
          Text(
            widget.errorText!,
            style: AppTypography.annotation.copyWith(
              color: AppColors.danger,
            ),
          ),
        ],
      ],
    );
  }
}

/// State holder for [LhotsePhoneField]. Notifies on country / number change
/// and composes the E.164 representation via [e164].
class LhotsePhoneController extends ChangeNotifier {
  LhotsePhoneController({Country initial = kDefaultCountry}) : _country = initial;

  Country _country;
  String _localNumber = '';

  Country get country => _country;
  String get localNumber => _localNumber;

  /// E.164 representation if the local number has 6–14 digits, else null.
  String? get e164 {
    final digits = _localNumber.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 6 || digits.length > 14) return null;
    return '${_country.dialCode}$digits';
  }

  void setCountry(Country c) {
    if (c.code == _country.code && c.dialCode == _country.dialCode) return;
    _country = c;
    notifyListeners();
  }

  void setLocalNumber(String digitsOnly) {
    if (digitsOnly == _localNumber) return;
    _localNumber = digitsOnly;
    notifyListeners();
  }

  void clear() {
    _localNumber = '';
    notifyListeners();
  }
}

/// Inserts a single space every 3 digits while preserving caret position.
class _ThreeDigitGroupFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');

    // Build the formatted string.
    final buf = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && i % 3 == 0) buf.write(' ');
      buf.write(digits[i]);
    }
    final formatted = buf.toString();

    // Place the caret after the same number of digits that preceded it
    // in the user's edit, accounting for the spaces that now appear.
    final rawCaret =
        newValue.selection.baseOffset.clamp(0, newValue.text.length);
    final digitsBefore = newValue.text
        .substring(0, rawCaret)
        .replaceAll(RegExp(r'\D'), '')
        .length;
    final spacesBefore = digitsBefore == 0 ? 0 : (digitsBefore - 1) ~/ 3;
    final newCaret = (digitsBefore + spacesBefore).clamp(0, formatted.length);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: newCaret),
    );
  }
}
