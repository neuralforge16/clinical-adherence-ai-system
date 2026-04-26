import 'package:flutter/material.dart';
import '../core/api_service.dart';
import 'edit_medication_dialog.dart';
import '../dashboards/medication_analytics_page.dart';

class MedicationTable extends StatefulWidget {
  final int patientId;

  const MedicationTable({super.key, required this.patientId});

  @override
  State<MedicationTable> createState() => _MedicationTableState();
}

class _MedicationTableState extends State<MedicationTable> {
  List medications = [];

  @override
  void initState() {
    super.initState();
    loadMedications();
  }

  Future<void> loadMedications() async {
    var data = await ApiService.getPatientMedications(widget.patientId);

    setState(() {
      medications = data;
    });
  }

  deleteMedication(int id) async {
    await ApiService.deleteMedication(id);
    loadMedications();
  }

  // 🔥 NEXT DOSE LOGIC

  DateTime getNextDoseTime(String time, String frequency) {
    final now = DateTime.now();

    try {
      // 🔥 handle formats like "08:00" OR "8 Am"
      int hour = 8;
      int minute = 0;

      if (time.contains(":")) {
        final parts = time.split(":");
        hour = int.parse(parts[0]);
        minute = int.parse(parts[1]);
      } else {
        final lower = time.toLowerCase();

        if (lower.contains("am") || lower.contains("pm")) {
          hour = int.parse(lower.replaceAll(RegExp(r'[^0-9]'), ''));

          if (lower.contains("pm") && hour != 12) hour += 12;
          if (lower.contains("am") && hour == 12) hour = 0;
        }
      }

      final base = DateTime(now.year, now.month, now.day, hour, minute);

      int interval =
          int.tryParse(frequency.replaceAll(RegExp(r'[^0-9]'), '')) ?? 8;

      DateTime next = base;

      while (next.isBefore(now)) {
        next = next.add(Duration(hours: interval));
      }

      return next;
    } catch (e) {
      return now.add(const Duration(hours: 1)); // fallback
    }
  }

  String formatRemainingTime(DateTime nextDose) {
    final diff = nextDose.difference(DateTime.now());

    if (diff.isNegative) return "Now";

    final h = diff.inHours;
    final m = diff.inMinutes % 60;

    return "${h}h ${m}m";
  }

  Color getDoseColor(DateTime nextDose) {
    final diff = nextDose.difference(DateTime.now()).inMinutes;

    if (diff <= 0) return Colors.red;
    if (diff < 30) return Colors.orange;
    return Colors.green;
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
          const Text(
            "Active Prescriptions",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 20),

          DataTable(
            columns: const [
              DataColumn(label: Text("Medication")),
              DataColumn(label: Text("Dosage")),
              DataColumn(label: Text("Frequency")),
              DataColumn(label: Text("Time")),
              DataColumn(label: Text("Next Dose")), // ✅ NEW
              DataColumn(label: Text("Actions")),
            ],
            rows: medications.map((m) {
              final nextDose = getNextDoseTime(
                m["time"] ?? "08:00",
                m["frequency"] ?? "8h",
              );

              return DataRow(
                cells: [
                  DataCell(Text((m["name"] ?? "").toString())),
                  DataCell(Text((m["dosage"] ?? "").toString())),
                  DataCell(Text((m["frequency"] ?? "").toString())),
                  DataCell(Text((m["time"] ?? "").toString())),

                  /// ⏱ NEXT DOSE
                  DataCell(
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${nextDose.hour.toString().padLeft(2, '0')}:${nextDose.minute.toString().padLeft(2, '0')}",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          formatRemainingTime(nextDose),
                          style: TextStyle(
                            color: getDoseColor(nextDose),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                  /// 🔥 ACTIONS (UNCHANGED — YOUR LOGIC SAFE)
                  DataCell(
                    Row(
                      children: [
                        /// ANALYTICS
                        Tooltip(
                          message: "Medication analytics",
                          child: IconButton(
                            icon: const Icon(
                              Icons.analytics,
                              color: Colors.deepPurple,
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      MedicationAnalyticsPage(medication: m),
                                ),
                              );
                            },
                          ),
                        ),

                        /// EDIT
                        Tooltip(
                          message: "Edit medication",
                          child: IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () async {
                              await showDialog(
                                context: context,
                                builder: (context) =>
                                    EditMedicationDialog(medication: m),
                              );
                              loadMedications();
                            },
                          ),
                        ),

                        /// DELETE
                        Tooltip(
                          message: "Delete medication",
                          child: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Row(
                                    children: [
                                      Icon(Icons.warning, color: Colors.red),
                                      SizedBox(width: 10),
                                      Text("Delete Medication"),
                                    ],
                                  ),
                                  content: const Text(
                                    "Are you sure you want to delete this medication?",
                                  ),
                                  actions: [
                                    TextButton(
                                      child: const Text("Cancel"),
                                      onPressed: () => Navigator.pop(context),
                                    ),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                      ),
                                      child: const Text("Delete"),
                                      onPressed: () {
                                        deleteMedication(m["id"]);
                                        Navigator.pop(context);
                                      },
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),

                        const SizedBox(width: 10),

                        /// TAKEN
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                          ),
                          onPressed: () async {
                            var result = await ApiService.logDose(
                              patientId: widget.patientId,
                              medicationId: m["id"],
                              status: "taken",
                            );

                            setState(() {});

                            if (result["status"] == "duplicate") {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Dose already taken recently"),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    "Next dose at ${nextDose.hour}:${nextDose.minute.toString().padLeft(2, '0')}",
                                  ),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          },

                          child: const Text("Taken"),
                        ),

                        const SizedBox(width: 5),

                        /// MISSED
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          onPressed: () async {
                            var result = await ApiService.logDose(
                              patientId: widget.patientId,
                              medicationId: m["id"],
                              status: "missed",
                            );

                            if (result["status"] == "duplicate") {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Already logged recently"),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Missed dose recorded"),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                          child: const Text("Missed"),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
