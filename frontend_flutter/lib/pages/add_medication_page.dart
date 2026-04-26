import 'package:flutter/material.dart';
import '../core/api_service.dart';

class AddMedicationPage extends StatefulWidget {
  const AddMedicationPage({super.key});

  @override
  State<AddMedicationPage> createState() => _AddMedicationPageState();
}

class _AddMedicationPageState extends State<AddMedicationPage> {
  final nameController = TextEditingController();
  final dosageController = TextEditingController();
  final frequencyController = TextEditingController();
  final timeController = TextEditingController();

  Future addMedication() async {
    await ApiService.addMedication(
      patientId: 1,
      name: nameController.text,
      dosage: dosageController.text,
      frequency: frequencyController.text,
      time: timeController.text,
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Medication")),

      body: Padding(
        padding: const EdgeInsets.all(30),

        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Medication Name"),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: dosageController,
              decoration: const InputDecoration(labelText: "Dosage"),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: frequencyController,
              decoration: const InputDecoration(labelText: "Frequency"),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: timeController,
              decoration: const InputDecoration(labelText: "Time"),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: addMedication,
              child: const Text("Add Medication"),
            ),
          ],
        ),
      ),
    );
  }
}
