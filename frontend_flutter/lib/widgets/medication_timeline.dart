import 'package:flutter/material.dart';
import '../core/api_service.dart';

/// Shows today's scheduled doses for a patient loaded from the backend.
/// Each dose shows its scheduled time, status (pending/taken/missed),
/// and an overdue indicator.
class MedicationTimeline extends StatefulWidget {
  final int patientId;

  const MedicationTimeline({super.key, required this.patientId});

  @override
  State<MedicationTimeline> createState() => _MedicationTimelineState();
}

class _MedicationTimelineState extends State<MedicationTimeline> {
  static const Color _primary = Color(0xFF1E4ED8);
  static const Color _green = Color(0xFF10B981);
  static const Color _amber = Color(0xFFF59E0B);
  static const Color _red = Color(0xFFEF4444);
  static const Color _mutedText = Color(0xFF6B7280);

  List<Map<String, dynamic>> _schedule = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await ApiService.getTodaySchedule(widget.patientId);
      if (mounted)
        setState(() {
          _schedule = data;
          _loading = false;
        });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Color _statusColor(String status, bool overdue) {
    if (status == 'taken') return _green;
    if (status == 'missed') return _red;
    if (overdue) return _amber;
    return _primary;
  }

  IconData _statusIcon(String status, bool overdue) {
    if (status == 'taken') return Icons.check_circle;
    if (status == 'missed') return Icons.cancel;
    if (overdue) return Icons.warning_amber_rounded;
    return Icons.schedule;
  }

  String _statusLabel(String status, bool overdue) {
    if (status == 'taken') return 'Taken';
    if (status == 'missed') return 'Missed';
    if (overdue) return 'Overdue';
    return 'Pending';
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
                child: const Icon(Icons.today, color: _primary, size: 16),
              ),
              const SizedBox(width: 10),
              const Text(
                "Today's Medication Schedule",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const Spacer(),
              // Refresh button
              IconButton(
                onPressed: () {
                  setState(() => _loading = true);
                  _load();
                },
                icon: const Icon(Icons.refresh, size: 18, color: _mutedText),
                tooltip: 'Refresh',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Loading
          if (_loading)
            const Padding(
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
                    'Loading schedule...',
                    style: TextStyle(color: Color(0xFF6B7280), fontSize: 13),
                  ),
                ],
              ),
            )
          // Empty
          else if (_schedule.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F7FB),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.medication_outlined,
                    color: Color(0xFF6B7280),
                    size: 18,
                  ),
                  SizedBox(width: 10),
                  Text(
                    'No medications scheduled for today.',
                    style: TextStyle(color: Color(0xFF6B7280), fontSize: 13),
                  ),
                ],
              ),
            )
          // Schedule list
          else
            Column(
              children: _schedule.asMap().entries.map((entry) {
                final i = entry.key;
                final dose = entry.value;

                final status = (dose['status'] ?? 'pending').toString();
                final overdue = dose['is_overdue'] == true;
                final color = _statusColor(status, overdue);
                final name = (dose['medication_name'] ?? '').toString();
                final dosage = (dose['dosage'] ?? '').toString();
                final time = (dose['scheduled_time'] ?? '').toString();

                return Column(
                  children: [
                    if (i > 0) const Divider(height: 20),

                    Row(
                      children: [
                        // Time block
                        Container(
                          width: 64,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              Text(
                                time,
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                  color: color,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 14),

                        // Medication info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: Color(0xFF1A1A1A),
                                ),
                              ),
                              if (dosage.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  dosage,
                                  style: const TextStyle(
                                    color: _mutedText,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),

                        // Status badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: color.withOpacity(0.25)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _statusIcon(status, overdue),
                                size: 13,
                                color: color,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _statusLabel(status, overdue),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: color,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              }).toList(),
            ),

          // Summary footer
          if (!_loading && _schedule.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                _summaryChip(
                  _schedule.where((d) => d['status'] == 'taken').length,
                  'Taken',
                  _green,
                ),
                const SizedBox(width: 8),
                _summaryChip(
                  _schedule.where((d) => d['status'] == 'missed').length,
                  'Missed',
                  _red,
                ),
                const SizedBox(width: 8),
                _summaryChip(
                  _schedule.where((d) => d['status'] == 'pending').length,
                  'Pending',
                  _primary,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _summaryChip(int count, String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      '$count $label',
      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
    ),
  );
}
