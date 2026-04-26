import 'package:flutter/material.dart';
import '../core/api_service.dart';
import '../widgets/edit_patient_dialog.dart';
import '../dashboards/patient_dashboard.dart';

class PatientTable extends StatefulWidget {
  final Function(Map patient)? onPatientTap;

  const PatientTable({super.key, this.onPatientTap});

  @override
  State<PatientTable> createState() => _PatientTableState();
}

class _PatientTableState extends State<PatientTable> {
  List patients = [];
  List filteredPatients = [];
  String searchText = "";

  @override
  void initState() {
    super.initState();
    loadPatients();
  }

  loadPatients() async {
    var patientData = await ApiService.getPatients();
    var adherenceData = await ApiService.getAdherenceOverview();

    Map adherenceMap = {};

    for (var a in adherenceData) {
      adherenceMap[a["patient_id"]] = a["adherence"];
    }

    for (var p in patientData) {
      p["adherence"] = adherenceMap[p["id"]] ?? 0;
    }

    setState(() {
      patients = patientData;
      filteredPatients = patientData;
    });
  }

  void searchPatients(String value) {
    setState(() {
      searchText = value;

      filteredPatients = patients.where((p) {
        final name = (p["full_name"] ?? "").toLowerCase();
        final email = (p["email"] ?? "").toLowerCase();

        return name.contains(value.toLowerCase()) ||
            email.contains(value.toLowerCase());
      }).toList();
    });
  }

  Color riskColor(int adherence) {
    if (adherence >= 85) {
      return Colors.green;
    } else if (adherence >= 60) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  Color riskRowColor(int adherence) {
    if (adherence >= 85) {
      return Colors.green.withOpacity(0.12);
    } else if (adherence >= 60) {
      return Colors.orange.withOpacity(0.12);
    } else {
      return Colors.red.withOpacity(0.12);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        /// SEARCH BAR
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: TextField(
            decoration: InputDecoration(
              hintText: "Search patients...",
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onChanged: searchPatients,
          ),
        ),

        /// TABLE
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columnSpacing: 40,
            columns: const [
              DataColumn(label: Text("Name")),
              DataColumn(label: Text("Email")),
              DataColumn(label: Text("Phone")),
              DataColumn(label: Text("Condition")),
              DataColumn(label: Text("Risk")),
              DataColumn(label: Text("Actions")),
            ],
            rows: filteredPatients.map((p) {
              final name = (p["full_name"] ?? "").toString();
              final email = (p["email"] ?? "").toString();
              final phone = (p["phone"] ?? "-").toString();
              final condition = (p["medical_condition"] ?? "-").toString();

              final adherence = (p["adherence"] ?? 0);

              return DataRow(
                color: MaterialStateProperty.resolveWith<Color?>(
                  (Set<MaterialState> states) => riskRowColor(adherence),
                ),
                cells: [
                  DataCell(Text(name)),
                  DataCell(Text(email)),
                  DataCell(Text(phone)),
                  DataCell(Text(condition)),

                  /// RISK INDICATOR
                  DataCell(
                    Row(
                      children: [
                        Icon(
                          Icons.circle,
                          size: 12,
                          color: riskColor(adherence),
                        ),
                        const SizedBox(width: 8),
                        Text("$adherence%"),
                      ],
                    ),
                  ),

                  /// ACTIONS
                  DataCell(
                    Row(
                      children: [
                        /// VIEW
                        IconButton(
                          icon: const Icon(Icons.visibility, size: 20),
                          tooltip: "View Patient",
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    PatientDashboard(patientId: p["id"]),
                              ),
                            );
                          },
                        ),

                        /// EDIT
                        IconButton(
                          icon: const Icon(Icons.edit, size: 20),
                          tooltip: "Edit",
                          onPressed: () async {
                            final updated = await showDialog(
                              context: context,
                              builder: (_) => EditPatientDialog(patient: p),
                            );

                            if (updated == true) {
                              loadPatients();
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
