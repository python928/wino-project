import 'package:flutter/material.dart';

import '../../../core/components/custom_modal_bottom_sheet.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/helpers.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../data/models/pack_model.dart';

Future<Pack?> showPackPickerBottomSheet(
  BuildContext context, {
  required List<Pack> packs,
  String title = 'Select Pack',
}) async {
  final result = await customModalBottomSheet(
    context,
    child: _PackPickerSheet(
      title: title,
      packs: packs,
    ),
  );

  if (result is Pack) return result;
  return null;
}

class _PackPickerSheet extends StatefulWidget {
  final String title;
  final List<Pack> packs;

  const _PackPickerSheet({
    required this.title,
    required this.packs,
  });

  @override
  State<_PackPickerSheet> createState() => _PackPickerSheetState();
}

class _PackPickerSheetState extends State<_PackPickerSheet> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim().toLowerCase();
    final filtered = query.isEmpty
        ? widget.packs
        : widget.packs
            .where((pack) => pack.name.toLowerCase().contains(query))
            .toList();

    return Directionality(
      textDirection: TextDirection.ltr,
      child: DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.55,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: AppSearchField(
                  controller: _searchController,
                  hintText: 'Search packs...',
                  compact: true,
                  onChanged: (_) => setState(() {}),
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? const Center(
                        child: Text(
                          'No packs found',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      )
                    : ListView.separated(
                        controller: scrollController,
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final pack = filtered[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.grey.shade200,
                              child: const Icon(
                                Icons.inventory_2_outlined,
                                color: Colors.grey,
                              ),
                            ),
                            title: Text(
                              pack.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              Helpers.formatPrice(pack.discountPrice),
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            onTap: () => Navigator.pop(context, pack),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
