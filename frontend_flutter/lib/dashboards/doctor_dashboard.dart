import 'package:flutter/material.dart';
import '../widgets/patient_table.dart';
import '../widgets/adherence_chart.dart';
import '../pages/patients_page.dart';
import '../pages/settings_page.dart';
import '../widgets/ai_risk_panel.dart';
import '../widgets/smart_alerts_panel.dart';
import '../widgets/doctor_calendar.dart';
import '../widgets/patient_risk_summary.dart';
import '../widgets/population_adherence_grid.dart';
import '../pages/reports_page.dart';
import '../widgets/ai_insight_panel.dart';
import '../widgets/ai_risk_prediction.dart';
import '../core/api_service.dart';
import '../widgets/top_risk_card.dart';
import '../pages/login_page.dart';
import '../widgets/ai_chat_dialog.dart';

class DoctorDashboard extends StatefulWidget {
  const DoctorDashboard({super.key});

  @override
  State<DoctorDashboard> createState() => _DoctorDashboardState();
}

class _DoctorDashboardState extends State<DoctorDashboard> {
  static const Color _primary = Color(0xFF1E4ED8);
  static const Color _pageBg = Color(0xFFF5F7FB);
  static const Color _cardBg = Colors.white;
  static const Color _mutedText = Color(0xFF6B7280);

  int selectedIndex = 0;

  // Tab labels for breadcrumb
  static const List<String> _tabLabels = [
    "Dashboard",
    "Patients",
    "Reports",
    "Settings",
  ];

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
              Expanded(
                child: Container(
                  color: _pageBg,
                  child: selectedIndex == 0
                      ? SingleChildScrollView(
                          padding: EdgeInsets.symmetric(
                            horizontal: isMobile ? 16 : 24,
                            vertical: 24,
                          ),
                          child: _dashboardContent(isMobile: isMobile),
                        )
                      : _buildContent(isMobile: isMobile),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Content switcher ───────────────────────────────────────────────────────
  Widget _buildContent({required bool isMobile}) {
    switch (selectedIndex) {
      case 0:
        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 16 : 24,
            vertical: 24,
          ),
          child: _dashboardContent(isMobile: isMobile),
        );
      case 1:
        return PatientsPage();
      case 2:
        return _reportsTab();
      case 3:
        return const SettingsPage();
      default:
        return const SizedBox();
    }
  }

  // ── Top bar with dynamic breadcrumb ───────────────────────────────────────
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

        // AI Assistant pill — MouseRegion gives pointer cursor on web/desktop
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () => AIChatDialog.show(context),
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

        // Bell
        Tooltip(
          message: "Notifications",
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _cardBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Color(0xFFE5E7EB)),
            ),
            child: const Icon(
              Icons.notifications_none,
              color: _mutedText,
              size: 18,
            ),
          ),
        ),

        const SizedBox(width: 8),

        // Profile
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

  // ── Dashboard content ──────────────────────────────────────────────────────
  Widget _dashboardContent({required bool isMobile}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _topBar("Doctor Portal  /  Dashboard"),
        const SizedBox(height: 14),

        // Blue banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: _primary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            "Hello, Doctor\nWish you a wonderful day at work.",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 16,
              height: 1.4,
            ),
          ),
        ),

        const SizedBox(height: 20),
        const TopRiskCard(),
        const SizedBox(height: 16),
        _card(child: AdherenceChart(patientId: 0)),
        const SizedBox(height: 16),

        isMobile
            ? Column(
                children: [
                  _card(child: const AIRiskPanel()),
                  const SizedBox(height: 16),
                  _card(child: const SmartAlertsPanel()),
                ],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _card(child: const AIRiskPanel())),
                  const SizedBox(width: 16),
                  Expanded(child: _card(child: const SmartAlertsPanel())),
                ],
              ),

        const SizedBox(height: 16),
        _card(child: const DoctorCalendar()),
        const SizedBox(height: 16),

        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                "Patients",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              SizedBox(height: 20),
              PatientRiskSummary(),
              SizedBox(height: 20),
              PopulationAdherenceGrid(),
              SizedBox(height: 24),
              AIInsightPanel(),
              SizedBox(height: 20),
              AIRiskPredictionPanel(),
              SizedBox(height: 24),
              _PatientTableOrEmpty(),
            ],
          ),
        ),

        const SizedBox(height: 24),
      ],
    );
  }

  // ── Reports tab ────────────────────────────────────────────────────────────
  Widget _reportsTab() {
    return FutureBuilder(
      future: ApiService.getPatients(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 10),
                Text("Loading data..."),
              ],
            ),
          );
        }

        final patients = (snapshot.data ?? []) as List;

        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          children: patients.map((p) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
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
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.person, color: _primary, size: 22),
                ),
                title: Text(
                  (p["full_name"] ?? p["name"] ?? "Unknown Patient").toString(),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  (p["email"] ?? "No email").toString(),
                  style: const TextStyle(color: _mutedText, fontSize: 13),
                ),
                trailing: const Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: _mutedText,
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ReportsPage(patientId: p["id"] ?? 0),
                    ),
                  );
                },
              ),
            );
          }).toList(),
        );
      },
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

  // ── Sidebar with system name subtitle ─────────────────────────────────────
  Widget _buildSidebar({required bool isDrawer}) {
    return Container(
      color: _cardBg,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          const SizedBox(height: 20),

          // Logo + name + system subtitle
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
                // System name — small pill under logo
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
          _menuItem(Icons.people, "Patients", 1, isDrawer),
          _menuItem(Icons.bar_chart, "Reports", 2, isDrawer),
          _menuItem(Icons.settings, "Settings", 3, isDrawer),

          const Spacer(),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () async {
                if (isDrawer) Navigator.pop(context);
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => Dialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    backgroundColor: Colors.white,
                    insetPadding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 24,
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 360),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF2F2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.logout,
                                color: Color(0xFFEF4444),
                                size: 22,
                              ),
                            ),
                            const SizedBox(height: 14),
                            const Text(
                              'Log out',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A1A1A),
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Are you sure you want to log out?',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFF6B7280),
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 22),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFF6B7280),
                                      side: const BorderSide(
                                        color: Color(0xFFE5E7EB),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 11,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    child: const Text(
                                      'Cancel',
                                      style: TextStyle(fontSize: 13),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFEF4444),
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 11,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    child: const Text(
                                      'Log out',
                                      style: TextStyle(fontSize: 13),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
                if (confirm == true && mounted) {
                  Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                    (route) => false,
                  );
                }
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Color(0xFF6B7280), size: 20),
                    SizedBox(width: 10),
                    Text('Logout', style: TextStyle(color: Color(0xFF6B7280))),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _menuItem(IconData icon, String title, int index, bool isDrawer) {
    final selected = selectedIndex == index;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
      decoration: BoxDecoration(
        color: selected ? _primary : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          setState(() => selectedIndex = index);
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

// ── Feature 14: empty state when no patients exist ────────────────────────────
class _PatientTableOrEmpty extends StatelessWidget {
  const _PatientTableOrEmpty();

  static const Color _primary = Color(0xFF1E4ED8);
  static const Color _mutedText = Color(0xFF6B7280);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: ApiService.getPatients(),
      builder: (context, snapshot) {
        // Loading
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
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
                  style: TextStyle(color: _mutedText, fontSize: 13),
                ),
              ],
            ),
          );
        }

        final patients = snapshot.data ?? [];

        // ── Empty state ────────────────────────────────────────────────────
        if (patients.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 48),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F7FB),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: _primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.people_outline,
                    color: _primary,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'No patients yet',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Go to Patients and add your first patient\nto see their data here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _mutedText,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          );
        }

        // Has patients — show the normal table
        return const PatientTable();
      },
    );
  }
}
