import 'package:flutter/material.dart';

class JarlsNumber extends StatelessWidget {
  final List<Map<String, dynamic>>
      allActivities; // List of all activities with detailed info

  JarlsNumber({
    required this.allActivities,
  });

  int findLargestX(List<int> items) {
    // Sort the list in descending order
    items.sort((a, b) => b.compareTo(a));

    // Find the largest X
    for (int i = 0; i < items.length; i++) {
      if (i + 1 >= items[i]) {
        return i;
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
      height: 200,
      width: 200,
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: const Color.fromARGB(255, 255, 184, 251),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          children: [
            Text(
              "J-index",
              style: TextStyle(fontSize: 20),
            ),
            Text(
              JN.toString(),
              style: TextStyle(fontSize: 50),
            ),
            Text(
              "You have $JN activities that last longer that $JN minutes",
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
