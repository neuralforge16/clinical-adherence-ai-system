import 'package:flutter/material.dart';
import '../core/api_service.dart';

class SmartAlertsPanel extends StatelessWidget {
  const SmartAlertsPanel({super.key});

  static const Color _primary = Color(0xFF1E4ED8);
  static const Color _mutedText = Color(0xFF6B7280);
  static const Color _pageBg = Color(0xFFF5F7FB);

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
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1F2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.notifications_active,
                  color: Color(0xFFEF4444),
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Smart Alerts',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          FutureBuilder(
            future: ApiService.getAlerts(),
            builder: (context, snapshot) {
              // ── Feature 13: consistent loading state ───────────────────
              if (!snapshot.hasData) {
                return const _LoadingState(label: 'Loading alerts...');
              }

              final alerts = snapshot.data as List;

              if (alerts.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFF10B981).withOpacity(0.3),
                    ),
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
                        ),
                      ),
                    ],
                  ),
                );
              }

              return Column(
                children: alerts.map<Widget>((alert) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: _pageBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF1F2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.warning_amber_rounded,
                            color: Color(0xFFEF4444),
                            size: 14,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                alert['patient']?.toString() ?? '',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: Color(0xFF1A1A1A),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                alert['message']?.toString() ?? '',
                                style: const TextStyle(
                                  color: _mutedText,
                                  fontSize: 12,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
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

// ── Shared loading widget (Feature 13) ────────────────────────────────────────
class _LoadingState extends StatelessWidget {
  final String label;
  const _LoadingState({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13),
          ),
        ],
      ),
    );
  }
}
