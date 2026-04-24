import 'package:wino/core/extensions/l10n_extension.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_constants.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../data/models/category_model.dart';

class CategorySelectionScreen extends StatefulWidget {
  final List<Category> categories;
  final Set<int> initialSelectedCategoryIds;
  final bool singleSelection;
  final int? maxSelection;
  final int minSelection;
  final String? title;
  final String? subtitle;
  final String? confirmText;
  final String? searchHintText;
  final String? emptyMessage;
  final bool? showSelectionPreview;

  const CategorySelectionScreen({
    super.key,
    required this.categories,
    required this.initialSelectedCategoryIds,
    this.singleSelection = false,
    this.maxSelection,
    this.minSelection = 0,
    this.title,
    this.subtitle,
    this.confirmText,
    this.searchHintText,
    this.emptyMessage,
    this.showSelectionPreview,
  });

  @override
  State<CategorySelectionScreen> createState() =>
      _CategorySelectionScreenState();
}

class _CategorySelectionScreenState extends State<CategorySelectionScreen> {
  final TextEditingController _searchController = TextEditingController();

  late Set<int> _selectedIds;
  String _query = '';

  bool get _hasActiveQuery => _query.trim().isNotEmpty;
  bool get _canConfirm => _selectedIds.length >= widget.minSelection;
  bool get _showSelectionPreview =>
      widget.showSelectionPreview ?? !widget.singleSelection;

  List<Category> get _selectedCategories {
    return widget.categories
        .where((category) => _selectedIds.contains(category.id))
        .toList(growable: false);
  }

  @override
  void initState() {
    super.initState();
    _selectedIds = {...widget.initialSelectedCategoryIds};
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Category> get _filteredCategories {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return widget.categories;
    return widget.categories
        .where((c) => c.name.toLowerCase().contains(q))
        .toList();
  }

  void _clearSelection() {
    if (_selectedIds.isEmpty) {
      return;
    }
    setState(() => _selectedIds.clear());
  }

  void _toggle(int id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        if (widget.singleSelection) {
          _selectedIds = {id};
        } else if (widget.maxSelection != null &&
            _selectedIds.length >= widget.maxSelection!) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                context.l10n.categoriesPickerMaxReached(widget.maxSelection!),
              ),
            ),
          );
        } else {
          _selectedIds.add(id);
        }
      }
    });
  }

  /// Colour palette — same as search screen cards so the icons look consistent
  static const List<Color> _palette = [
    Color(0xFFFF9800),
    Color(0xFF2196F3),
    Color(0xFF9C27B0),
    Color(0xFFE91E63),
    Color(0xFF4CAF50),
    Color(0xFFFF5722),
    Color(0xFF009688),
    Color(0xFF3F51B5),
  ];

  Color _colorFor(int index) => _palette[index % _palette.length];

  @override
  Widget build(BuildContext context) {
    final categories = _filteredCategories;
    final selectedCountLabel = context.l10n.categoriesPickerSelectionCount(
      _selectedIds.length,
      widget.maxSelection ?? widget.categories.length,
    );
    final helperText = !_canConfirm && widget.minSelection > 0
        ? context.l10n.categoriesPickerMinRequired(widget.minSelection)
        : widget.maxSelection != null
            ? context.l10n.categoriesPickerMaxHint(widget.maxSelection!)
            : null;
    final resolvedTitle = widget.title ??
        (widget.singleSelection
            ? context.tr('Select Category')
            : context.tr('Categories'));
    final resolvedSearchHint =
        widget.searchHintText ?? context.tr('Search categories...');
    final resolvedEmptyMessage =
        widget.emptyMessage ?? context.tr('No categories found');

    return Scaffold(
      backgroundColor: AppColors.surfaceSecondary,
      appBar: AppBar(
        backgroundColor: AppColors.surfacePrimary,
        elevation: 0.5,
        title: Text(
          resolvedTitle,
          style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.blackColor),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_selectedIds.isNotEmpty)
            TextButton(
              onPressed: _clearSelection,
              child: Text(
                context.tr('Clear'),
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          const SizedBox(width: AppConstants.spacing8),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: AppColors.surfacePrimary,
            padding: const EdgeInsets.fromLTRB(
              AppConstants.spacing16,
              AppConstants.spacing12,
              AppConstants.spacing16,
              AppConstants.spacing12,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.subtitle != null) ...[
                  Text(
                    widget.subtitle!,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacing12),
                ],
                AppSearchField(
                  controller: _searchController,
                  hintText: resolvedSearchHint,
                  onChanged: (v) => setState(() => _query = v),
                  onClear: () {
                    setState(() {
                      _query = '';
                    });
                  },
                ),
                if (widget.maxSelection != null ||
                    _selectedIds.isNotEmpty ||
                    _hasActiveQuery) ...[
                  const SizedBox(height: AppConstants.spacing10),
                  Text(
                    selectedCountLabel,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                if (_showSelectionPreview && _selectedIds.isNotEmpty) ...[
                  const SizedBox(height: AppConstants.spacing10),
                  _SelectedCategoryPreview(
                    categories: _selectedCategories,
                    onRemove: _toggle,
                  ),
                ],
                if (helperText != null) ...[
                  const SizedBox(height: AppConstants.spacing10),
                  Text(
                    helperText,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: _canConfirm
                          ? AppColors.textSecondary
                          : AppColors.errorRed,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: AppConstants.shortDuration,
              child: categories.isEmpty
                  ? _CategoryEmptyState(
                      key: ValueKey<String>(_query.trim()),
                      hasQuery: _hasActiveQuery,
                      message: resolvedEmptyMessage,
                      onClearQuery: _hasActiveQuery
                          ? () {
                              _searchController.clear();
                              setState(() => _query = '');
                            }
                          : null,
                    )
                  : ListView(
                      key: const ValueKey<String>('categories-list'),
                      padding: const EdgeInsets.all(AppConstants.spacing16),
                      children: [
                        Wrap(
                          spacing: AppConstants.spacing10,
                          runSpacing: AppConstants.spacing10,
                          children: List.generate(categories.length, (i) {
                            final category = categories[i];
                            final isSelected = _selectedIds.contains(
                              category.id,
                            );
                            final color = _colorFor(
                              // Keep color index stable by matching the global list.
                              widget.categories.indexOf(category),
                            );
                            return _buildCategoryChip(
                              category: category,
                              color: color,
                              isSelected: isSelected,
                              onTap: () => _toggle(category.id),
                            );
                          }),
                        ),
                      ],
                    ),
            ),
          ),
          Container(
            color: AppColors.surfacePrimary,
            padding: const EdgeInsets.fromLTRB(
              AppConstants.spacing16,
              AppConstants.spacing12,
              AppConstants.spacing16,
              AppConstants.spacing16,
            ),
            child: SafeArea(
              top: false,
              child: AppPrimaryButton(
                text: widget.confirmText ?? context.tr('Confirm'),
                icon: Icons.check_circle_outline_rounded,
                onPressed: _canConfirm
                    ? () => Navigator.pop<Set<int>>(context, _selectedIds)
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip({
    required Category category,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Semantics(
      button: true,
      selected: isSelected,
      label: category.name,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppConstants.radiusRound),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            constraints: const BoxConstraints(minHeight: 44),
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.spacing12,
              vertical: AppConstants.spacing10,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? color.withValues(alpha: 0.10)
                  : AppColors.surfacePrimary,
              borderRadius: BorderRadius.circular(AppConstants.radiusRound),
              border: Border.all(
                color: isSelected ? color : AppColors.borderPrimary,
                width: isSelected ? 1.5 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: isSelected ? 0.18 : 0.10),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(category.iconData, size: 15, color: color),
                ),
                const SizedBox(width: AppConstants.spacing8),
                Flexible(
                  child: Text(
                    category.name,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w600,
                      color: isSelected ? color : AppColors.textPrimary,
                    ),
                  ),
                ),
                if (isSelected) ...[
                  const SizedBox(width: AppConstants.spacing6),
                  Icon(
                    Icons.check_rounded,
                    size: AppConstants.iconSmall,
                    color: color,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectedCategoryPreview extends StatelessWidget {
  final List<Category> categories;
  final ValueChanged<int> onRemove;

  const _SelectedCategoryPreview({
    required this.categories,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final category = categories[index];
          return Container(
            decoration: BoxDecoration(
              color: AppColors.primaryLightShade,
              borderRadius: BorderRadius.circular(AppConstants.radiusRound),
              border: Border.all(color: AppColors.borderPurple),
            ),
            padding: const EdgeInsetsDirectional.only(
              start: AppConstants.spacing10,
              end: AppConstants.spacing6,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  category.name,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: AppConstants.spacing4),
                InkWell(
                  onTap: () => onRemove(category.id),
                  customBorder: const CircleBorder(),
                  child: const Padding(
                    padding: EdgeInsets.all(AppConstants.spacing4),
                    child: Icon(
                      Icons.close_rounded,
                      size: AppConstants.iconSmall,
                      color: AppColors.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        separatorBuilder: (_, __) =>
            const SizedBox(width: AppConstants.spacing8),
        itemCount: categories.length,
      ),
    );
  }
}

class _CategoryEmptyState extends StatelessWidget {
  final bool hasQuery;
  final String message;
  final VoidCallback? onClearQuery;

  const _CategoryEmptyState({
    super.key,
    required this.hasQuery,
    required this.message,
    this.onClearQuery,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacing24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surfaceTertiary,
              ),
              child: const Icon(
                Icons.search_off_rounded,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppConstants.spacing12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            if (hasQuery && onClearQuery != null) ...[
              const SizedBox(height: AppConstants.spacing12),
              TextButton.icon(
                onPressed: onClearQuery,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(context.tr('Clear')),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
