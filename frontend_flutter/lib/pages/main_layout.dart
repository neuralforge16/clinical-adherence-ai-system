import 'package:flutter/material.dart';
import '../widgets/sidebar.dart';
import '../dashboards/doctor_dashboard.dart';
import '../pages/patients_page.dart';
import '../dashboards/patient_dashboard.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  String page = "dashboard";
  int? patientId;

  void navigate(String newPage, {int? id}) {
    setState(() {
      page = newPage;
      patientId = id;
    });
  }

  Widget buildContent() {
    if (page == "patients") {
      return PatientsPage(
        onPatientSelected: (id) {
          navigate("patientDashboard", id: id);
        },
      );
    }

    if (page == "patientDashboard" && patientId != null) {
      return PatientDashboard(patientId: patientId!);
    }

    return const DoctorDashboard();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          Sidebar(onNavigate: navigate),

          Expanded(child: buildContent()),
        ],
      ),
    );
  }
}
