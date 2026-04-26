import 'package:flutter/material.dart';
import '../dashboards/doctor_dashboard.dart';
import '../dashboards/patient_view.dart';

class RouterPage extends StatelessWidget {
  final String role;
  final int userId;

  const RouterPage({super.key, required this.role, required this.userId});

  @override
  Widget build(BuildContext context) {
    if (role == 'doctor') {
      return const DoctorDashboard();
    }

    if (role == 'patient') {
      // PatientView — patient-facing portal with today's schedule,
      // progress tracking, and read-only prescription list.
      // No doctor controls, no AI assistant, no admin features.
      return PatientView(patientId: userId);
    }

    return const Scaffold(body: Center(child: Text('Unknown role')));
  }
}
