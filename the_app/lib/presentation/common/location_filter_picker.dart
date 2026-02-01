import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/algeria_wilayas_baladiat.dart';
import '../../core/widgets/app_button.dart';

class LocationFilterResult {
  final List<String> selectedWilayas;
  final Map<String, List<String>> selectedBaladiyat; // wilaya -> list of baladiyat
  final bool allAlgeria;

  LocationFilterResult({
    required this.selectedWilayas,
    required this.selectedBaladiyat,
    this.allAlgeria = false,
  });

  bool get hasFilters => selectedWilayas.isNotEmpty || allAlgeria;

  String get displayText {
    if (allAlgeria) return 'All Algeria';
    if (selectedWilayas.isEmpty) return 'All Locations';

    // Check if any baladiyat are selected
    int totalBaladiyat = 0;
    for (final list in selectedBaladiyat.values) {
      totalBaladiyat += list.length;
    }

    if (totalBaladiyat > 0) {
      if (selectedWilayas.length == 1) {
        if (totalBaladiyat == 1) {
          return selectedBaladiyat.values.first.first;
        }
        return '$totalBaladiyat areas in ${selectedWilayas.first}';
      }
      return '$totalBaladiyat areas';
    }

    if (selectedWilayas.length == 1) return selectedWilayas.first;
    return '${selectedWilayas.length} wilayas';
  }
}

class LocationFilterPicker extends StatefulWidget {
  final LocationFilterResult? initialFilter;

  const LocationFilterPicker({super.key, this.initialFilter});

  @override
  State<LocationFilterPicker> createState() => _LocationFilterPickerState();
}

class _LocationFilterPickerState extends State<LocationFilterPicker> {
  Set<String> _selectedWilayas = {};
  Map<String, Set<String>> _selectedBaladiyat = {};
  bool _allAlgeria = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // For 2-step flow
  String? _currentWilaya; // null = showing wilayas, non-null = showing baladiyat

  List<String> get _wilayaList => algeriaWilayasBaladiat.keys.toList();

  List<String> get _filteredWilayaList {
    if (_searchQuery.isEmpty) return _wilayaList;
    return _wilayaList
        .where((w) => w.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  List<String> get _baladiyaList =>
      _currentWilaya != null ? algeriaWilayasBaladiat[_currentWilaya!] ?? [] : [];

  List<String> get _filteredBaladiyaList {
    if (_searchQuery.isEmpty) return _baladiyaList;
    return _baladiyaList
        .where((b) => b.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  @override
  void initState() {
    super.initState();
    if (widget.initialFilter != null) {
      _selectedWilayas = widget.initialFilter!.selectedWilayas.toSet();
      _allAlgeria = widget.initialFilter!.allAlgeria;
      for (final entry in widget.initialFilter!.selectedBaladiyat.entries) {
        _selectedBaladiyat[entry.key] = entry.value.toSet();
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _confirmFilter() {
    final baladiyatMap = <String, List<String>>{};
    for (final entry in _selectedBaladiyat.entries) {
      if (entry.value.isNotEmpty) {
        baladiyatMap[entry.key] = entry.value.toList();
      }
    }

    Navigator.pop(
      context,
      LocationFilterResult(
        selectedWilayas: _selectedWilayas.toList(),
        selectedBaladiyat: baladiyatMap,
        allAlgeria: _allAlgeria,
      ),
    );
  }

  void _clearFilters() {
    setState(() {
      _selectedWilayas.clear();
      _selectedBaladiyat.clear();
      _allAlgeria = false;
    });
  }

  void _goBack() {
    setState(() {
      _currentWilaya = null;
      _searchQuery = '';
      _searchController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.neutral300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(
              children: [
                if (_currentWilaya != null)
                  GestureDetector(
                    onTap: _goBack,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: AppColors.neutral100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.arrow_back, size: 18, color: AppColors.textPrimary),
                    ),
                  ),
                Icon(Icons.location_on_rounded, color: AppColors.primaryColor, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _currentWilaya ?? 'Filter by Location',
                    style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                if (_selectedWilayas.isNotEmpty || _allAlgeria)
                  GestureDetector(
                    onTap: _clearFilters,
                    child: Text(
                      'Clear',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.errorRed,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Search
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SizedBox(
              height: 44,
              child: AppSearchField(
                controller: _searchController,
                hintText: _currentWilaya == null ? 'Search wilayas...' : 'Search baladiyat...',
                onChanged: (value) => setState(() => _searchQuery = value),
                onClear: () => setState(() => _searchQuery = ''),
                compact: true,
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Selected wilayas chips (when viewing baladiyat)
          if (_currentWilaya != null && _selectedWilayas.contains(_currentWilaya))
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, size: 16, color: AppColors.primaryColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _selectedBaladiyat[_currentWilaya]?.isNotEmpty == true
                            ? '${_selectedBaladiyat[_currentWilaya]!.length} baladiyat selected'
                            : 'All baladiyat in $_currentWilaya',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 8),

          // List
          Expanded(
            child: _currentWilaya == null ? _buildWilayaList() : _buildBaladiyaList(),
          ),

          // Bottom Button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: AppPrimaryButton(
                  text: _getButtonText(),
                  onPressed: _confirmFilter,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getButtonText() {
    if (_allAlgeria) return 'Apply - All Algeria';
    if (_selectedWilayas.isEmpty) return 'Apply - All Locations';

    int totalBaladiyat = 0;
    for (final list in _selectedBaladiyat.values) {
      totalBaladiyat += list.length;
    }

    if (totalBaladiyat > 0) {
      return 'Apply - $totalBaladiyat areas in ${_selectedWilayas.length} wilayas';
    }
    return 'Apply - ${_selectedWilayas.length} wilayas';
  }

  Widget _buildWilayaList() {
    final wilayas = _filteredWilayaList;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        // All Algeria option
        _buildCompactItem(
          title: 'All Algeria',
          subtitle: '58 wilayas',
          isSelected: _allAlgeria,
          icon: Icons.public,
          onTap: () {
            setState(() {
              _allAlgeria = !_allAlgeria;
              if (_allAlgeria) {
                _selectedWilayas.clear();
                _selectedBaladiyat.clear();
              }
            });
          },
        ),

        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Divider(height: 1, color: AppColors.neutral200),
        ),

        // Wilayas - simple compact list
        ...wilayas.asMap().entries.map((entry) {
          final index = entry.key;
          final wilaya = entry.value;
          final isSelected = _selectedWilayas.contains(wilaya);
          final baladiyatCount = algeriaWilayasBaladiat[wilaya]?.length ?? 0;
          final selectedBaladiyatCount = _selectedBaladiyat[wilaya]?.length ?? 0;

          return _buildCompactWilayaItem(
            index: index + 1,
            wilaya: wilaya,
            baladiyatCount: baladiyatCount,
            selectedBaladiyatCount: selectedBaladiyatCount,
            isSelected: isSelected,
            isDisabled: _allAlgeria,
            onCheckTap: _allAlgeria
                ? null
                : () {
                    setState(() {
                      if (isSelected) {
                        _selectedWilayas.remove(wilaya);
                        _selectedBaladiyat.remove(wilaya);
                      } else {
                        _selectedWilayas.add(wilaya);
                      }
                    });
                  },
            onDetailTap: () {
              setState(() {
                _currentWilaya = wilaya;
                _searchQuery = '';
                _searchController.clear();
              });
            },
          );
        }),

        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildCompactItem({
    required String title,
    required String subtitle,
    required bool isSelected,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryColor.withOpacity(0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: isSelected ? AppColors.primaryColor : AppColors.textSecondary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isSelected ? AppColors.primaryColor : AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: AppTextStyles.caption.copyWith(color: AppColors.textTertiary),
                  ),
                ],
              ),
            ),
            _buildCheckbox(isSelected),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactWilayaItem({
    required int index,
    required String wilaya,
    required int baladiyatCount,
    required int selectedBaladiyatCount,
    required bool isSelected,
    required bool isDisabled,
    VoidCallback? onCheckTap,
    required VoidCallback onDetailTap,
  }) {
    return Opacity(
      opacity: isDisabled ? 0.4 : 1.0,
      child: Container(
        margin: const EdgeInsets.only(bottom: 2),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryColor.withOpacity(0.05) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            // Checkbox
            GestureDetector(
              onTap: onCheckTap,
              child: _buildCheckbox(isSelected),
            ),
            const SizedBox(width: 10),

            // Number
            Container(
              width: 24,
              height: 24,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.neutral100,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '$index',
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(width: 10),

            // Name & count
            Expanded(
              child: GestureDetector(
                onTap: onDetailTap,
                behavior: HitTestBehavior.opaque,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        wilaya,
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected ? AppColors.primaryColor : AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (selectedBaladiyatCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        margin: const EdgeInsets.only(right: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$selectedBaladiyatCount',
                          style: AppTextStyles.caption.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    Text(
                      '$baladiyatCount',
                      style: AppTextStyles.caption.copyWith(color: AppColors.textTertiary),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.chevron_right, size: 16, color: AppColors.textTertiary),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckbox(bool isSelected) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primaryColor : Colors.transparent,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isSelected ? AppColors.primaryColor : AppColors.neutral300,
          width: 1.5,
        ),
      ),
      child: isSelected
          ? const Icon(Icons.check, color: Colors.white, size: 14)
          : null,
    );
  }

  Widget _buildBaladiyaList() {
    final baladiyat = _filteredBaladiyaList;
    final selectedSet = _selectedBaladiyat[_currentWilaya] ?? {};
    final wilayaSelected = _selectedWilayas.contains(_currentWilaya);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        // Select/Deselect all for this wilaya
        GestureDetector(
          onTap: () {
            setState(() {
              if (wilayaSelected) {
                _selectedWilayas.remove(_currentWilaya);
                _selectedBaladiyat.remove(_currentWilaya);
              } else {
                _selectedWilayas.add(_currentWilaya!);
              }
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: wilayaSelected ? AppColors.primaryColor.withOpacity(0.08) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.select_all,
                  size: 18,
                  color: wilayaSelected ? AppColors.primaryColor : AppColors.textSecondary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    wilayaSelected ? 'Deselect $_currentWilaya' : 'Select all $_currentWilaya',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: wilayaSelected ? AppColors.primaryColor : AppColors.textPrimary,
                    ),
                  ),
                ),
                _buildCheckbox(wilayaSelected),
              ],
            ),
          ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Divider(height: 1, color: AppColors.neutral200),
        ),

        // Individual baladiyat
        ...baladiyat.map((baladiya) {
          final isSelected = selectedSet.contains(baladiya);

          return GestureDetector(
            onTap: wilayaSelected
                ? () {
                    setState(() {
                      _selectedBaladiyat[_currentWilaya!] ??= {};
                      if (isSelected) {
                        _selectedBaladiyat[_currentWilaya!]!.remove(baladiya);
                      } else {
                        _selectedBaladiyat[_currentWilaya!]!.add(baladiya);
                      }
                    });
                  }
                : null,
            child: Opacity(
              opacity: wilayaSelected ? 1.0 : 0.4,
              child: Container(
                margin: const EdgeInsets.only(bottom: 2),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.successGreen.withOpacity(0.08) : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.successGreen : Colors.transparent,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: isSelected ? AppColors.successGreen : AppColors.neutral300,
                          width: 1.5,
                        ),
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, color: Colors.white, size: 14)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        baladiya,
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected ? AppColors.successGreen : AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),

        const SizedBox(height: 16),

        // Hint text
        if (!wilayaSelected)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.warningAmber.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: AppColors.warningAmber),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Select the wilaya first to choose specific baladiyat',
                    style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),

        const SizedBox(height: 16),
      ],
    );
  }
}
