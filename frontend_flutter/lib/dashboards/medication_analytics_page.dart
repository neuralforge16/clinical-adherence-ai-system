import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../core/api_service.dart';

class MedicationAnalyticsPage extends StatefulWidget {
  final Map medication;

  const MedicationAnalyticsPage({super.key, required this.medication});

  @override
  State<MedicationAnalyticsPage> createState() =>
      _MedicationAnalyticsPageState();
}

class _MedicationAnalyticsPageState extends State<MedicationAnalyticsPage> {
  // ── Design tokens ──────────────────────────────────────────────────────────
  static const Color _primary = Color(0xFF1E4ED8);
  static const Color _pageBg = Color(0xFFF5F7FB);
  static const Color _cardBg = Colors.white;
  static const Color _mutedText = Color(0xFF6B7280);

  // ── State (all unchanged from original) ───────────────────────────────────
  String viewMode = "weekly";
  List logs = [];
  bool loading = true;
  Map<String, dynamic>? patientData;

  @override
  void initState() {
    super.initState();
    loadLogs();
    loadPatient();
  }

  // ── Data loaders (unchanged) ───────────────────────────────────────────────
  Future<void> loadLogs() async {
    try {
      final data = await ApiService.getMedicationLogs(widget.medication["id"]);
      setState(() {
        logs = data;
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
    }
  }

  Future<void> loadPatient() async {
    try {
      var data = await ApiService.getPatientById(
        widget.medication["patient_id"],
      );
      setState(() => patientData = data);
    } catch (e) {
      setState(() => patientData = {});
    }
  }

  // ── Chart logic (unchanged) ────────────────────────────────────────────────
  List<FlSpot> buildChartSpots() {
    if (logs.isEmpty) return [];

    logs.sort(
      (a, b) => DateTime.parse(
        a["timestamp"],
      ).compareTo(DateTime.parse(b["timestamp"])),
    );

    Map<int, List<Map>> grouped = {};

    for (var log in logs) {
      DateTime time = DateTime.parse(log["timestamp"]);
      int key;
      if (viewMode == "daily") {
        key = time.hour;
      } else if (viewMode == "weekly") {
        key = time.weekday;
      } else {
        key = time.day % 7;
      }
      grouped.putIfAbsent(key, () => []).add(log);
    }

    List<FlSpot> spots = [];
    grouped.forEach((key, groupLogs) {
      int taken = groupLogs.where((l) => l["status"] == "taken").length;
      double adherence = (taken / groupLogs.length) * 100;
      spots.add(FlSpot(key.toDouble(), adherence));
    });

    spots.sort((a, b) => a.x.compareTo(b.x));
    return spots;
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final medicationName = widget.medication["name"] ?? "Medication";
    final patientName =
        (patientData?["full_name"] ?? patientData?["name"] ?? "").toString();

    final taken = logs.where((l) => l["status"] == "taken").length;
    final missed = logs.where((l) => l["status"] == "missed").length;
    final total = logs.length;
    final adherence = total == 0 ? 0 : ((taken / total) * 100).round();

    return Scaffold(
      backgroundColor: _pageBg,
      appBar: AppBar(
        backgroundColor: _cardBg,
        elevation: 0,
        iconTheme: const IconThemeData(color: _primary),
        title: Text(
          medicationName,
          style: const TextStyle(
            color: Color(0xFF1A1A1A),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header info ────────────────────────────────────────────────
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    medicationName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    patientName.isEmpty
                        ? "Loading patient information..."
                        : patientName,
                    style: const TextStyle(color: _mutedText, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${widget.medication["dosage"]} • ${widget.medication["frequency"]} • ${widget.medication["time"]}",
                    style: const TextStyle(color: _mutedText, fontSize: 13),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── KPI cards ──────────────────────────────────────────────────
            loading
                ? const Center(child: CircularProgressIndicator())
                : Row(
                    children: [
                      _kpiCard(
                        "Adherence",
                        "$adherence%",
                        const Color(0xFF10B981),
                      ),
                      const SizedBox(width: 12),
                      _kpiCard("Taken", "$taken", _primary),
                      const SizedBox(width: 12),
                      _kpiCard("Missed", "$missed", const Color(0xFFEF4444)),
                    ],
                  ),

            const SizedBox(height: 16),

            // ── Adherence trend chart ──────────────────────────────────────
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Adherence Trend",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      // Period toggle pills
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: _pageBg,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            _modeButton("Daily"),
                            _modeButton("Weekly"),
                            _modeButton("Monthly"),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "Adherence trend over time. Red markers indicate risk events.",
                    style: TextStyle(color: _mutedText, fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 260,
                    child: LineChart(
                      LineChartData(
                        minY: 60,
                        maxY: 100,
                        gridData: FlGridData(show: true),
                        borderData: FlBorderData(show: false),
                        titlesData: FlTitlesData(
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              interval: 1,
                              getTitlesWidget: (value, meta) {
                                final style = const TextStyle(
                                  fontSize: 10,
                                  color: _mutedText,
                                );
                                if (viewMode == "weekly") {
                                  const days = [
                                    "Mon",
                                    "Tue",
                                    "Wed",
                                    "Thu",
                                    "Fri",
                                    "Sat",
                                    "Sun",
                                  ];
                                  int i = value.toInt() - 1;
                                  if (i >= 0 && i < 7) {
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 6),
                                      child: Text(days[i], style: style),
                                    );
                                  }
                                }
                                if (viewMode == "daily" &&
                                    value.toInt() % 3 == 0) {
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Text(
                                      "${value.toInt()}h",
                                      style: style,
                                    ),
                                  );
                                }
                                if (viewMode == "monthly" &&
                                    value.toInt() % 5 == 0) {
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Text(
                                      "${value.toInt()}",
                                      style: style,
                                    ),
                                  );
                                }
                                return const SizedBox();
                              },
                            ),
                          ),
                        ),
                        lineBarsData: [
                          LineChartBarData(
                            isCurved: false,
                            color: _primary,
                            barWidth: 3,
                            dotData: FlDotData(
                              show: true,
                              getDotPainter: (spot, percent, bar, index) {
                                if (spot.y < 80) {
                                  return FlDotCirclePainter(
                                    radius: 5,
                                    color: const Color(0xFFEF4444),
                                    strokeWidth: 0,
                                  );
                                }
                                return FlDotCirclePainter(
                                  radius: 3,
                                  color: _primary,
                                  strokeWidth: 0,
                                );
                              },
                            ),
                            belowBarData: BarAreaData(
                              show: true,
                              color: _primary.withOpacity(0.08),
                            ),
                            spots: buildChartSpots(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Insight ────────────────────────────────────────────────────
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Medication Insights",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: adherence < 70
                          ? const Color(0xFFEF4444).withOpacity(0.08)
                          : const Color(0xFF10B981).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          adherence < 70
                              ? Icons.warning_amber_rounded
                              : Icons.check_circle_outline,
                          color: adherence < 70
                              ? const Color(0xFFEF4444)
                              : const Color(0xFF10B981),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            adherence < 70
                                ? "Adherence is below optimal. Consider reviewing patient routine and support strategies."
                                : "Adherence is stable and well maintained.",
                            style: TextStyle(
                              color: adherence < 70
                                  ? const Color(0xFF9F1239)
                                  : const Color(0xFF065F46),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Dose logs ──────────────────────────────────────────────────
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Dose Logs",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 14),
                  loading
                      ? const Center(child: CircularProgressIndicator())
                      : logs.isEmpty
                      ? const Text(
                          "No logs available",
                          style: TextStyle(color: _mutedText),
                        )
                      : Column(
                          children: logs.map((log) {
                            final status = log["status"];
                            final isTaken = status == "taken";
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
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: isTaken
                                          ? const Color(
                                              0xFF10B981,
                                            ).withOpacity(0.12)
                                          : const Color(
                                              0xFFEF4444,
                                            ).withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      isTaken ? Icons.check : Icons.close,
                                      color: isTaken
                                          ? const Color(0xFF10B981)
                                          : const Color(0xFFEF4444),
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          status.toString().toUpperCase(),
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: isTaken
                                                ? const Color(0xFF065F46)
                                                : const Color(0xFF9F1239),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          log["timestamp"].toString(),
                                          style: const TextStyle(
                                            color: _mutedText,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _kpiCard(String title, String value, Color color) {
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
              value,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _modeButton(String mode) {
    final active = viewMode == mode.toLowerCase();
    return GestureDetector(
      onTap: () => setState(() => viewMode = mode.toLowerCase()),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? _primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          mode,
          style: TextStyle(
            color: active ? Colors.white : _mutedText,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
