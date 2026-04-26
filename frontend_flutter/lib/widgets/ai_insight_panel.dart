import 'package:flutter/material.dart';
import '../core/api_service.dart';

class AIInsightPanel extends StatefulWidget {
  const AIInsightPanel({super.key});

  @override
  State<AIInsightPanel> createState() => _AIInsightPanelState();
}

class _AIInsightPanelState extends State<AIInsightPanel> {
  static const Color _primary = Color(0xFF1E4ED8);
  static const Color _mutedText = Color(0xFF6B7280);

  List _insights = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await ApiService.getAIInsights();
      if (mounted)
        setState(() {
          _insights = data;
          _loading = false;
        });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Consistent loading state
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text(
              'Loading insights...',
              style: TextStyle(color: Color(0xFF6B7280), fontSize: 13),
            ),
          ],
        ),
      );
    }

    if (_insights.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F7FB),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Row(
          children: [
            Icon(Icons.lightbulb_outline, color: Color(0xFF6B7280), size: 18),
            SizedBox(width: 10),
            Text(
              'No AI insights available yet.',
              style: TextStyle(color: Color(0xFF6B7280), fontSize: 13),
            ),
          ],
        ),
      );
    }

    final insight = _insights.first;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        // Design system: primary tint instead of Colors.blue.shade50
        color: _primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _primary.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: _primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.lightbulb_outline,
                  color: _primary,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'AI Clinical Insight',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            insight['insight']?.toString() ?? '',
            style: const TextStyle(
              fontSize: 13,
              height: 1.6,
              color: Color(0xFF1A1A1A),
            ),
          ),
        ],
      ),
    );
  }
}
