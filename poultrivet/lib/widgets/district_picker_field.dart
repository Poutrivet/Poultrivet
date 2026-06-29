import 'package:flutter/material.dart';
import '../data/districts.dart';
import '../core/theme.dart';

/// A tappable field that opens a searchable district picker bottom sheet.
/// Usage:
///   DistrictPickerField(
///     value: _selectedDistrict,
///     onChanged: (d) => setState(() => _selectedDistrict = d),
///   )
class DistrictPickerField extends StatelessWidget {
  final String? value;
  final ValueChanged<String> onChanged;
  final String? errorText;

  const DistrictPickerField({
    super.key,
    required this.value,
    required this.onChanged,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => _openPicker(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: PoulvetTheme.lightBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: errorText != null
                    ? PoulvetTheme.error
                    : value != null
                        ? PoulvetTheme.primary
                        : PoulvetTheme.border,
                width: value != null ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  color: value != null
                      ? PoulvetTheme.primary
                      : PoulvetTheme.textGrey,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    value ?? 'Select District',
                    style: TextStyle(
                      fontSize: 14,
                      color: value != null
                          ? PoulvetTheme.textDark
                          : PoulvetTheme.textGrey.withOpacity(0.7),
                    ),
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: PoulvetTheme.textGrey,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(
              errorText!,
              style: const TextStyle(
                  color: PoulvetTheme.error, fontSize: 12),
            ),
          ),
      ],
    );
  }

  void _openPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DistrictPickerSheet(
        selected: value,
        onPicked: (district) {
          Navigator.pop(context);
          onChanged(district);
        },
      ),
    );
  }
}

// ─── Bottom sheet with search ─────────────────────────────────────────────────
class _DistrictPickerSheet extends StatefulWidget {
  final String? selected;
  final ValueChanged<String> onPicked;

  const _DistrictPickerSheet({
    required this.selected,
    required this.onPicked,
  });

  @override
  State<_DistrictPickerSheet> createState() => _DistrictPickerSheetState();
}

class _DistrictPickerSheetState extends State<_DistrictPickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<String> _filtered = ugandaDistricts;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearch);
  }

  void _onSearch() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      if (query.isEmpty) {
        _filtered = ugandaDistricts;
      } else {
        // Prioritize: starts with query first, then contains
        final startsWith = ugandaDistricts
            .where((d) => d.toLowerCase().startsWith(query))
            .toList();
        final contains = ugandaDistricts
            .where((d) =>
                d.toLowerCase().contains(query) &&
                !d.toLowerCase().startsWith(query))
            .toList();
        _filtered = [...startsWith, ...contains];
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: PoulvetTheme.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Title
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Select Your District',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: PoulvetTheme.textDark,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Search field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Search district...',
                hintStyle: TextStyle(
                    color: PoulvetTheme.textGrey.withOpacity(0.6),
                    fontSize: 14),
                prefixIcon: const Icon(Icons.search,
                    color: PoulvetTheme.primary, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? GestureDetector(
                        onTap: () {
                          _searchController.clear();
                        },
                        child: const Icon(Icons.close,
                            color: PoulvetTheme.textGrey, size: 18),
                      )
                    : null,
                filled: true,
                fillColor: PoulvetTheme.lightBg,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: PoulvetTheme.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: PoulvetTheme.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: PoulvetTheme.primary, width: 2),
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Results count
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Row(
              children: [
                Text(
                  '${_filtered.length} district${_filtered.length != 1 ? 's' : ''}',
                  style: const TextStyle(
                      fontSize: 12, color: PoulvetTheme.textGrey),
                ),
              ],
            ),
          ),

          // List
          Expanded(
            child: _filtered.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.search_off,
                            color: PoulvetTheme.border, size: 48),
                        SizedBox(height: 12),
                        Text(
                          'No district found',
                          style: TextStyle(color: PoulvetTheme.textGrey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _filtered.length,
                    itemBuilder: (context, index) {
                      final district = _filtered[index];
                      final isSelected = district == widget.selected;
                      final query =
                          _searchController.text.toLowerCase().trim();

                      return ListTile(
                        onTap: () => widget.onPicked(district),
                        leading: Icon(
                          isSelected
                              ? Icons.check_circle_rounded
                              : Icons.location_city_outlined,
                          color: isSelected
                              ? PoulvetTheme.primary
                              : PoulvetTheme.textGrey,
                          size: 22,
                        ),
                        title: query.isEmpty
                            ? Text(
                                district,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                  color: isSelected
                                      ? PoulvetTheme.primary
                                      : PoulvetTheme.textDark,
                                ),
                              )
                            : _HighlightedText(
                                text: district,
                                query: query,
                                isSelected: isSelected,
                              ),
                        tileColor: isSelected
                            ? PoulvetTheme.primary.withOpacity(0.05)
                            : null,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ─── Highlights matching text in green ───────────────────────────────────────
class _HighlightedText extends StatelessWidget {
  final String text;
  final String query;
  final bool isSelected;

  const _HighlightedText({
    required this.text,
    required this.query,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    final lowerText = text.toLowerCase();
    final matchIndex = lowerText.indexOf(query);

    if (matchIndex == -1) {
      return Text(text,
          style: TextStyle(
            fontSize: 15,
            color: isSelected ? PoulvetTheme.primary : PoulvetTheme.textDark,
          ));
    }

    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontSize: 15,
          color: isSelected ? PoulvetTheme.primary : PoulvetTheme.textDark,
          fontWeight:
              isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
        children: [
          if (matchIndex > 0)
            TextSpan(text: text.substring(0, matchIndex)),
          TextSpan(
            text: text.substring(matchIndex, matchIndex + query.length),
            style: const TextStyle(
              color: PoulvetTheme.primary,
              fontWeight: FontWeight.bold,
              backgroundColor: Color(0x2219e16c),
            ),
          ),
          if (matchIndex + query.length < text.length)
            TextSpan(
                text: text.substring(matchIndex + query.length)),
        ],
      ),
    );
  }
}
