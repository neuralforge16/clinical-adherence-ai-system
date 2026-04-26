import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class AdherencePieChart extends StatelessWidget {
  final int onTime;
  final int late;
  final int missed;

  const AdherencePieChart({
    super.key,
    required this.onTime,
    required this.late,
    required this.missed,
  });

  @override
  Widget build(BuildContext context) {
    final total = onTime + late + missed;

    if (total == 0) {
      return const Text("No data available");
    }

    return Column(
      children: [
        SizedBox(
          height: 250,
          child: PieChart(
            PieChartData(
              sectionsSpace: 3,
              centerSpaceRadius: 50,
              sections: [
                PieChartSectionData(
                  color: Colors.green,
                  value: onTime.toDouble(),
                  title: "${(onTime / total * 100).toStringAsFixed(0)}%",
                  radius: 70,
                  titleStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                PieChartSectionData(
                  color: Colors.orange,
                  value: late.toDouble(),
                  title: "${(late / total * 100).toStringAsFixed(0)}%",
                  radius: 70,
                  titleStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                PieChartSectionData(
                  color: Colors.red,
                  value: missed.toDouble(),
                  title: "${(missed / total * 100).toStringAsFixed(0)}%",
                  radius: 70,
                  titleStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _legend("On Time", Colors.green),
            const SizedBox(width: 20),
            _legend("Late", Colors.orange),
            const SizedBox(width: 20),
            _legend("Missed", Colors.red),
          ],
        ),
      ],
    );
  }

  Widget _legend(String text, Color color) {
    return Row(
      children: [
        Container(width: 14, height: 14, color: color),
        const SizedBox(width: 6),
        Text(text),
      ],
    );
  }
}
