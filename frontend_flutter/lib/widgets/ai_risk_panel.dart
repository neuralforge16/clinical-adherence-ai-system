import 'package:flutter/material.dart';
import '../core/api_service.dart';

class AIRiskPanel extends StatelessWidget {
  const AIRiskPanel({super.key});

  static const Color _primary = Color(0xFF1E4ED8);
  static const Color _green = Color(0xFF10B981);
  static const Color _amber = Color(0xFFF59E0B);
  static const Color _red = Color(0xFFEF4444);
  static const Color _mutedText = Color(0xFF6B7280);

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

  Color _arrowColor(int adherence) {
    if (adherence < 60) return _red;
    if (adherence < 85) return _amber;
    return _green;
  }

  IconData _arrowIcon(int adherence) {
    if (adherence < 60) return Icons.arrow_downward;
    if (adherence < 85) return Icons.remove;
    return Icons.arrow_upward;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            blurRadius: 12,
            color: Color.fromRGBO(0, 0, 0, 0.06),
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.psychology, color: _primary, size: 18),
              ),
              const SizedBox(width: 10),
              const Text(
                'AI Risk Assessment',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          FutureBuilder(
            future: ApiService.getRiskPredictions(),
            builder: (context, snapshot) {
              // Consistent loading state
              if (!snapshot.hasData) {
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
                        'Loading risk data...',
                        style: TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                );
              }

              final data = snapshot.data as List;

              if (data.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _green.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _green.withOpacity(0.25)),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        color: Color(0xFF10B981),
                        size: 18,
                      ),
                      SizedBox(width: 10),
                      Text(
                        'No active risks detected',
                        style: TextStyle(
                          color: Color(0xFF065F46),
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return Column(
                children: data.map<Widget>((p) {
                  final risk = (p['risk'] ?? 'LOW').toString();
                  final reason = (p['reason'] ?? '').toString();
                  final adherence = (p['adherence'] ?? 0) as int;
                  final color = _riskColor(risk);
                  final aColor = _arrowColor(adherence);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F7FB),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.warning_amber_rounded,
                            color: color,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p['patient']?.toString() ?? '',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: Color(0xFF1A1A1A),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                reason,
                                style: const TextStyle(
                                  color: _mutedText,
                                  fontSize: 12,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                risk,
                                style: TextStyle(
                                  color: color,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                color: aColor.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _arrowIcon(adherence),
                                size: 14,
                                color: aColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
