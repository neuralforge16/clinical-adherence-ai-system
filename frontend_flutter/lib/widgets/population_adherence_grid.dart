import 'package:flutter/material.dart';
import '../core/api_service.dart';

class PopulationAdherenceGrid extends StatefulWidget {
  const PopulationAdherenceGrid({super.key});

  @override
  State<PopulationAdherenceGrid> createState() =>
      _PopulationAdherenceGridState();
}

class _PopulationAdherenceGridState extends State<PopulationAdherenceGrid> {
  static const Color _primary = Color(0xFF1E4ED8);
  static const Color _green = Color(0xFF10B981);
  static const Color _amber = Color(0xFFF59E0B);
  static const Color _red = Color(0xFFEF4444);
  static const Color _mutedText = Color(0xFF6B7280);

  List _patients = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await ApiService.getPopulationAdherence();
      if (mounted)
        setState(() {
          _patients = data;
          _loading = false;
        });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Color _riskColor(int adherence) {
    if (adherence >= 85) return _green;
    if (adherence >= 60) return _amber;
    return _red;
  }

  Color _riskBg(int adherence) {
    if (adherence >= 85) return const Color(0xFFF0FDF4);
    if (adherence >= 60) return const Color(0xFFFFFBEB);
    return const Color(0xFFFEF2F2);
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
                child: const Icon(Icons.grid_view, color: _primary, size: 16),
              ),
              const SizedBox(width: 10),
              const Text(
                'Population Adherence Overview',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Consistent loading state
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
                    'Loading patients...',
                    style: TextStyle(color: Color(0xFF6B7280), fontSize: 13),
                  ),
                ],
              ),
            )
          else if (_patients.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F7FB),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.people_outline,
                      size: 32,
                      color: _mutedText.withOpacity(0.4),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'No patient data yet.',
                      style: TextStyle(color: Color(0xFF6B7280), fontSize: 13),
                    ),
                  ],
                ),
              ),
            )
          else
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _patients.map((p) {
                final adherence = (p['adherence'] ?? 0) as int;
                final color = _riskColor(adherence);
                final bg = _riskBg(adherence);

                return Container(
                  width: 150,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: color.withOpacity(0.25)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              p['name']?.toString() ?? '',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                                color: Color(0xFF1A1A1A),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$adherence%',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}
