import 'package:flutter/material.dart';
import '../core/api_service.dart';

class TopRiskCard extends StatelessWidget {
  const TopRiskCard({super.key});

  // ── Feature 12: design system colors ──────────────────────────────────────
  Color _riskColor(String risk) {
    switch (risk) {
      case 'HIGH':
        return const Color(0xFFEF4444);
      case 'MEDIUM':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF10B981);
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

  Color _riskBorder(String risk) {
    switch (risk) {
      case 'HIGH':
        return const Color(0xFFFCA5A5);
      case 'MEDIUM':
        return const Color(0xFFFCD34D);
      default:
        return const Color(0xFF6EE7B7);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: ApiService.getTopRiskPatient(),
      builder: (context, snapshot) {
        // ── Feature 13: consistent loading state ───────────────────────────
        if (!snapshot.hasData) {
          return const SizedBox(
            height: 56,
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Loading risk data...',
                    style: TextStyle(color: Color(0xFF6B7280), fontSize: 13),
                  ),
                ],
              ),
            ),
          );
        }

        final data = snapshot.data;
        if (data == null || (data is Map && data.isEmpty)) {
          return const SizedBox();
        }

        final risk = (data['risk'] ?? 'LOW').toString();
        final patient = (data['patient'] ?? '').toString();
        final adherence = data['adherence'];

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: _riskBg(risk),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _riskBorder(risk)),
          ),
          child: Row(
            children: [
              Icon(
                risk == 'HIGH'
                    ? Icons.error_outline
                    : risk == 'MEDIUM'
                    ? Icons.warning_amber_rounded
                    : Icons.check_circle_outline,
                color: _riskColor(risk),
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF1A1A1A),
                    ),
                    children: [
                      const TextSpan(
                        text: 'Top Risk: ',
                        style: TextStyle(color: Color(0xFF6B7280)),
                      ),
                      TextSpan(
                        text: patient,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      TextSpan(
                        text: ' — ',
                        style: TextStyle(color: _riskColor(risk)),
                      ),
                      TextSpan(
                        text: risk,
                        style: TextStyle(
                          color: _riskColor(risk),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (adherence != null)
                        TextSpan(
                          text: '  ($adherence% adherence)',
                          style: const TextStyle(
                            color: Color(0xFF6B7280),
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
