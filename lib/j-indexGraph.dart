import 'package:flutter/material.dart';
import '_colors.dart';
import 'package:fl_chart/fl_chart.dart';

class JindexGraph extends StatelessWidget {
  final List<Map<String, dynamic>> activities;
  const JindexGraph({
    super.key,
    required this.activities,
  });

  List<List<int>> findJindexGraph() {
    List<int> Times = [];
    for (var activity in activities) {
      int durationSeconds = activity['moving_time'] ~/ 60;
      Times.add(durationSeconds);
    }

    // Sort the list in descending order
    Times.sort((a, b) => b.compareTo(a));
    Map<int, int> points = {};

    int i = 0;
    for (int t in Times) {
      i++;
      if (points.containsKey(t)) {
        points[t] = points[t]! + 1;
      } else {
        points[t] = i;
      }
    }

    return points.entries.map((e) => [e.key, e.value]).toList();
  }

  int findLargestX() {
    List<int> items = [];
    for (var activity in activities) {
      int durationSeconds = activity['moving_time'] ~/ 60;
      items.add(durationSeconds);
    }
    // Sort the list in descending order
    items.sort((a, b) => b.compareTo(a));
    // print(items);
    // Find the largest X
    for (int i = 0; i < items.length; i++) {
      // print("${i + 1}  ${items[i]}");
      if (i + 1 >= items[i]) {
        return i + 1;
      }
    }

    // If no such X is found, return 0
    return items.length;
  }

  @override
  Widget build(BuildContext context) {
    List<List<int>> points = findJindexGraph();
    int JN = findLargestX();
    return Container(
      height: 600,
      width: 1600,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: TreenixColors.grayBackground,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        mainAxisSize: MainAxisSize.max,
        children: [
          SizedBox(height: 10),
          Container(
            padding: EdgeInsets.only(left: 30, right: 30),
            child: Text(
              "Your J-index is $JN, that means you have $JN activities that last longer that $JN minutes",
              style: TextStyle(
                fontSize: 20,
                color: TreenixColors.primaryPink,
              ),
            ),
          ),
          // SizedBox(height: 10),
          Container(
            padding: EdgeInsets.all(30),
            height: 550,
            width: 1600,
            child: LineChart(
              LineChartData(
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      interval: 10,
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          "${value.toInt()}",
                          style: TextStyle(
                            color: TreenixColors.primaryPink,
                            fontSize: 17,
                          ),
                        );
                      },
                    ),
                    axisNameSize: 40,
                    axisNameWidget: Text(
                      "Nr o Activities",
                      style: TextStyle(
                        color: TreenixColors.lightGray,
                        fontSize: 22,
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      interval: 10,
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          "${value.toInt()}",
                          style: TextStyle(
                            color: TreenixColors.primaryPink,
                            fontSize: 17,
                          ),
                        );
                      },
                    ),
                    axisNameSize: 40,
                    axisNameWidget: Text(
                      "Minutes",
                      style: TextStyle(
                        color: TreenixColors.lightGray,
                        fontSize: 22,
                      ),
                    ),
                  ),
                  rightTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  horizontalInterval: 10,
                  verticalInterval: 10,
                ),
                borderData: FlBorderData(show: true),
                lineBarsData: [
                  LineChartBarData(
                    spots: [
                      for (var point in points)
                        FlSpot(point[0].toDouble(), point[1].toDouble()),
                    ],
                    // isCurved: false,
                    color: TreenixColors.primaryPink,
                    barWidth: 3,
                    belowBarData: BarAreaData(show: false),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
