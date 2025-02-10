import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

Map<String, IconData> ikoonid = {
  'cycling': Icons.directions_bike,
  'running': Icons.directions_run,
  'swimming': Icons.pool,
  'skiing': Icons.downhill_skiing,
  'others': Icons.question_mark,
  'walking': Icons.directions_walk,
  'hiking': Icons.hiking_rounded,
};

Map<String, Color> varvid = {
  'cycling': Colors.pink,
  'running': Colors.green,
  'swimming': Colors.purple,
  'skiing': Colors.lightBlue,
  'others': Colors.grey,
  'walking': Colors.grey,
  'hiking': Colors.grey,
};

class CalendarView extends StatelessWidget {
  final Map<DateTime, bool> activityDurations;
  final List<Map<String, dynamic>>
      allActivities; // List of all activities with detailed info
  final int YEAR;
  final bool columns;

  CalendarView({
    required this.activityDurations,
    required this.allActivities,
    required this.YEAR,
    required this.columns,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime(YEAR); //DateTime.now();
    final firstDayOfYear = DateTime(now.year, 1, 1);
    final lastDayOfYear = DateTime(now.year, 12, 31);

    // Adjust the first day to Monday if it isn't already
    DateTime startOfFirstWeek =
        firstDayOfYear.subtract(Duration(days: firstDayOfYear.weekday - 1));
    DateTime endOfLastWeek =
        lastDayOfYear.add(Duration(days: 7 - lastDayOfYear.weekday));

    List<List<DateTime>> weeks = [];
    DateTime currentDay = startOfFirstWeek;

    // Generate weeks
    while (currentDay.isBefore(endOfLastWeek)) {
      List<DateTime> week = List.generate(
        7,
        (index) => DateTime(
            currentDay.add(Duration(days: index)).year,
            currentDay.add(Duration(days: index)).month,
            currentDay.add(Duration(days: index)).day),
      );
      weeks.add(week);
      currentDay = currentDay.add(Duration(days: 7));
    }

    List<List<List<DateTime>>> halves;
    if (columns) {
      halves = [weeks.sublist(0, 26), weeks.sublist(26)];
    } else {
      halves = [weeks];
    }

    return Container(
      width: 1000,
      height: 900,
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: const Color.fromARGB(255, 255, 184, 251)),
      padding: EdgeInsets.all(10),
      // color: const Color.fromARGB(255, 202, 198, 255),
      child: Row(
        children: [
          for (var weekhalf in halves)
            Container(
              width: 480,
              height: 900,
              child: ListView.builder(
                itemCount: weekhalf.length,
                itemBuilder: (context, index) {
                  final week = weekhalf[index];

                  // Calculate stats for the week
                  final weekStats = _calculateWeeklyStats(week);

                  return Row(
                    // crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 220,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: week.map((day) {
                            final isActivityDay = activityDurations.containsKey(
                                DateTime(day.year, day.month, day.day));
                            final isLongActivity = isActivityDay &&
                                activityDurations[
                                    DateTime(day.year, day.month, day.day)]!;

                            return Expanded(
                              child: Container(
                                margin: EdgeInsets.all(1.0),
                                decoration: BoxDecoration(
                                  color: isLongActivity
                                      ? Colors.green
                                      : isActivityDay
                                          ? Colors.yellow
                                          : day.month % 2 == 1
                                              ? Colors.grey[200]
                                              : Colors.grey[300],
                                  borderRadius: BorderRadius.circular(4.0),
                                ),
                                height: 30,
                                child: Center(
                                  child: Text(
                                    '${day.day}',
                                    style: TextStyle(
                                      color: isActivityDay
                                          ? Colors.white
                                          : Colors.black,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      // Iterate through the map
                      // weeklyBarView(weekStats: weekStats),
                      for (var entry in weekStats.entries)
                        if (entry.value > 0) ...[
                          Icon(
                            ikoonid[entry.key],
                            color: Colors.pink,
                            size: 20,
                          ),
                          Text(
                            _formatTime(entry
                                .value), // Use a helper method for formatting
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                        ],
                    ],
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  String _formatTime(int minutes) {
    int hours = minutes ~/ 60; // Calculate hours
    int remainingMinutes = minutes % 60; // Calculate remaining minutes

    return '${hours}:${remainingMinutes.toString().padLeft(2, "0")}';
    // if (hours > 0) {
    //   return '${hours}:${remainingMinutes} min';
    // } else {
    //   return '${remainingMinutes} min';
    // }
  }

  Map<String, int> _calculateWeeklyStats(List<DateTime> week) {
    // Initialize stats for the week
    int cyclingMinutes = 0;
    int runningMinutes = 0;
    int swimmingMinutes = 0;
    int skiingMinutes = 0;
    int walkingMinutes = 0;
    int hikinggMinutes = 0;
    int othersMinutes = 0;
    for (var activity in allActivities) {
      final activityDate = DateTime.parse(activity['start_date']);
      final normalizedDate =
          DateTime(activityDate.year, activityDate.month, activityDate.day);
      if (week.contains(normalizedDate)) {
        final String type = activity['type'];
        final int duration =
            activity['moving_time'] ~/ 60; // Convert seconds to minutes
        switch (type) {
          case 'Ride':
            cyclingMinutes += duration;
            break;
          case 'VirtualRide':
            cyclingMinutes += duration;
            break;
          case 'Run':
            runningMinutes += duration;
            break;
          case 'Swim':
            swimmingMinutes += duration;
            break;
          case 'NordicSki':
            skiingMinutes += duration;
            break;
          case 'Walk':
            walkingMinutes += duration;
            break;
          case 'Hike':
            hikinggMinutes += duration;
            break;
          default:
            othersMinutes += duration;
            break;
        }
      }
    }

    return {
      'cycling': cyclingMinutes,
      'running': runningMinutes,
      'swimming': swimmingMinutes,
      'skiing': skiingMinutes,
      'walking': walkingMinutes,
      'hiking': hikinggMinutes,
      'others': othersMinutes,
    };
  }
}

class weeklyBarView extends StatelessWidget {
  const weeklyBarView({
    super.key,
    required this.weekStats,
  });
  final Map<String, int> weekStats;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 10,
      width: 100,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.start,
          groupsSpace: 0,
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: [
            for (var entry in weekStats.entries)
              if (entry.value > 0) ...[
                BarChartGroupData(
                  x: 0, // Position on the X-axis
                  barRods: [
                    BarChartRodData(
                      toY: 20, // Height of the bar
                      width: entry.value.toDouble() / 3, // Width of the bar
                      // width: 20,
                      color: varvid[entry.key], // Bar color
                      borderRadius: BorderRadius.zero,
                    ),
                  ],
                ),
              ],
          ],
        ),
      ),
    );
  }
}
