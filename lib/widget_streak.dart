import 'package:Treenix/_colors.dart';
import 'package:flutter/material.dart';

import 'home.dart';

class TreenixStreak extends StatelessWidget {
  final List<Map<String, dynamic>> allActivities;

  final Function(TreenixView) viewStateCallback;

  const TreenixStreak({
    required this.allActivities,
    required this.viewStateCallback,
  });

  int calculateRunningStreak(List<DateTime> runStartTimes, DateTime now) {
    // Normalize the 'now' DateTime to just the date (no time part)
    DateTime today = DateTime(now.year, now.month, now.day);

    // Sort the list in descending order
    runStartTimes.sort((a, b) => b.compareTo(a));

    // Normalize all dates in the list to remove the time part
    List<DateTime> normalizedDates = runStartTimes
        .map((date) => DateTime(date.year, date.month, date.day))
        .toSet() // Remove duplicates (same day runs)
        .toList()
      ..sort((a, b) => b.compareTo(a));

    int streak = 0;

    // Start streak checking
    for (int i = 0; i < normalizedDates.length; i++) {
      if (streak == 0) {
        // Check if the streak starts from today or yesterday
        if (normalizedDates[i] == today ||
            normalizedDates[i] == today.subtract(Duration(days: 1))) {
          streak++;
        }
      } else {
        // Check if the next date is exactly one day before the current date
        if (normalizedDates[i] ==
            normalizedDates[i - 1].subtract(Duration(days: 1))) {
          streak++;
        } else {
          break; // End the streak if a day is skipped
        }
      }
    }

    return streak;
  }

  @override
  Widget build(BuildContext context) {
    List<DateTime> allDates = [];
    for (var activity in allActivities) {
      allDates.add(DateTime.parse(activity['start_date']));
    }
    DateTime today = DateTime.now();

    int streak = calculateRunningStreak(allDates, today);
    print("Streak $streak");

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
              "Streak",
              style: TextStyle(
                fontSize: 20,
                color: TreenixColors.primaryPink,
              ),
            ),
            Text(
              streak.toString(),
              style: TextStyle(
                fontSize: 50,
                color: TreenixColors.primaryPink,
              ),
            ),
            ElevatedButton(
              onPressed: () {
                viewStateCallback(TreenixView.Calendar);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: TreenixColors.lightGray,
              ),
              child: Text(
                "Calendar",
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
