import 'package:flutter/material.dart';
import '../core/api_service.dart';

class EditMedicationDialog extends StatefulWidget {
  final Map medication;

  const EditMedicationDialog({super.key, required this.medication});

  @override
  State<EditMedicationDialog> createState() => _EditMedicationDialogState();
}

class _EditMedicationDialogState extends State<EditMedicationDialog> {
  late TextEditingController nameController;
  late TextEditingController dosageController;
  late TextEditingController frequencyController;
  late TextEditingController timeController;

  @override
  void initState() {
    super.initState();

    nameController = TextEditingController(text: widget.medication["name"]);
    dosageController = TextEditingController(text: widget.medication["dosage"]);
    frequencyController = TextEditingController(
      text: widget.medication["frequency"],
    );
    timeController = TextEditingController(text: widget.medication["time"]);
  }

  save() async {
    await ApiService.updateMedication(
      id: widget.medication["id"],
      name: nameController.text,
      dosage: dosageController.text,
      frequency: frequencyController.text,
      time: timeController.text,
    );

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Edit Medication"),

      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: nameController,
            decoration: const InputDecoration(labelText: "Name"),
          ),

          TextField(
            controller: dosageController,
            decoration: const InputDecoration(labelText: "Dosage"),
          ),

          TextField(
            controller: frequencyController,
            decoration: const InputDecoration(labelText: "Frequency"),
          ),

          TextField(
            controller: timeController,
            decoration: const InputDecoration(labelText: "Time"),
          ),
        ],
      ),

      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),

        ElevatedButton(onPressed: save, child: const Text("Save")),
      ],
    );
  }
}
