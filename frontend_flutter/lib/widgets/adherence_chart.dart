import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../core/api_service.dart';

class AdherenceChart extends StatefulWidget {
  /// Optional — when provided loads real data for this patient.
  /// When null (doctor dashboard overview) uses demo data.
  final int? patientId;

  const AdherenceChart({super.key, this.patientId});

  @override
  State<AdherenceChart> createState() => _AdherenceChartState();
}

class _AdherenceChartState extends State<AdherenceChart> {
  static const Color _primary = Color(0xFF1E4ED8);
  static const Color _mutedText = Color(0xFF6B7280);

  String selectedPeriod = 'Weekly';

  Map<String, List<bool>> _weeklyData = {};
  bool _loadingReal = false;
  bool _hasRealData = false;

  @override
  void initState() {
    super.initState();
    // Only load real data when a real patientId is provided
    if (widget.patientId != null && widget.patientId != 0) {
      _loadRealData();
    }
  }

  Future<void> _loadRealData() async {
    setState(() => _loadingReal = true);
    try {
      final data = await ApiService.getWeeklyAdherence(widget.patientId!);
      if (mounted) {
        setState(() {
          _weeklyData = Map<String, List<bool>>.from(
            data.map((k, v) => MapEntry(k.toString(), List<bool>.from(v))),
          );
          _hasRealData = true;
          _loadingReal = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingReal = false);
    }
  }

  List<FlSpot> get _realWeeklySpots {
    const order = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final spots = <FlSpot>[];
    for (int i = 0; i < order.length; i++) {
      final logs = _weeklyData[order[i]] ?? [];
      if (logs.isEmpty) continue;
      final rate = (logs.where((t) => t).length / logs.length) * 100;
      spots.add(FlSpot(i.toDouble(), rate));
    }
    return spots.isEmpty ? [const FlSpot(0, 0)] : spots;
  }

  List<FlSpot> get _demoData {
    switch (selectedPeriod) {
      case 'Daily':
        return const [
          FlSpot(0, 78),
          FlSpot(1, 82),
          FlSpot(2, 80),
          FlSpot(3, 86),
          FlSpot(4, 84),
          FlSpot(5, 88),
        ];
      case 'Monthly':
        return const [
          FlSpot(0, 72),
          FlSpot(1, 75),
          FlSpot(2, 79),
          FlSpot(3, 81),
          FlSpot(4, 84),
          FlSpot(5, 86),
        ];
      default:
        return const [
          FlSpot(0, 84),
          FlSpot(1, 88),
          FlSpot(2, 85),
          FlSpot(3, 91),
          FlSpot(4, 87),
          FlSpot(5, 83),
          FlSpot(6, 89),
        ];
    }
  }

  List<FlSpot> get chartData => (_hasRealData && selectedPeriod == 'Weekly')
      ? _realWeeklySpots
      : _demoData;

  List<String> get labels {
    switch (selectedPeriod) {
      case 'Daily':
        return ['8AM', '10AM', '12PM', '2PM', '4PM', '6PM'];
      case 'Monthly':
        return ['W1', 'W2', 'W3', 'W4', 'W5', 'W6'];
      default:
        return ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    }
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
          Row(
            children: [
              const Text(
                'Adherence Trend',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              if (_hasRealData && selectedPeriod == 'Weekly') ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Live',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF10B981),
                    ),
                  ),
                ),
              ],
              const Spacer(),
              _periodButton('Daily'),
              const SizedBox(width: 8),
              _periodButton('Weekly'),
              const SizedBox(width: 8),
              _periodButton('Monthly'),
            ],
          ),

          if (_loadingReal) ...[
            const SizedBox(height: 8),
            const LinearProgressIndicator(
              backgroundColor: Color(0xFFF0F4FF),
              color: _primary,
              minHeight: 2,
            ),
          ],

          const SizedBox(height: 24),

          SizedBox(
            height: 260,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: 100,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 20,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: const Color(0xFFE5E7EB),
                    strokeWidth: 1,
                    dashArray: [4, 4],
                  ),
                ),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 20,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) => Text(
                        value.toInt().toString(),
                        style: const TextStyle(fontSize: 12, color: _mutedText),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final i = value.toInt();
                        if (i < 0 || i >= labels.length)
                          return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            labels[i],
                            style: const TextStyle(
                              fontSize: 12,
                              color: _mutedText,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    isCurved: true,
                    color: _primary,
                    barWidth: 3,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                        radius: 4,
                        color: _primary,
                        strokeWidth: 2,
                        strokeColor: Colors.white,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: _primary.withOpacity(0.08),
                    ),
                    spots: chartData,
                  ),
                ],
              ),
            ),
          ),

          if (!_hasRealData &&
              widget.patientId != null &&
              widget.patientId != 0)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                'No adherence logs yet — showing sample data.',
                style: TextStyle(
                  color: _mutedText.withOpacity(0.7),
                  fontSize: 11,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _periodButton(String label) {
    final isSelected = selectedPeriod == label;
    return GestureDetector(
      onTap: () => setState(() => selectedPeriod = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? _primary : const Color(0xFFEEF2F7),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
