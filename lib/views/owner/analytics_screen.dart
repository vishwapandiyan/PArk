import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Earnings Analytics')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: LineChart(
          LineChartData(
            titlesData: const FlTitlesData(show: true),
            lineBarsData: [
              LineChartBarData(
                spots: const [
                  FlSpot(0, 2),
                  FlSpot(1, 3.5),
                  FlSpot(2, 2.2),
                  FlSpot(3, 5),
                  FlSpot(4, 3),
                  FlSpot(5, 4.2),
                ],
                isCurved: true,
                color: Theme.of(context).colorScheme.primary,
                barWidth: 3,
                dotData: const FlDotData(show: false),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


