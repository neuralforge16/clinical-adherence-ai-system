import 'package:flutter/material.dart';
import '../core/api_service.dart';

class PatientRiskSummary extends StatefulWidget {
  const PatientRiskSummary({super.key});

  @override
  State<PatientRiskSummary> createState() => _PatientRiskSummaryState();
}

class _PatientRiskSummaryState extends State<PatientRiskSummary> {
  static const Color _primary = Color(0xFF1E4ED8);
  static const Color _green = Color(0xFF10B981);
  static const Color _amber = Color(0xFFF59E0B);
  static const Color _red = Color(0xFFEF4444);
  static const Color _mutedText = Color(0xFF6B7280);

  Map data = {};
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final result = await ApiService.getRiskSummary();
      if (mounted)
        setState(() {
          data = result;
          loading = false;
        });
    } catch (_) {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Inline loading — no separate _LoadingState class needed
    if (loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
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
              'Loading risk summary...',
              style: TextStyle(color: Color(0xFF6B7280), fontSize: 13),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Patient Risk Overview',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _kpiCard('Total', data['total'] ?? 0, _primary),
            const SizedBox(width: 10),
            _kpiCard('Stable', data['stable'] ?? 0, _green),
            const SizedBox(width: 10),
            _kpiCard('At Risk', data['risk'] ?? 0, _amber),
            const SizedBox(width: 10),
            _kpiCard('Critical', data['critical'] ?? 0, _red),
          ],
        ),
      ],
    );
  }

  Widget _kpiCard(String title, int value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Text(
              '$value',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
