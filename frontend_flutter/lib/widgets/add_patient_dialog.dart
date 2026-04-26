import 'package:flutter/material.dart';
import '../core/api_service.dart';

class AddPatientDialog extends StatefulWidget {
  const AddPatientDialog({super.key});

  @override
  State<AddPatientDialog> createState() => _AddPatientDialogState();
}

class _AddPatientDialogState extends State<AddPatientDialog> {
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final ageController = TextEditingController();
  final sexController = TextEditingController();
  final dobController = TextEditingController();
  final conditionController = TextEditingController();
  final notesController = TextEditingController();

  Future savePatient() async {
    final fullName =
        "${firstNameController.text.trim()} ${lastNameController.text.trim()}"
            .trim();

    await ApiService.addPatient(
      fullName: fullName,
      email: emailController.text.trim(),
      phone: phoneController.text.trim(),
      age: int.tryParse(ageController.text.trim()),
      sex: sexController.text.trim(),
      dateOfBirth: dobController.text.trim(),
      medicalCondition: conditionController.text.trim(),
      notes: notesController.text.trim(),
    );

    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  InputDecoration inputStyle(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: Colors.grey.shade50,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 560,
        padding: const EdgeInsets.all(28),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.person_add, color: Colors.blue),
                  SizedBox(width: 10),
                  Text(
                    "Add New Patient",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: firstNameController,
                      decoration: inputStyle("First Name"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: lastNameController,
                      decoration: inputStyle("Last Name"),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              TextField(
                controller: emailController,
                decoration: inputStyle("Email Address"),
              ),

              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: phoneController,
                      decoration: inputStyle("Phone Number"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: ageController,
                      decoration: inputStyle("Age"),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: sexController,
                      decoration: inputStyle("Sex"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: dobController,
                      decoration: inputStyle("Date of Birth"),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              TextField(
                controller: conditionController,
                decoration: inputStyle("Medical Condition"),
              ),

              const SizedBox(height: 14),

              TextField(
                controller: notesController,
                maxLines: 4,
                decoration: inputStyle("Patient Notes"),
              ),

              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Cancel"),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: savePatient,
                    icon: const Icon(Icons.save),
                    label: const Text("Add Patient"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
