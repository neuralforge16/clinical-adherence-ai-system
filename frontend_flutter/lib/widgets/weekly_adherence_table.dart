import 'package:flutter/material.dart';
import '../core/api_service.dart';

class WeeklyAdherenceTable extends StatefulWidget {
  final int patientId;

  const WeeklyAdherenceTable({super.key, required this.patientId});

  @override
  State<WeeklyAdherenceTable> createState() => _WeeklyAdherenceTableState();
}

class _WeeklyAdherenceTableState extends State<WeeklyAdherenceTable> {
  Map<String, List<bool>> weeklyData = {};
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadWeekly();
  }

  Future<void> loadWeekly() async {
    try {
      final days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];

      final data = await ApiService.getWeeklyAdherence(widget.patientId);

      Map<String, List<bool>> temp = {};

      for (var d in days) {
        final dayData = data[d] ?? [];
        temp[d] = List<bool>.from(dayData);
      }

      setState(() {
        weeklyData = temp;
        loading = false;
      });
    } catch (e) {
      setState(() {
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];

    if (loading) {
      return const Center(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              CircularProgressIndicator(),
              SizedBox(height: 10),
              Text("Loading data..."),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Table(
          border: TableBorder.all(color: Colors.grey.shade300),
          children: days.map((day) {
            List<bool> row = List<bool>.from(weeklyData[day] ?? []);

            // 🔥 FORCE FIXED LENGTH (VERY IMPORTANT)
            while (row.length < 3) {
              row.add(false);
            }

            // OPTIONAL: trim if too long
            if (row.length > 3) {
              row = row.sublist(0, 3);
            }

            // 🔥 FORCE SAME LENGTH (3 columns)
            while (row.length < 3) {
              row.add(false);
            }

            return TableRow(
              children: [
                Padding(padding: const EdgeInsets.all(8), child: Text(day)),
                ...row.map((taken) {
                  return Padding(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      taken ? Icons.check : Icons.close,
                      color: taken ? Colors.green : Colors.red,
                      size: 18,
                    ),
                  );
                }).toList(),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}
