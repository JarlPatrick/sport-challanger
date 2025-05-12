import 'package:Treenix/_colors.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

Map<String, IconData> ikoonid = {
  'Ride': Icons.directions_bike,
  'Run': Icons.directions_run,
  'Swim': Icons.pool,
  'NordicSki': Icons.downhill_skiing,
  'Other': Icons.question_mark,
  'Walk': Icons.directions_walk,
  'Hike': Icons.hiking_rounded,
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

class CalendarView extends StatefulWidget {
  // final Map<DateTime, bool> activityDurations;
  final List<Map<String, dynamic>>
      allActivities; // List of all activities with detailed info
  final int YEAR;
  final bool columns;
  final String summaryType;

  CalendarView({
    // required this.activityDurations,
    required this.allActivities,
    required this.YEAR,
    required this.columns,
    required this.summaryType,
  });

  @override
  State<CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends State<CalendarView> {
  // String summaryType = "minutes";

  Text _formatTime(int minutes) {
    if (widget.summaryType == "minutes") {
      int hours = minutes ~/ 60; // Calculate hours
      int remainingMinutes = minutes % 60; // Calculate remaining minutes
      return Text(
        '${hours}:${remainingMinutes.toString().padLeft(2, "0")}', // Use a helper method for formatting
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: TreenixColors.lightGray,
        ),
      );
    }
    if (widget.summaryType == "meters") {
      int hours = minutes ~/ 60; // Calculate hours
      int remainingMinutes = minutes % 60; // Calculate remaining minutes

      return Text(
        '${(minutes / 1000).toStringAsFixed(0)}km', // Use a helper method for formatting
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: TreenixColors.lightGray,
        ),
      );
    }
    return Text(
      "", // Use a helper method for formatting
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.bold,
        color: TreenixColors.lightGray,
      ),
    );
    // if (hours > 0) {
    //   return '${hours}:${remainingMinutes} min';
    // } else {
    //   return '${remainingMinutes} min';
    // }
  }

  String _formatTimeMinutes(int minutes) {
    int hours = minutes ~/ 60; // Calculate hours
    int remainingMinutes = minutes % 60; // Calculate remaining minutes
    return '${hours}:${remainingMinutes.toString().padLeft(2, "0")}';
  }

  Map<DateTime, Map<String, dynamic>> activitiesByDate = {};

  Map<String, Map<String, dynamic>> _calculateWeeklyStats(List<DateTime> week) {
    // Initialize stats for the week
    Map<String, Map<String, dynamic>> allTypes = {
      'Ride': {
        'minutes': 0,
        'meters': 0.0,
        'icon': Icons.directions_bike,
      },
      'VirtualRide': {
        'minutes': 0,
        'meters': 0.0,
        'icon': Icons.directions_bike,
      },
      'Run': {
        'minutes': 0,
        'meters': 0.0,
        'icon': Icons.directions_run,
      },
      'Swim': {
        'minutes': 0,
        'meters': 0.0,
        'icon': Icons.pool,
      },
      'NordicSki': {
        'minutes': 0,
        'meters': 0.0,
        'icon': Icons.downhill_skiing,
      },
      'Walk': {
        'minutes': 0,
        'meters': 0.0,
        'icon': Icons.directions_walk,
      },
      'Hike': {
        'minutes': 0,
        'meters': 0.0,
        'icon': Icons.hiking_rounded,
      },
      'Rowing': {
        'minutes': 0,
        'meters': 0.0,
        'icon': Icons.rowing,
      },
      'Kayaking': {
        'minutes': 0,
        'meters': 0.0,
        'icon': Icons.kayaking,
      },
      'Other': {
        'minutes': 0,
        'meters': 0.0,
        'icon': Icons.question_mark,
      },
    };
    for (var activity in widget.allActivities) {
      final activityDate = DateTime.parse(activity['start_date']);
      final normalizedDate =
          DateTime(activityDate.year, activityDate.month, activityDate.day);
      activitiesByDate[normalizedDate] = activity;
      if (week.contains(normalizedDate)) {
        final String type = activity['type'];
        int duration =
            activity['moving_time'] ~/ 60; // Convert seconds to minutes
        int distance = activity['distance'] ~/ 1;
        if (allTypes.keys.contains(type)) {
          allTypes[type]!["minutes"] += duration;
          allTypes[type]!["meters"] += distance;
        } else {
          allTypes["Other"]!["minutes"] += duration;
          // allTypes["Other"]!["meters"] +=
          //     double.parse(activity['distance'] / 1000);
        }
      }
    }
    return allTypes;
  }

  DateTime expanded = DateTime.now();

  @override
  Widget build(BuildContext context) {
    Map<DateTime, bool> activityDurations = {};

    for (var activity in widget.allActivities) {
      final parsedDate = DateTime.parse(activity['start_date']);
      final normalizedDate =
          DateTime(parsedDate.year, parsedDate.month, parsedDate.day);
      final durationSeconds = activity['elapsed_time'];
      final isLongActivity = durationSeconds > 20 * 60; // 20 minutes

      if (activityDurations.containsKey(normalizedDate)) {
        activityDurations[normalizedDate] =
            activityDurations[normalizedDate]! || isLongActivity;
      } else {
        activityDurations[normalizedDate] = isLongActivity;
      }
    }

    final now = DateTime(widget.YEAR); //DateTime.now();
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
    if (widget.columns) {
      // halves = [weeks.sublist(0, 26), weeks.sublist(26)];
      halves = [
        weeks.sublist(0, 13),
        weeks.sublist(13, 26),
        weeks.sublist(26, 39),
        weeks.sublist(39)
      ];
    } else {
      halves = [weeks];
    }

    return Container(
      width: 1600,
      height: 600,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        // color: const Color.fromARGB(255, 255, 184, 251)),
        color: TreenixColors.grayBackground,
      ),
      padding: EdgeInsets.all(10),
      // color: const Color.fromARGB(255, 202, 198, 255),
      child: Row(
        children: [
          for (var weekhalf in halves)
            Container(
              width: 390,
              height: 900,
              child: ListView.builder(
                itemCount: weekhalf.length,
                itemBuilder: (context, index) {
                  final week = weekhalf[index];

                  bool startnewmonth = false;
                  bool endnewmonth = false;
                  String monthName = "";
                  for (var paev in week) {
                    if (paev.day == 1) {
                      monthName = DateFormat.MMMM().format(paev);
                      if (week.take(4).contains(paev)) {
                        startnewmonth = true;
                      } else {
                        endnewmonth = true;
                      }
                    }
                  }

                  // Calculate stats for the week
                  // final weekStats = _calculateWeeklyStats(week);
                  // weekStats
                  Map<String, Map<String, dynamic>> weekStats = Map.fromEntries(
                      _calculateWeeklyStats(week).entries.toList()
                        ..sort((a, b) => b.value[widget.summaryType]
                            .compareTo(a.value[widget.summaryType])));

                  // Map<String, int> sortedMap = Map.fromEntries(sortedEntries);

                  return Column(
                    children: [
                      if (startnewmonth) ...[
                        SizedBox(height: 5),
                        Text(
                          monthName,
                          style: TextStyle(
                            fontSize: 18,
                            color: TreenixColors.primaryPink,
                          ),
                        ),
                      ],
                      Row(
                        // crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // if (startnewmonth) ...[
                          //   SizedBox(
                          //     width: 25,
                          //     height: 30,
                          //     child: RotatedBox(
                          //       quarterTurns: 3,
                          //       child: Text(
                          //         monthName,
                          //         overflow: TextOverflow.visible,
                          //         softWrap: false,
                          //         maxLines: 1,
                          //         textAlign: TextAlign.right,
                          //         style: TextStyle(
                          //           fontSize: 18,
                          //           color: TreenixColors.primaryPink,
                          //         ),
                          //       ),
                          //     ),
                          //   ),
                          // ] else ...[
                          //   SizedBox(width: 25),
                          // ],
                          Material(
                            color: const Color.fromARGB(0, 255, 255, 255),
                            child: InkWell(
                              onHover: (value) {
                                // print(week.first.toString());
                                setState(() {
                                  if (value) {
                                    expanded = week.first;
                                  } else {
                                    expanded = DateTime.now();
                                  }
                                });

                                // print(value);
                              },
                              onTap: () {
                                // print("tap");
                                // print(week.first.toString());
                                setState(() {
                                  expanded = week.first;
                                });
                              },
                              child: (week.first == expanded)
                                  ? Container(
                                      width: 390,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: week.map((day) {
                                          final isLongActivity =
                                              activityDurations.containsKey(
                                                  DateTime(day.year, day.month,
                                                      day.day));

                                          return Expanded(
                                            child: Container(
                                              margin: EdgeInsets.all(1.0),
                                              decoration: BoxDecoration(
                                                color: isLongActivity
                                                    ? TreenixColors.primaryPink
                                                    : TreenixColors.lightGray,
                                                borderRadius:
                                                    BorderRadius.circular(4.0),
                                              ),
                                              height: 60,
                                              child: Center(
                                                child: Column(
                                                  children: [
                                                    Text(
                                                      '${day.day}',
                                                      style: TextStyle(
                                                        color: isLongActivity
                                                            ? Colors.white
                                                            : Colors.black,
                                                        fontSize: 10,
                                                      ),
                                                    ),
                                                    if (activitiesByDate
                                                        .containsKey(day))
                                                      Column(
                                                        children: [
                                                          Icon(
                                                            ikoonid[
                                                                activitiesByDate[
                                                                        day]![
                                                                    'type']],
                                                            // entry.value["icon"],
                                                            color: Colors.white,
                                                            size: 15,
                                                          ),
                                                          Text(
                                                            _formatTimeMinutes(
                                                                activitiesByDate[
                                                                            day]![
                                                                        'moving_time'] ~/
                                                                    60),
                                                            style: TextStyle(
                                                              fontSize: 10,
                                                              color:
                                                                  Colors.white,
                                                            ),
                                                          ),
                                                          Text(
                                                            "${(activitiesByDate[day]!['distance'] ~/ 1000).toString()} km",
                                                            style: TextStyle(
                                                              color:
                                                                  isLongActivity
                                                                      ? Colors
                                                                          .white
                                                                      : Colors
                                                                          .black,
                                                              fontSize: 10,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    )
                                  : Row(
                                      children: [
                                        Container(
                                          width: 220,
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: week.map((day) {
                                              final isLongActivity =
                                                  activityDurations.containsKey(
                                                      DateTime(day.year,
                                                          day.month, day.day));
                                              // final isLongActivity = isActivityDay &&
                                              //     activityDurations[DateTime(
                                              //         day.year, day.month, day.day)]!;

                                              return Expanded(
                                                child: Container(
                                                  margin: EdgeInsets.all(1.0),
                                                  decoration: BoxDecoration(
                                                    color: isLongActivity
                                                        ? TreenixColors
                                                            .primaryPink
                                                        : TreenixColors
                                                            .lightGray,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            4.0),
                                                  ),
                                                  height: 30,
                                                  child: Center(
                                                    child: Text(
                                                      '${day.day}',
                                                      style: TextStyle(
                                                        color: isLongActivity
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
                                        SizedBox(width: 5),
                                        for (var entry in weekStats.entries
                                            .where((e) =>
                                                e.value[widget.summaryType] > 0)
                                            .take(3))
                                          if (entry.value[widget.summaryType] >
                                              0) ...[
                                            Icon(
                                              // ikoonid[entry.key],
                                              entry.value["icon"],
                                              color: TreenixColors.primaryPink,
                                              size: 20,
                                            ),
                                            _formatTime(
                                                entry.value[widget.summaryType])
                                            // Text(
                                            //   _formatTime(entry.value[
                                            //       widget.summaryType]), // Use a helper method for formatting
                                            //   style: TextStyle(
                                            //     fontSize: 15,
                                            //     fontWeight: FontWeight.bold,
                                            //     color: TreenixColors.lightGray,
                                            //   ),
                                            // ),
                                          ],
                                      ],
                                    ),
                            ),
                          ),
                          // Iterate through the map
                        ],
                      ),
                      if (endnewmonth) ...[
                        SizedBox(height: 5),
                        Text(
                          monthName,
                          style: TextStyle(
                            fontSize: 18,
                            color: TreenixColors.primaryPink,
                          ),
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
}
