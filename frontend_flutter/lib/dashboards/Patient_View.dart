import 'package:flutter/material.dart';
import '../core/api_service.dart';
import '../widgets/adherence_chart.dart';
import '../widgets/medication_timeline.dart';
import '../widgets/weekly_adherence_table.dart';
import '../widgets/summary_card.dart';
import '../widgets/notification_bell.dart';
import '../pages/login_page.dart';

/// Patient-facing portal.
/// Completely separate from PatientDashboard (which is the doctor's view).
/// No edit/delete controls, no AI assistant, no admin features.
/// Home tab is today's schedule with one-tap Mark as Taken.
class PatientView extends StatefulWidget {
  final int patientId;

  const PatientView({super.key, required this.patientId});

  @override
  State<PatientView> createState() => _PatientViewState();
}

class _PatientViewState extends State<PatientView> {
  // ── Design system ──────────────────────────────────────────────────────────
  static const Color _primary = Color(0xFF1E4ED8);
  static const Color _pageBg = Color(0xFFF5F7FB);
  static const Color _cardBg = Colors.white;
  static const Color _mutedText = Color(0xFF6B7280);
  static const Color _green = Color(0xFF10B981);
  static const Color _amber = Color(0xFFF59E0B);
  static const Color _red = Color(0xFFEF4444);

  int _selectedIndex = 0;

  // Patient data
  Map<String, dynamic>? _patient;
  List<Map<String, dynamic>> _schedule = [];
  List _medications = [];
  int _adherenceRate = 0;
  int _totalDoses = 0;
  int _missed = 0;
  bool _loadingSchedule = true;
  bool _loadingPatient = true;

  // Tab config — patient-facing labels
  static const _tabs = [
    (icon: Icons.today, label: 'Today'),
    (icon: Icons.bar_chart, label: 'My Progress'),
    (icon: Icons.medication, label: 'My Medications'),
  ];

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    await Future.wait([
      _loadPatient(),
      _loadSchedule(),
      _loadAdherence(),
      _loadMedications(),
    ]);
  }

  Future<void> _loadPatient() async {
    try {
      final data = await ApiService.getPatientById(widget.patientId);
      if (mounted)
        setState(() {
          _patient = data;
          _loadingPatient = false;
        });
    } catch (_) {
      if (mounted) setState(() => _loadingPatient = false);
    }
  }

  Future<void> _loadSchedule() async {
    try {
      final data = await ApiService.getTodaySchedule(widget.patientId);
      if (mounted)
        setState(() {
          _schedule = data;
          _loadingSchedule = false;
        });
    } catch (_) {
      if (mounted) setState(() => _loadingSchedule = false);
    }
  }

  Future<void> _loadAdherence() async {
    try {
      final data = await ApiService.getPatientAdherence(widget.patientId);
      if (mounted)
        setState(() {
          _adherenceRate = data['adherence_rate'] ?? 0;
          _totalDoses = data['total_doses'] ?? 0;
          _missed = data['missed'] ?? 0;
        });
    } catch (_) {}
  }

  Future<void> _loadMedications() async {
    try {
      final data = await ApiService.getPatientMedications(widget.patientId);
      if (mounted) setState(() => _medications = data);
    } catch (_) {}
  }

  String get _firstName {
    final name = _patient?['full_name'] ?? '';
    return name.isNotEmpty ? name.split(' ').first : 'there';
  }

  String get _fullName => _patient?['full_name'] ?? '';

  // ── Mark dose as taken ─────────────────────────────────────────────────────
  Future<void> _markTaken(Map<String, dynamic> dose) async {
    try {
      final result = await ApiService.logDose(
        patientId: widget.patientId,
        medicationId: dose['medication_id'],
        status: 'taken',
      );

      if (result['status'] == 'duplicate') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Already logged recently.'),
              backgroundColor: _amber,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      } else {
        // Refresh schedule
        await _loadSchedule();
        await _loadAdherence();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white, size: 16),
                  const SizedBox(width: 8),
                  Text('${dose['medication_name']} marked as taken!'),
                ],
              ),
              backgroundColor: _green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      }
    } catch (_) {}
  }

  // ── Build ──────────────────────────────────────────────────────────────────
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
                    'eHospital',
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

  // ── Content router ─────────────────────────────────────────────────────────
  Widget _buildContent({required bool isMobile}) {
    final pad = EdgeInsets.symmetric(
      horizontal: isMobile ? 16 : 24,
      vertical: 24,
    );

    switch (_selectedIndex) {
      case 0:
        return SingleChildScrollView(
          padding: pad,
          child: _todayTab(isMobile: isMobile),
        );
      case 1:
        return SingleChildScrollView(padding: pad, child: _progressTab());
      case 2:
        return SingleChildScrollView(padding: pad, child: _medicationsTab());
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
        const NotificationBell(),
        const SizedBox(width: 8),
        Tooltip(
          message: 'Profile',
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

  // ── Today tab ──────────────────────────────────────────────────────────────
  Widget _todayTab({required bool isMobile}) {
    // Count pending doses
    final pending = _schedule.where((d) => d['status'] == 'pending').length;
    final taken = _schedule.where((d) => d['status'] == 'taken').length;
    final missed = _schedule.where((d) => d['status'] == 'missed').length;
    final overdue = _schedule
        .where((d) => d['status'] == 'pending' && d['is_overdue'] == true)
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _topBar('My Portal  /  Today'),
        const SizedBox(height: 14),

        // Welcome banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _primary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _loadingPatient ? 'Good day!' : 'Hello, $_firstName 👋',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                pending > 0
                    ? 'You have $pending dose${pending == 1 ? '' : 's'} to take today.'
                    : taken > 0
                    ? 'Great job — all doses taken today! 🎉'
                    : 'No medications scheduled for today.',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Quick stats row
        if (_schedule.isNotEmpty) ...[
          Row(
            children: [
              _statChip('$taken Taken', _green, Icons.check_circle),
              const SizedBox(width: 10),
              _statChip('$missed Missed', _red, Icons.cancel),
              const SizedBox(width: 10),
              _statChip('$pending Pending', _primary, Icons.schedule),
              if (overdue > 0) ...[
                const SizedBox(width: 10),
                _statChip(
                  '$overdue Overdue',
                  _amber,
                  Icons.warning_amber_rounded,
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
        ],

        // Today's schedule card with tap-to-take
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                    "Today's Schedule",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () {
                      setState(() => _loadingSchedule = true);
                      _loadSchedule();
                    },
                    icon: const Icon(
                      Icons.refresh,
                      size: 18,
                      color: _mutedText,
                    ),
                    tooltip: 'Refresh',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              if (_loadingSchedule)
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
                        style: TextStyle(color: _mutedText, fontSize: 13),
                      ),
                    ],
                  ),
                )
              else if (_schedule.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: _pageBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.medication_outlined,
                          size: 36,
                          color: _mutedText,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'No medications scheduled for today.',
                          style: TextStyle(color: _mutedText, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Column(
                  children: _schedule.asMap().entries.map((entry) {
                    final i = entry.key;
                    final dose = entry.value;
                    return _doseCard(dose, i);
                  }).toList(),
                ),
            ],
          ),
        ),

        const SizedBox(height: 24),
      ],
    );
  }

  // ── Dose card with Mark as Taken button ────────────────────────────────────
  Widget _doseCard(Map<String, dynamic> dose, int index) {
    final status = (dose['status'] ?? 'pending').toString();
    final overdue = dose['is_overdue'] == true;
    final name = (dose['medication_name'] ?? '').toString();
    final dosage = (dose['dosage'] ?? '').toString();
    final time = (dose['scheduled_time'] ?? '').toString();
    final isPending = status == 'pending';
    final isTaken = status == 'taken';
    final isMissed = status == 'missed';

    Color statusColor = isTaken
        ? _green
        : isMissed
        ? _red
        : overdue
        ? _amber
        : _primary;

    return Container(
      margin: EdgeInsets.only(bottom: index < _schedule.length - 1 ? 12 : 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isTaken
            ? _green.withOpacity(0.04)
            : isMissed
            ? _red.withOpacity(0.04)
            : overdue
            ? _amber.withOpacity(0.04)
            : _pageBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          // Time block
          Container(
            width: 60,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                time,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  color: statusColor,
                ),
              ),
            ),
          ),

          const SizedBox(width: 14),

          // Med info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: isTaken ? _mutedText : const Color(0xFF1A1A1A),
                    decoration: isTaken
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                  ),
                ),
                if (dosage.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    dosage,
                    style: const TextStyle(color: _mutedText, fontSize: 12),
                  ),
                ],
                if (overdue && isPending) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 12,
                        color: _amber,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Overdue — please take now',
                        style: TextStyle(
                          color: _amber,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(width: 10),

          // Action
          if (isTaken)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _green.withOpacity(0.3)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, color: _green, size: 14),
                  SizedBox(width: 4),
                  Text(
                    'Taken',
                    style: TextStyle(
                      color: _green,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            )
          else if (isMissed)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _red.withOpacity(0.3)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.cancel, color: _red, size: 14),
                  SizedBox(width: 4),
                  Text(
                    'Missed',
                    style: TextStyle(
                      color: _red,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            )
          else
            // Mark as Taken button — the core patient action
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: ElevatedButton(
                onPressed: () => _markTaken(dose),
                style: ElevatedButton.styleFrom(
                  backgroundColor: overdue ? _amber : _primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Mark Taken',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Progress tab ───────────────────────────────────────────────────────────
  Widget _progressTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _topBar('My Portal  /  My Progress'),
        const SizedBox(height: 14),

        // Overall adherence banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _adherenceRate >= 85
                ? _green
                : _adherenceRate >= 60
                ? _amber
                : _red,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your Adherence Rate',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 4),
              Text(
                '$_adherenceRate%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _adherenceRate >= 85
                    ? 'Excellent — keep it up!'
                    : _adherenceRate >= 60
                    ? 'Good, but there\'s room to improve.'
                    : 'Needs attention — try to take all doses.',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Stats row
        Row(
          children: [
            Expanded(
              child: SummaryCard(
                title: 'Total Doses',
                value: '$_totalDoses',
                color: _primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SummaryCard(
                title: 'Taken',
                value: '${_totalDoses - _missed}',
                color: _green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SummaryCard(
                title: 'Missed',
                value: '$_missed',
                color: _red,
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Adherence chart
        _card(child: AdherenceChart(patientId: widget.patientId)),

        const SizedBox(height: 16),

        // Weekly table
        _card(child: WeeklyAdherenceTable(patientId: widget.patientId)),

        const SizedBox(height: 24),
      ],
    );
  }

  // ── Medications tab — read only ────────────────────────────────────────────
  Widget _medicationsTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _topBar('My Portal  /  My Medications'),
        const SizedBox(height: 14),

        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: _primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.medication,
                      color: _primary,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'My Active Prescriptions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 6),
              const Text(
                'Your prescriptions are managed by your doctor.',
                style: TextStyle(color: _mutedText, fontSize: 12),
              ),

              const SizedBox(height: 20),

              if (_medications.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: _pageBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.medication_outlined,
                          size: 32,
                          color: _mutedText,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'No active prescriptions.',
                          style: TextStyle(color: _mutedText, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Column(
                  children: _medications.map((m) {
                    final times =
                        (m['schedule_times'] as List?)
                            ?.map((t) => t.toString())
                            .toList() ??
                        [m['time']?.toString() ?? ''];
                    final isActive = m['is_active'] == true;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isActive
                            ? _pageBg
                            : _mutedText.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isActive
                              ? const Color(0xFFE5E7EB)
                              : _mutedText.withOpacity(0.15),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: isActive
                                  ? _primary.withOpacity(0.08)
                                  : _mutedText.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.medication,
                              color: isActive ? _primary : _mutedText,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      m['name']?.toString() ?? '',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                        color: isActive
                                            ? const Color(0xFF1A1A1A)
                                            : _mutedText,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 7,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isActive
                                            ? _green.withOpacity(0.1)
                                            : _mutedText.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                      child: Text(
                                        isActive ? 'Active' : 'Inactive',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: isActive ? _green : _mutedText,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Wrap(
                                  spacing: 12,
                                  children: [
                                    if ((m['dosage'] ?? '')
                                        .toString()
                                        .isNotEmpty)
                                      _infoChip(
                                        Icons.local_pharmacy,
                                        m['dosage'].toString(),
                                      ),
                                    _infoChip(
                                      Icons.access_time,
                                      times.join(' · '),
                                    ),
                                    if ((m['start_date'] ?? '')
                                        .toString()
                                        .isNotEmpty)
                                      _infoChip(
                                        Icons.calendar_today,
                                        'From ${m['start_date']}',
                                      ),
                                    if ((m['end_date'] ?? '')
                                        .toString()
                                        .isNotEmpty)
                                      _infoChip(
                                        Icons.event,
                                        'Until ${m['end_date']}',
                                      ),
                                  ],
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
    );
  }

  // ── Sidebar ────────────────────────────────────────────────────────────────
  Widget _buildSidebar({required bool isDrawer}) {
    return Container(
      color: _cardBg,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          const SizedBox(height: 20),

          // Logo
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
                      'eHospital',
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
                    'Smart Med. Adherence',
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

          const SizedBox(height: 16),

          // Patient name badge
          if (_fullName.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _pageBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: _primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person,
                        color: _primary,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _fullName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                              color: Color(0xFF1A1A1A),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const Text(
                            'Patient',
                            style: TextStyle(color: _mutedText, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 16),

          // Nav items
          for (int i = 0; i < _tabs.length; i++)
            _menuItem(
              icon: _tabs[i].icon,
              label: _tabs[i].label,
              index: i,
              isDrawer: isDrawer,
            ),

          const Spacer(),

          // Logout
          _logoutButton(isDrawer),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _menuItem({
    required IconData icon,
    required String label,
    required int index,
    required bool isDrawer,
  }) {
    final selected = _selectedIndex == index;

    // Show pending badge on Today tab
    final showBadge =
        index == 0 &&
        _schedule.where((d) => d['status'] == 'pending').isNotEmpty;

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
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected ? Colors.white : _mutedText,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
              // Pending doses badge on Today tab
              if (showBadge)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: selected ? Colors.white.withOpacity(0.25) : _amber,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${_schedule.where((d) => d['status'] == 'pending').length}',
                    style: TextStyle(
                      color: selected ? Colors.white : Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _logoutButton(bool isDrawer) {
    return Padding(
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
                        style: TextStyle(color: _mutedText, fontSize: 13),
                      ),
                      const SizedBox(height: 22),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: _mutedText,
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
              Icon(Icons.logout, color: _mutedText, size: 20),
              SizedBox(width: 10),
              Text('Logout', style: TextStyle(color: _mutedText)),
            ],
          ),
        ),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  Widget _card({required Widget child}) => Container(
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

  Widget _statChip(String label, Color color, IconData icon) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: color.withOpacity(0.25)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    ),
  );

  Widget _infoChip(IconData icon, String text) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 11, color: _mutedText),
      const SizedBox(width: 3),
      Text(text, style: const TextStyle(color: _mutedText, fontSize: 11)),
    ],
  );
}
