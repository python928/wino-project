import 'package:flutter/material.dart';

import '../../core/config/api_config.dart';
import 'package:wino/core/extensions/l10n_extension.dart';
import '../../core/services/api_service.dart';

class MyFeedbackScreen extends StatefulWidget {
  const MyFeedbackScreen({super.key});

  @override
  State<MyFeedbackScreen> createState() => _MyFeedbackScreenState();
}

class _MyFeedbackScreenState extends State<MyFeedbackScreen> {
  bool _loading = true;
  String? _error;
  List<dynamic> _items = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await ApiService.get(ApiConfig.feedbackMy);
      final list = response is List
          ? response
          : (response is Map<String, dynamic> ? (response['results'] as List<dynamic>? ?? const []) : const []);
      if (!mounted) return;
      setState(() {
        _items = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'resolved':
        return Colors.green;
      case 'in_review':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.blueGrey;
    }
  }

  String _localizedStatus(String status) {
    final l10n = context.l10n;
    switch (status) {
      case 'resolved':
        return l10n.feedbackStatusResolved;
      case 'in_review':
        return l10n.feedbackStatusInReview;
      case 'rejected':
        return l10n.feedbackStatusRejected;
      case 'open':
      default:
        return l10n.feedbackStatusOpen;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.feedbackTitleMy)),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? ListView(
                    children: [
                      const SizedBox(height: 80),
                      Center(child: Text(l10n.feedbackLoadHistoryFailed)),
                      Center(child: Text(_error!, style: const TextStyle(fontSize: 12))),
                    ],
                  )
                : _items.isEmpty
                    ? ListView(
                        children: [
                          const SizedBox(height: 80),
                          Center(child: Text(l10n.feedbackEmpty)),
                        ],
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final item = _items[index] as Map<String, dynamic>;
                          final status = (item['status'] ?? 'open').toString();
                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          _mapType((item['type'] ?? 'feedback').toString()),
                                          style: const TextStyle(fontWeight: FontWeight.w700),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: _statusColor(status).withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          _localizedStatus(status),
                                          style: TextStyle(color: _statusColor(status)),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text((item['message'] ?? '').toString()),
                                  if ((item['admin_note'] ?? '').toString().trim().isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      l10n.feedbackAdminNotePrefix(
                                        (item['admin_note'] ?? '').toString(),
                                      ),
                                      style: const TextStyle(fontStyle: FontStyle.italic),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
      ),
    );
  }

  String _mapType(String type) {
    final l10n = context.l10n;
    switch (type) {
      case 'problem':
        return l10n.feedbackTypeProblem;
      case 'suggestion':
        return l10n.feedbackTypeSuggestion;
      default:
        return l10n.feedbackTypeDefault;
    }
  }
}
