import 'package:dzlocal_shop/core/extensions/l10n_extension.dart';
import 'package:flutter/material.dart';

import '../../core/constants/algeria_wilayas_baladiat.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_button.dart';

class LocationResult {
  final String wilaya;
  final String baladiya;
  final String address;

  LocationResult({
    required this.wilaya,
    required this.baladiya,
    required this.address,
  });
}

class LocationPickerScreen extends StatefulWidget {
  final String? initialWilaya;
  final String? initialBaladiya;

  const LocationPickerScreen({
    super.key,
    this.initialWilaya,
    this.initialBaladiya,
  });

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  String? _selectedWilaya;
  String? _selectedBaladiya;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  List<String> get _wilayaList => algeriaWilayasBaladiat.keys.toList();

  List<String> get _filteredWilayaList {
    if (_searchQuery.isEmpty) return _wilayaList;
    return _wilayaList
        .where((w) => w.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  List<String> get _baladiyaList => _selectedWilaya != null
      ? algeriaWilayasBaladiat[_selectedWilaya!] ?? []
      : [];

  List<String> get _filteredBaladiyaList {
    if (_searchQuery.isEmpty) return _baladiyaList;
    return _baladiyaList
        .where((b) => b.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _selectedWilaya = widget.initialWilaya;
    _selectedBaladiya = widget.initialBaladiya;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _confirmLocation() {
    if (_selectedWilaya == null || _selectedBaladiya == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('Please select wilaya and baladiya')),
          backgroundColor: AppColors.errorRed,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    final address =
        '${context.tr(_selectedBaladiya!)}, ${context.tr(_selectedWilaya!)}';
    Navigator.pop(
      context,
      LocationResult(
        wilaya: _selectedWilaya!,
        baladiya: _selectedBaladiya!,
        address: address,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: Directionality.of(context),
      child: Scaffold(
        backgroundColor: AppColors.backgroundLight,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 18,
              color: AppColors.textPrimary,
            ),
            onPressed: () {
              if (_selectedWilaya != null && _selectedBaladiya == null) {
                setState(() {
                  _selectedWilaya = null;
                  _searchQuery = '';
                  _searchController.clear();
                });
              } else {
                Navigator.pop(context);
              }
            },
          ),
          title: Text(
            _selectedWilaya == null
                ? context.tr('Select Wilaya')
                : context.tr('Select Baladiya'),
            style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w700),
          ),
          centerTitle: true,
        ),
        body: Column(
          children: [
            // Search bar
            Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.neutral200),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _searchQuery = value),
                style: AppTextStyles.bodyMedium,
                decoration: InputDecoration(
                  hintText: _selectedWilaya == null
                      ? context.tr('Search wilaya...')
                      : context.tr('Search baladiya...'),
                  hintStyle: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.textTertiary),
                  prefixIcon: Icon(Icons.search,
                      color: AppColors.textSecondary, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.close,
                              color: AppColors.textSecondary, size: 18),
                          onPressed: () {
                            setState(() {
                              _searchQuery = '';
                              _searchController.clear();
                            });
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),

            // Selected wilaya chip (when selecting baladiya)
            if (_selectedWilaya != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.location_city,
                              size: 16, color: AppColors.primaryColor),
                          const SizedBox(width: 6),
                          Text(
                            context.tr(_selectedWilaya!),
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedWilaya = null;
                                _selectedBaladiya = null;
                                _searchQuery = '';
                                _searchController.clear();
                              });
                            },
                            child: Icon(Icons.close,
                                size: 16, color: AppColors.primaryColor),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 8),

            // List
            Expanded(
              child: _selectedWilaya == null
                  ? _buildWilayaList()
                  : _buildBaladiyaList(),
            ),

            // Confirm button (only show when both selected)
            if (_selectedWilaya != null && _selectedBaladiya != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadowLight,
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: AppPrimaryButton(
                    text:
                        '${context.tr(_selectedBaladiya!)}, ${context.tr(_selectedWilaya!)}',
                    onPressed: _confirmLocation,
                    icon: Icons.check_circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildWilayaList() {
    final wilayas = _filteredWilayaList;

    if (wilayas.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 48, color: AppColors.textTertiary),
            const SizedBox(height: 12),
            Text(context.tr('No wilaya found'),
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: wilayas.length,
      itemBuilder: (context, index) {
        final wilaya = wilayas[index];
        final baladiyaCount = algeriaWilayasBaladiat[wilaya]?.length ?? 0;

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedWilaya = wilaya;
                  _selectedBaladiya = null;
                  _searchQuery = '';
                  _searchController.clear();
                });
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.neutral200),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.primaryColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr(wilaya),
                            style: AppTextStyles.bodyMedium
                                .copyWith(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            '$baladiyaCount ${context.tr('baladiyat')}',
                            style: AppTextStyles.bodySmall
                                .copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_back_ios,
                        size: 14, color: AppColors.textTertiary),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBaladiyaList() {
    final baladiyat = _filteredBaladiyaList;

    if (baladiyat.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 48, color: AppColors.textTertiary),
            const SizedBox(height: 12),
            Text(context.tr('No baladiya found'),
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: baladiyat.length,
      itemBuilder: (context, index) {
        final baladiya = baladiyat[index];
        final isSelected = _selectedBaladiya == baladiya;

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          child: Material(
            color: isSelected
                ? AppColors.successGreen.withValues(alpha: 0.1)
                : Colors.white,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: () => setState(() => _selectedBaladiya = baladiya),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.successGreen
                        : AppColors.neutral200,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.successGreen.withValues(alpha: 0.2)
                            : AppColors.neutral100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Icon(
                          isSelected ? Icons.check : Icons.location_city,
                          color: isSelected
                              ? AppColors.successGreen
                              : AppColors.textSecondary,
                          size: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        context.tr(baladiya),
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected
                              ? AppColors.successGreen
                              : AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (isSelected)
                      Icon(Icons.check_circle,
                          color: AppColors.successGreen, size: 20),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
