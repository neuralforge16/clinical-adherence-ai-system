import 'package:flutter/material.dart';
import '../core/api_service.dart';

class AIRiskPredictionPanel extends StatefulWidget {
  const AIRiskPredictionPanel({super.key});

  @override
  State<AIRiskPredictionPanel> createState() => _AIRiskPredictionPanelState();
}

class _AIRiskPredictionPanelState extends State<AIRiskPredictionPanel> {
  static const Color _primary = Color(0xFF1E4ED8);
  static const Color _green = Color(0xFF10B981);
  static const Color _amber = Color(0xFFF59E0B);
  static const Color _red = Color(0xFFEF4444);
  static const Color _mutedText = Color(0xFF6B7280);

  List _predictions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await ApiService.getRiskPredictions();
      if (mounted)
        setState(() {
          _predictions = data;
          _loading = false;
        });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Color _riskColor(String risk) {
    switch (risk) {
      case 'HIGH':
        return _red;
      case 'MEDIUM':
        return _amber;
      default:
        return _green;
    }
  }

  Color _riskBg(String risk) {
    switch (risk) {
      case 'HIGH':
        return const Color(0xFFFEF2F2);
      case 'MEDIUM':
        return const Color(0xFFFFFBEB);
      default:
        return const Color(0xFFF0FDF4);
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
              'Loading predictions...',
              style: TextStyle(color: Color(0xFF6B7280), fontSize: 13),
            ),
          ],
        ),
      );
    }

    if (_predictions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F7FB),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Row(
          children: [
            Icon(Icons.insights, color: Color(0xFF6B7280), size: 18),
            SizedBox(width: 10),
            Text(
              'No predictions available yet.',
              style: TextStyle(color: Color(0xFF6B7280), fontSize: 13),
            ),
          ],
        ),
      );
    }

    final top = _predictions.first;
    final risk = (top['risk'] ?? 'LOW').toString();
    final color = _riskColor(risk);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        // Design system tint based on risk level, not raw Colors.*
        color: _riskBg(risk),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.25)),
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
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.insights, color: color, size: 16),
              ),
              const SizedBox(width: 10),
              const Text(
                'AI Risk Prediction',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: Text(
                  top['patient']?.toString() ?? '',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  risk,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Text(
            top['reason']?.toString() ?? '',
            style: const TextStyle(
              fontSize: 13,
              height: 1.5,
              color: _mutedText,
            ),
          ),
        ],
      ),
    );
  }
}
