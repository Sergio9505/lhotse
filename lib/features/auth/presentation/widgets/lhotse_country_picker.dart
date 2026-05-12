import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/data/countries.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/lhotse_bottom_sheet.dart';

/// Opens the country selector as a bottom sheet. Returns the picked
/// [Country] or null if dismissed.
Future<Country?> showLhotseCountryPicker(
  BuildContext context, {
  required Country selected,
}) {
  return showModalBottomSheet<Country>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.background,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
    ),
    builder: (_) => _CountryPickerSheet(selected: selected),
  );
}

class _CountryPickerSheet extends StatefulWidget {
  const _CountryPickerSheet({required this.selected});

  final Country selected;

  @override
  State<_CountryPickerSheet> createState() => _CountryPickerSheetState();
}

class _CountryPickerSheetState extends State<_CountryPickerSheet> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Country> get _filtered {
    // Selected country pinned on top; rest sorted by name with the query
    // applied to both name and dial code.
    final q = _query.trim().toLowerCase();
    final rest = kCountries.where((c) => c.code != widget.selected.code).where((c) {
      if (q.isEmpty) return true;
      return c.name.toLowerCase().contains(q) || c.dialCode.contains(q);
    }).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    final selectedMatches = q.isEmpty ||
        widget.selected.name.toLowerCase().contains(q) ||
        widget.selected.dialCode.contains(q);
    return [if (selectedMatches) widget.selected, ...rest];
  }

  @override
  Widget build(BuildContext context) {
    final items = _filtered;
    return LhotseBottomSheetBody(
      title: 'PAÍS',
      header: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.md,
        ),
        child: TextField(
          controller: _searchController,
          autofocus: false,
          textInputAction: TextInputAction.search,
          style: AppTypography.bodyInput.copyWith(
            color: AppColors.textPrimary,
          ),
          onChanged: (v) => setState(() => _query = v),
          decoration: InputDecoration(
            hintText: 'Buscar país…',
            hintStyle: AppTypography.bodyInput.copyWith(
              color: AppColors.accentMuted,
            ),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 8),
            prefixIcon: const Padding(
              padding: EdgeInsets.only(right: 8),
              child: PhosphorIcon(
                PhosphorIconsThin.magnifyingGlass,
                size: 20,
                color: AppColors.accentMuted,
              ),
            ),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 28,
              minHeight: 28,
            ),
            border: const UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.textPrimary, width: 0.5),
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                color: AppColors.textPrimary.withValues(alpha: 0.2),
                width: 0.5,
              ),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.textPrimary, width: 1),
            ),
            filled: false,
          ),
        ),
      ),
      bodyBuilder: (bottomPadding) {
        if (items.isEmpty) {
          return Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              bottomPadding + AppSpacing.lg,
            ),
            child: Text(
              'Ningún país coincide con "${_query.trim()}".',
              style: AppTypography.annotationParagraph.copyWith(
                color: AppColors.accentMuted,
              ),
            ),
          );
        }
        return ListView.separated(
          shrinkWrap: true,
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            bottomPadding + AppSpacing.md,
          ),
          itemCount: items.length,
          separatorBuilder: (_, _) => Container(
            height: 0.5,
            color: AppColors.textPrimary.withValues(alpha: 0.08),
          ),
          itemBuilder: (context, index) {
            final country = items[index];
            final isSelected = country.code == widget.selected.code;
            return InkWell(
              onTap: () => Navigator.of(context).pop(country),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Row(
                  children: [
                    Text(
                      country.flag,
                      style: const TextStyle(fontSize: 22),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        country.name,
                        style: AppTypography.bodyInput.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Text(
                      country.dialCode,
                      style: AppTypography.bodyInput.copyWith(
                        color: AppColors.accentMuted,
                      ),
                    ),
                    if (isSelected) ...[
                      const SizedBox(width: AppSpacing.sm),
                      const PhosphorIcon(
                        PhosphorIconsThin.check,
                        size: 18,
                        color: AppColors.textPrimary,
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
