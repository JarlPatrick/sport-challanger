import 'package:Treenix/_colors.dart';
import 'package:Treenix/home.dart';
import 'package:flutter/material.dart';

class JarlsNumber extends StatelessWidget {
  final List<Map<String, dynamic>>
      allActivities; // List of all activities with detailed info

  final Function(TreenixView) viewStateCallback;

  JarlsNumber({
    required this.allActivities,
    required this.viewStateCallback,
  });

  int findLargestX(List<int> items) {
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
    List<int> Times = [];
    for (var activity in allActivities) {
      int durationSeconds = activity['moving_time'] ~/ 60;
      Times.add(durationSeconds);
    }
    int JN = findLargestX(Times);
    return Container(
      height: 160,
      width: 200,
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: TreenixColors.grayBackground,
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          children: [
            Text(
              "J-index",
              style: TextStyle(
                fontSize: 20,
                color: TreenixColors.primaryPink,
              ),
            ),
            Text(
              JN.toString(),
              style: TextStyle(
                fontSize: 50,
                color: TreenixColors.primaryPink,
              ),
            ),
            ElevatedButton(
              onPressed: () {
                viewStateCallback(TreenixView.JGraph);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: TreenixColors.lightGray,
              ),
              child: Text(
                "Graph",
                style: TextStyle(
                  fontSize: 13,
                  color: TreenixColors.primaryPink,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
