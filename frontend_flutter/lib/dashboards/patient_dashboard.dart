import 'package:flutter/material.dart';
import '../core/api_service.dart';
import '../widgets/ai_chat_dialog.dart';
import '../widgets/notification_bell.dart';
import '../widgets/summary_card.dart';
import '../widgets/medication_timeline.dart';
import '../widgets/medication_table.dart';
import '../widgets/add_medication_dialog.dart';
import '../widgets/adherence_chart.dart';
import '../widgets/edit_patient_dialog.dart';
import '../pages/reports_page.dart';
import '../pages/login_page.dart';

class PatientDashboard extends StatefulWidget {
  final int patientId;

  const PatientDashboard({super.key, required this.patientId});

  @override
  State<PatientDashboard> createState() => _PatientDashboardState();
}

class _PatientDashboardState extends State<PatientDashboard> {
  static const Color _primary = Color(0xFF1E4ED8);
  static const Color _pageBg = Color(0xFFF5F7FB);
  static const Color _cardBg = Colors.white;
  static const Color _mutedText = Color(0xFF6B7280);

  int _selectedIndex = 0;

  List medications = [];
  bool loading = true;

  int adherenceRate = 0;
  int totalDoses = 0;
  int missed = 0;

  Map<String, dynamic>? patientData;

  @override
  void initState() {
    super.initState();
    loadPatient();
    loadMedications();
    loadAdherence();
  }

  Future<void> loadPatient() async {
    var data = await ApiService.getPatientById(widget.patientId);
    setState(() => patientData = data);
  }

  Future<void> loadMedications() async {
    var data = await ApiService.getPatientMedications(widget.patientId);
    setState(() {
      medications = data;
      loading = false;
    });
  }

  Future<void> loadAdherence() async {
    var data = await ApiService.getPatientAdherence(widget.patientId);
    setState(() {
      adherenceRate = data["adherence_rate"];
      totalDoses = data["total_doses"];
      missed = data["missed"];
    });
  }

  void showDeletePatientDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Delete Patient"),
        content: const Text(
          "Are you sure you want to remove this patient? This action cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await ApiService.deletePatient(widget.patientId);
              if (mounted) {
                Navigator.pop(context);
                Navigator.pop(context);
              }
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  void showEditPatientDialog() async {
    if (patientData == null) return;
    var updated = await showDialog(
      context: context,
      builder: (context) => EditPatientDialog(patient: patientData!),
    );
    if (updated == true) loadPatient();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  String get _patientName => patientData?["full_name"] ?? "";

  // Build breadcrumb: "Doctor Portal / <Patient Name> / <Tab>"
  String _breadcrumb(String tab) {
    final name = _patientName;
    if (name.isEmpty) return "Doctor Portal  /  Patient Dashboard";
    return "Doctor Portal  /  $name  /  $tab";
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 900;

        return Scaffold(
          backgroundColor: _pageBg,
          appBar: isMobile
              ? AppBar(
                  backgroundColor: _cardBg,
                  elevation: 0,
                  iconTheme: const IconThemeData(color: _primary),
                  title: const Text(
                    "eHospital",
                    style: TextStyle(
                      color: _primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              : null,
          drawer: isMobile ? _buildSidebar(isDrawer: true) : null,
          body: Row(
            children: [
              if (!isMobile)
                SizedBox(width: 240, child: _buildSidebar(isDrawer: false)),
              Expanded(child: _buildContent(isMobile: isMobile)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContent({required bool isMobile}) {
    final padding = EdgeInsets.symmetric(
      horizontal: isMobile ? 16 : 24,
      vertical: 24,
    );

    switch (_selectedIndex) {
      case 0:
        return loading
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 10),
                    Text("Loading data..."),
                  ],
                ),
              )
            : SingleChildScrollView(
                padding: padding,
                child: _dashboardContent(isMobile: isMobile),
              );

      case 1:
        return SingleChildScrollView(
          padding: padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _topBar(_breadcrumb("Medications")),
              const SizedBox(height: 20),
              _card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Patient Medications",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text("Add Medication"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () async {
                            await showDialog(
                              context: context,
                              builder: (context) => AddMedicationDialog(
                                patientId: widget.patientId,
                              ),
                            );
                            loadMedications();
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    MedicationTimeline(patientId: widget.patientId),
                    const SizedBox(height: 24),
                    MedicationTable(patientId: widget.patientId),
                  ],
                ),
              ),
            ],
          ),
        );

      case 2:
        return SingleChildScrollView(
          padding: padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _topBar(_breadcrumb("Analytics")),
              const SizedBox(height: 20),
              _card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Adherence Analytics",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        SummaryCard(
                          title: "Adherence Rate",
                          value: "$adherenceRate%",
                          color: const Color(0xFF10B981),
                        ),
                        SummaryCard(
                          title: "Total Doses",
                          value: "$totalDoses",
                          color: _primary,
                        ),
                        SummaryCard(
                          title: "Missed",
                          value: "$missed",
                          color: const Color(0xFFEF4444),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    AdherenceChart(patientId: widget.patientId),
                  ],
                ),
              ),
            ],
          ),
        );

      case 3:
        return ReportsPage(patientId: widget.patientId);

      default:
        return const SizedBox();
    }
  }

  // ── Top bar ────────────────────────────────────────────────────────────────
  Widget _topBar(String breadcrumb) {
    return Row(
      children: [
        Expanded(
          child: Text(
            breadcrumb,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: _mutedText, fontSize: 13),
          ),
        ),
        const SizedBox(width: 10),

        // AI Assistant pill — clickable, passes patient context
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () => AIChatDialog.show(
              context,
              patientName: _patientName.isEmpty ? null : _patientName,
              patientId: widget.patientId,
              adherenceRate: adherenceRate,
              medications: medications,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF7C3AED),
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.smart_toy, color: Colors.white, size: 14),
                  SizedBox(width: 6),
                  Text(
                    "AI Assistant",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(width: 12),

        // Bell — Feature 8: wired to real alerts
        const NotificationBell(),

        const SizedBox(width: 8),

        // Person
        Tooltip(
          message: "Profile",
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.person_outline, color: _primary, size: 18),
          ),
        ),
      ],
    );
  }

  // ── Dashboard tab ──────────────────────────────────────────────────────────
  Widget _dashboardContent({required bool isMobile}) {
    final patientName = _patientName;
    final patientEmail = patientData?["email"] ?? "";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _topBar(_breadcrumb("Patient Dashboard")),
        const SizedBox(height: 14),

        // Blue banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: _primary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            patientName.isEmpty
                ? "Patient Dashboard"
                : "Patient: $patientName\nMedication Adherence Overview",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 16,
              height: 1.4,
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Patient info card
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
                child: const Icon(Icons.person, size: 30, color: _primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      patientName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      patientEmail,
                      style: const TextStyle(color: _mutedText, fontSize: 13),
                    ),
                  ],
                ),
              ),
              Wrap(
                spacing: 4,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: _primary),
                    tooltip: "Edit Patient",
                    onPressed: showEditPatientDialog,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Color(0xFFDC2626)),
                    tooltip: "Delete Patient",
                    onPressed: showDeletePatientDialog,
                  ),
                  const SizedBox(width: 4),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.picture_as_pdf, size: 16),
                    label: const Text("Report"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            ReportsPage(patientId: widget.patientId),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Overview
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Overview",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  SummaryCard(
                    title: "Adherence Rate",
                    value: "$adherenceRate%",
                    color: const Color(0xFF10B981),
                  ),
                  SummaryCard(
                    title: "Total Doses",
                    value: "$totalDoses",
                    color: _primary,
                  ),
                  SummaryCard(
                    title: "Missed",
                    value: "$missed",
                    color: const Color(0xFFEF4444),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              AdherenceChart(patientId: widget.patientId),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Medications
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Patient Medications",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text("Add Medication"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () async {
                      await showDialog(
                        context: context,
                        builder: (context) =>
                            AddMedicationDialog(patientId: widget.patientId),
                      );
                      loadMedications();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
              MedicationTimeline(patientId: widget.patientId),
              const SizedBox(height: 24),
              MedicationTable(patientId: widget.patientId),
            ],
          ),
        ),

        const SizedBox(height: 24),
      ],
    );
  }

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

  // ── Sidebar with system name ───────────────────────────────────────────────
  Widget _buildSidebar({required bool isDrawer}) {
    return Container(
      color: _cardBg,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          const SizedBox(height: 20),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: _primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.local_hospital,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      "eHospital",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    "Smart Med. Adherence",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: _primary,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          _menuItem(Icons.dashboard, "Dashboard", 0, isDrawer),
          _menuItem(Icons.medication, "Medications", 1, isDrawer),
          _menuItem(Icons.bar_chart, "Analytics", 2, isDrawer),
          _menuItem(Icons.picture_as_pdf, "Reports", 3, isDrawer),

          const Spacer(),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () {
                if (isDrawer) Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    Icon(Icons.arrow_back, color: _mutedText, size: 20),
                    SizedBox(width: 10),
                    Text("Back", style: TextStyle(color: _mutedText)),
                  ],
                ),
              ),
            ),
          ),

          TextButton.icon(
            onPressed: () async {
              if (isDrawer) Navigator.pop(context);
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text("Logout"),
                  content: const Text("Are you sure you want to log out?"),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text("Cancel"),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text("Logout"),
                    ),
                  ],
                ),
              );
              if (confirm == true && mounted) {
                Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                  (route) => false,
                );
              }
            },
            icon: const Icon(Icons.logout),
            label: const Text("Logout"),
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _menuItem(IconData icon, String title, int index, bool isDrawer) {
    final selected = _selectedIndex == index;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
      decoration: BoxDecoration(
        color: selected ? _primary : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          setState(() => _selectedIndex = index);
          if (isDrawer) Navigator.pop(context);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(icon, color: selected ? Colors.white : _mutedText, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected ? Colors.white : _mutedText,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
