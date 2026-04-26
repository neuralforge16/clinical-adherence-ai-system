import 'package:flutter/material.dart';
import '../core/api_service.dart';
import '../dashboards/patient_dashboard.dart';
import '../widgets/add_patient_dialog.dart';
import '../widgets/edit_patient_dialog.dart';

class PatientsPage extends StatefulWidget {
  const PatientsPage({super.key});

  @override
  State<PatientsPage> createState() => _PatientsPageState();
}

class _PatientsPageState extends State<PatientsPage> {
  static const Color _primary = Color(0xFF1E4ED8);
  static const Color _pageBg = Color(0xFFF5F7FB);
  static const Color _cardBg = Colors.white;
  static const Color _mutedText = Color(0xFF6B7280);

  List<Map<String, dynamic>> patients = [];
  bool isLoading = true;

  // ── Feature 7: search ─────────────────────────────────────────────────────
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  List<Map<String, dynamic>> get _filtered {
    if (_query.isEmpty) return patients;
    final q = _query.toLowerCase();
    return patients.where((p) {
      final name = (p['full_name'] ?? '').toString().toLowerCase();
      final email = (p['email'] ?? '').toString().toLowerCase();
      final condition = (p['medical_condition'] ?? '').toString().toLowerCase();
      return name.contains(q) || email.contains(q) || condition.contains(q);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    loadPatients();
    _searchController.addListener(() {
      setState(() => _query = _searchController.text.trim());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ── Data (all unchanged) ───────────────────────────────────────────────────
  Future<void> loadPatients() async {
    var data = await ApiService.getPatients();
    setState(() {
      patients = data;
      isLoading = false;
    });
  }

  void openPatient(Map<String, dynamic> patient) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PatientDashboard(patientId: patient['id']),
      ),
    );
  }

  Future<void> deletePatient(int patientId) async {
    await ApiService.deletePatient(patientId);
    loadPatients();
  }

  void showDeletePatientDialog(Map<String, dynamic> patient) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Patient'),
        content: Text(
          "Are you sure you want to remove ${patient['full_name']}? This action cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await deletePatient(patient['id']);
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void showAddPatientDialog() async {
    var added = await showDialog(
      context: context,
      builder: (_) => const AddPatientDialog(),
    );
    if (added == true) loadPatients();
  }

  void showEditPatientDialog(Map<String, dynamic> patient) async {
    var updated = await showDialog(
      context: context,
      builder: (_) => EditPatientDialog(patient: patient),
    );
    if (updated == true) loadPatients();
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 10),
            Text('Loading data...'),
          ],
        ),
      );
    }

    final filtered = _filtered;

    return Container(
      color: _pageBg,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Patient Overview',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${patients.length} patient${patients.length == 1 ? '' : 's'} registered',
                      style: const TextStyle(color: _mutedText, fontSize: 13),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: showAddPatientDialog,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add Patient'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ── Feature 7: Search bar ────────────────────────────────────────
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name, email or condition...',
                hintStyle: const TextStyle(color: _mutedText, fontSize: 13),
                prefixIcon: const Icon(
                  Icons.search,
                  color: _mutedText,
                  size: 20,
                ),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(
                          Icons.close,
                          color: _mutedText,
                          size: 18,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: _cardBg,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: _primary, width: 1.5),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ── Result count when searching ──────────────────────────────────
            if (_query.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '${filtered.length} result${filtered.length == 1 ? '' : 's'} for "$_query"',
                  style: const TextStyle(color: _mutedText, fontSize: 12),
                ),
              ),

            // ── Patient list ─────────────────────────────────────────────────
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: _primary.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              _query.isNotEmpty
                                  ? Icons.search_off
                                  : Icons.people_outline,
                              color: _primary,
                              size: 32,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _query.isNotEmpty
                                ? 'No patients match "$_query"'
                                : 'No patients yet',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _query.isNotEmpty
                                ? 'Try a different name, email or condition.'
                                : 'Add your first patient to get started.',
                            style: const TextStyle(
                              color: _mutedText,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, index) =>
                          _patientCard(filtered[index]),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _patientCard(Map<String, dynamic> patient) {
    final name = patient['full_name'] ?? '';
    final email = patient['email'] ?? '';
    final condition = (patient['medical_condition'] ?? '').toString();

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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: _primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.person, color: _primary, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    email,
                    style: const TextStyle(color: _mutedText, fontSize: 13),
                  ),
                  if (condition.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F4FF),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        condition,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: _primary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _actionBtn(
                  icon: Icons.edit,
                  color: _primary,
                  tooltip: 'Edit Patient',
                  onTap: () => showEditPatientDialog(patient),
                ),
                const SizedBox(width: 4),
                _actionBtn(
                  icon: Icons.delete_outline,
                  color: const Color(0xFFEF4444),
                  tooltip: 'Delete Patient',
                  onTap: () => showDeletePatientDialog(patient),
                ),
                const SizedBox(width: 4),
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: InkWell(
                    onTap: () => openPatient(patient),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: _primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Open',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.white,
                            size: 12,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionBtn({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
        ),
      ),
    );
  }
}
