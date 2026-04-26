import 'package:flutter/material.dart';
import '../core/api_service.dart';

class AddMedicationDialog extends StatefulWidget {
  final int patientId;

  const AddMedicationDialog({super.key, required this.patientId});

  @override
  State<AddMedicationDialog> createState() => _AddMedicationDialogState();
}

class _AddMedicationDialogState extends State<AddMedicationDialog> {
  static const Color _primary = Color(0xFF1E4ED8);
  static const Color _mutedText = Color(0xFF6B7280);
  static const Color _pageBg = Color(0xFFF5F7FB);

  final _nameController = TextEditingController();
  final _dosageController = TextEditingController();
  final _frequencyController = TextEditingController();

  String? _startDate;
  String? _endDate;
  List<String> _scheduleTimes = [];
  bool _saving = false;
  bool _ongoing = false; // no end date

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _frequencyController.dispose();
    super.dispose();
  }

  // ── Date picker ─────────────────────────────────────────────────────────────
  Future<void> _pickDate({required bool isStart}) async {
    final initial = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) => Theme(
        data: Theme.of(
          context,
        ).copyWith(colorScheme: const ColorScheme.light(primary: _primary)),
        child: child!,
      ),
    );
    if (picked != null) {
      final formatted =
          "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      setState(() {
        if (isStart) {
          _startDate = formatted;
        } else {
          _endDate = formatted;
        }
      });
    }
  }

  // ── Time picker ──────────────────────────────────────────────────────────────
  Future<void> _addTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 8, minute: 0),
      builder: (context, child) => Theme(
        data: Theme.of(
          context,
        ).copyWith(colorScheme: const ColorScheme.light(primary: _primary)),
        child: child!,
      ),
    );
    if (picked != null) {
      final formatted =
          "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}";
      if (!_scheduleTimes.contains(formatted)) {
        setState(() => _scheduleTimes.add(formatted));
        _scheduleTimes.sort();
      }
    }
  }

  // ── Save ─────────────────────────────────────────────────────────────────────
  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a medication name.')),
      );
      return;
    }
    if (_scheduleTimes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one scheduled dose time.')),
      );
      return;
    }
    if (_startDate == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please set a start date.')));
      return;
    }

    setState(() => _saving = true);

    try {
      await ApiService.addMedication(
        patientId: widget.patientId,
        name: _nameController.text.trim(),
        dosage: _dosageController.text.trim(),
        frequency: _frequencyController.text.trim().isEmpty
            ? '${_scheduleTimes.length}x daily'
            : _frequencyController.text.trim(),
        time: _scheduleTimes.first,
        scheduleTimes: _scheduleTimes,
        startDate: _startDate,
        endDate: _ongoing ? null : _endDate,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save. Please try again.')),
        );
      }
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.medication,
                      color: _primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Add Prescription',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Medication name
              _label('Medication Name *'),
              _field(_nameController, 'e.g. Metformin'),

              const SizedBox(height: 14),

              // Dosage + Frequency row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label('Dosage'),
                        _field(_dosageController, 'e.g. 500mg'),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label('Frequency (optional)'),
                        _field(_frequencyController, 'e.g. twice daily'),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 16),

              // ── Prescription period ────────────────────────────────────
              const Text(
                'Prescription Period',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'When should this medication start and end?',
                style: TextStyle(
                  color: _mutedText.withOpacity(0.8),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _dateTile(
                      label: 'Start Date *',
                      value: _startDate,
                      icon: Icons.calendar_today,
                      onTap: () => _pickDate(isStart: true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ongoing
                        ? Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _primary.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: _primary.withOpacity(0.2),
                              ),
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.all_inclusive,
                                  color: _primary,
                                  size: 18,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Ongoing',
                                  style: TextStyle(
                                    color: _primary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : _dateTile(
                            label: 'End Date',
                            value: _endDate,
                            icon: Icons.event,
                            onTap: () => _pickDate(isStart: false),
                          ),
                  ),
                ],
              ),

              const SizedBox(height: 8),
              Row(
                children: [
                  Checkbox(
                    value: _ongoing,
                    activeColor: _primary,
                    onChanged: (v) => setState(() {
                      _ongoing = v ?? false;
                      _endDate = null;
                    }),
                  ),
                  const Text(
                    'No end date (ongoing prescription)',
                    style: TextStyle(fontSize: 13),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),

              // ── Schedule times ─────────────────────────────────────────
              Row(
                children: [
                  const Text(
                    'Dose Schedule *',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _addTime,
                    icon: const Icon(Icons.add, size: 16, color: _primary),
                    label: const Text(
                      'Add Time',
                      style: TextStyle(color: _primary, fontSize: 13),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Set specific times when the patient should take this medication.',
                style: TextStyle(
                  color: _mutedText.withOpacity(0.8),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 12),

              if (_scheduleTimes.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _pageBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFFE5E7EB),
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.schedule, color: Color(0xFF6B7280), size: 16),
                      SizedBox(width: 8),
                      Text(
                        'No times added yet — tap Add Time',
                        style: TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _scheduleTimes
                      .map(
                        (t) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: _primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _primary.withOpacity(0.2),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.access_time,
                                color: _primary,
                                size: 14,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                t,
                                style: const TextStyle(
                                  color: _primary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(width: 6),
                              GestureDetector(
                                onTap: () =>
                                    setState(() => _scheduleTimes.remove(t)),
                                child: const Icon(
                                  Icons.close,
                                  size: 14,
                                  color: _primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),

              const SizedBox(height: 28),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _mutedText,
                        side: const BorderSide(color: Color(0xFFE5E7EB)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Add Prescription'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Color(0xFF1A1A1A),
      ),
    ),
  );

  Widget _field(TextEditingController c, String hint) => TextField(
    controller: c,
    style: const TextStyle(fontSize: 14),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF6B7280), fontSize: 13),
      filled: true,
      fillColor: const Color(0xFFF5F7FB),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _primary, width: 1.5),
      ),
    ),
  );

  Widget _dateTile({
    required String label,
    required String? value,
    required IconData icon,
    required VoidCallback onTap,
  }) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(10),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: value != null
              ? _primary.withOpacity(0.3)
              : const Color(0xFFE5E7EB),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: value != null ? _primary : const Color(0xFF6B7280),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value ?? label,
              style: TextStyle(
                fontSize: 13,
                color: value != null
                    ? const Color(0xFF1A1A1A)
                    : const Color(0xFF6B7280),
                fontWeight: value != null ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
