import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../widgets/weekly_adherence_table.dart';
import '../widgets/adherence_pie_chart.dart';
import '../core/api_service.dart';

class ReportsPage extends StatefulWidget {
  final int patientId;

  const ReportsPage({super.key, required this.patientId});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  // ── Design tokens ──────────────────────────────────────────────────────────
  static const Color _primary = Color(0xFF1E4ED8);
  static const Color _pageBg = Color(0xFFF5F7FB);
  static const Color _cardBg = Colors.white;
  static const Color _mutedText = Color(0xFF6B7280);

  // ── State (all unchanged) ──────────────────────────────────────────────────
  Map<String, dynamic>? reportData;
  Map<String, dynamic>? patientData;

  @override
  void initState() {
    super.initState();
    loadReport();
    loadPatient();
  }

  Future<void> loadPatient() async {
    try {
      var data = await ApiService.getPatientById(widget.patientId);
      setState(() => patientData = data);
    } catch (e) {
      setState(() => patientData = {});
    }
  }

  Future<void> loadReport() async {
    try {
      var data = await ApiService.getPatientReport(widget.patientId);
      setState(() => reportData = data);
    } catch (e) {
      setState(
        () => reportData = {
          "stable": 0,
          "risk": 0,
          "critical": 0,
          "on_time": 0,
          "late": 0,
          "missed": 0,
        },
      );
    }
  }

  // ── Clinical insight logic (unchanged) ────────────────────────────────────
  String getClinicalInsight() {
    final onTime = reportData?["on_time"] ?? 0;
    final missed = reportData?["missed"] ?? 0;
    final late = reportData?["late"] ?? 0;

    if (onTime >= 85 && missed < 10) {
      return "Patient demonstrates consistently high adherence with minimal missed doses. Continue current treatment plan.";
    }
    if (onTime >= 70) {
      if (late > 20) {
        return "Patient frequently takes medication late. Consider adjusting medication timing or reinforcing schedule adherence.";
      }
      return "Adherence is moderate but stable. Continued monitoring is recommended.";
    }
    if (onTime >= 50) {
      if (missed > late) {
        return "Patient is missing doses more frequently than taking them late. Investigate possible barriers to adherence.";
      }
      return "Adherence is declining with inconsistent intake patterns. Clinical review is advised.";
    }
    return "Critical adherence risk detected. Patient is missing a significant number of doses. Immediate intervention is strongly recommended.";
  }

  // ── PDF generation (unchanged) ────────────────────────────────────────────
  Future<void> generatePdf() async {
    final pdf = pw.Document();
    final data = reportData ?? {};

    pdf.addPage(
      pw.Page(
        build: (context) => pw.Padding(
          padding: const pw.EdgeInsets.all(24),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                "Medication Adherence Report",
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                "Patient: ${(patientData?["full_name"] ?? patientData?["name"] ?? widget.patientId).toString()}",
                style: pw.TextStyle(fontSize: 14),
              ),
              pw.SizedBox(height: 20),
              pw.Divider(),
              pw.SizedBox(height: 10),
              pw.Text(
                "Adherence Summary",
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 10),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("On Time: ${data["on_time"]}%"),
                  pw.Text("Late: ${data["late"]}%"),
                  pw.Text("Missed: ${data["missed"]}%"),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                "Risk Distribution",
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 10),
              pw.Text("Stable: ${data["stable"]}"),
              pw.Text("At Risk: ${data["risk"]}"),
              pw.Text("Critical: ${data["critical"]}"),
              pw.SizedBox(height: 20),
              pw.Divider(),
              pw.SizedBox(height: 10),
              pw.Text(
                "Clinical Insight",
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 10),
              pw.Text((reportData?["ai_insight"] ?? "").toString()),
              pw.SizedBox(height: 30),
              pw.Text(
                "Generated by Medication Adherence Monitoring System",
                style: pw.TextStyle(fontSize: 10),
              ),
            ],
          ),
        ),
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  // ── Share (unchanged) ─────────────────────────────────────────────────────
  void shareReport(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        final emailController = TextEditingController();
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text("Share Report"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Enter recipient email"),
              const SizedBox(height: 14),
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  hintText: "Email address",
                  filled: true,
                  fillColor: const Color(0xFFF5F6F8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Report sent to ${emailController.text}"),
                  ),
                );
              },
              child: const Text("Send"),
            ),
          ],
        );
      },
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (reportData == null) {
      return const Scaffold(
        backgroundColor: Color(0xFFF5F7FB),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 10),
              Text("Loading report..."),
            ],
          ),
        ),
      );
    }

    final data = reportData!;
    final patientName =
        (patientData?["full_name"] ?? patientData?["name"] ?? "").toString();

    return Scaffold(
      backgroundColor: _pageBg,

      // ── AppBar ─────────────────────────────────────────────────────────────
      appBar: AppBar(
        backgroundColor: _cardBg,
        elevation: 0,
        iconTheme: const IconThemeData(color: _primary),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Patient Report",
              style: TextStyle(
                color: Color(0xFF1A1A1A),
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            if (patientName.isNotEmpty)
              Text(
                patientName,
                style: const TextStyle(
                  color: _mutedText,
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
          ],
        ),
        actions: [
          Tooltip(
            message: "Export PDF",
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: _primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                onPressed: generatePdf,
                icon: const Icon(Icons.picture_as_pdf, color: _primary),
              ),
            ),
          ),
          Tooltip(
            message: "Share Report",
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: _primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                onPressed: () => shareReport(context),
                icon: const Icon(Icons.share, color: _primary),
              ),
            ),
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Patient header ───────────────────────────────────────────
            _card(
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: _primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.person, color: _primary, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        patientName.isEmpty
                            ? "Loading patient..."
                            : patientName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "Medication Adherence Report",
                        style: TextStyle(color: _mutedText, fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Adherence summary ────────────────────────────────────────
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Adherence Summary",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _kpiCard(
                        "Stable",
                        data["stable"],
                        const Color(0xFF10B981),
                      ),
                      const SizedBox(width: 12),
                      _kpiCard(
                        "At Risk",
                        data["risk"],
                        const Color(0xFFF59E0B),
                      ),
                      const SizedBox(width: 12),
                      _kpiCard(
                        "Critical",
                        data["critical"],
                        const Color(0xFFEF4444),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Weekly adherence table ───────────────────────────────────
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Weekly Medication Adherence",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 16),
                  WeeklyAdherenceTable(patientId: widget.patientId),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Medication timing pie ────────────────────────────────────
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Medication Timing",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 20),
                  AdherencePieChart(
                    onTime: data["on_time"] ?? 0,
                    late: data["late"] ?? 0,
                    missed: data["missed"] ?? 0,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Clinical insight ─────────────────────────────────────────
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Clinical Insight",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F4FF),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _primary.withOpacity(0.2)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.lightbulb_outline,
                          color: _primary,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            (reportData?["ai_insight"] ?? "").toString(),
                            style: const TextStyle(
                              height: 1.6,
                              color: Color(0xFF1A1A1A),
                              fontSize: 13,
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

            // ── Dose logs ────────────────────────────────────────────────
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
                  FutureBuilder(
                    future: ApiService.getAdherenceLogs(widget.patientId),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      final logs = snapshot.data as List;

                      if (logs.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Text(
                            "No adherence data available for this patient",
                            style: TextStyle(color: _mutedText),
                          ),
                        );
                      }

                      return Column(
                        children: logs.map((log) {
                          final status = (log["status"] ?? "").toString();
                          final timestamp = (log["timestamp"] ?? "").toString();
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
                                  width: 34,
                                  height: 34,
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
                                    size: 16,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        status.toUpperCase(),
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                          color: isTaken
                                              ? const Color(0xFF065F46)
                                              : const Color(0xFF9F1239),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        timestamp,
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
                      );
                    },
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

  Widget _kpiCard(String title, dynamic value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Text(
              value.toString(),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
