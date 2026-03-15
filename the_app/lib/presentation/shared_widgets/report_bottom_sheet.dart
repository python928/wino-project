import 'package:flutter/material.dart';

class ReportReason {
  final String value;
  final String label;

  const ReportReason(this.value, this.label);
}

class ReportResult {
  final String reason;
  final String details;

  const ReportResult({
    required this.reason,
    required this.details,
  });
}

class ReportBottomSheet {
  static Future<ReportResult?> show({
    required BuildContext context,
    required String title,
    required List<ReportReason> reasons,
    String detailsHint = 'Add details (optional)',
    String submitLabel = 'Send Report',
  }) async {
    if (reasons.isEmpty) return null;
    String selectedReason = reasons.first.value;
    final detailsController = TextEditingController();

    final result = await showModalBottomSheet<ReportResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
            ),
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: reasons.map((r) {
                    final selected = selectedReason == r.value;
                    return GestureDetector(
                      onTap: () =>
                          setModalState(() => selectedReason = r.value),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: selected
                              ? Colors.red.withOpacity(0.1)
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: selected
                                ? Colors.red.shade300
                                : Colors.grey.shade300,
                          ),
                        ),
                        child: Text(
                          r.label,
                          style: TextStyle(
                            color:
                                selected ? Colors.red.shade700 : Colors.black87,
                            fontWeight:
                                selected ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: detailsController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: detailsHint,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade500,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => Navigator.pop(
                      ctx,
                      ReportResult(
                        reason: selectedReason,
                        details: detailsController.text.trim(),
                      ),
                    ),
                    child: Text(submitLabel),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    detailsController.dispose();
    return result;
  }
}
