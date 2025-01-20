import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'api_dummy.dart';
import 'secret.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

int YEAR = 2025;

class _HomeState extends State<Home> {
  String? accessToken;
  // final String clientId = '111297'; // Replace with your client ID
  // final String clientSecret = '9165c87e1af5ed7f4d8d5a89c564ae63af97cbc7';
  List<Map<String, dynamic>> _activities = [];

  @override
  void initState() {
    loadAccess();
    // _getActivitiesThisYear();
  }

  void loadAccess() async {
    final tokenUrl = Uri.parse('https://www.strava.com/oauth/token');
    String? authCode = Uri.base.queryParameters['code'];

    // Exchange auth code for access token
    final response = await http.post(
      tokenUrl,
      body: {
        'client_id': CLIENTID,
        'client_secret': CLENTSECRET,
        'code': authCode,
        'grant_type': 'authorization_code',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        accessToken = data['access_token'];
      });

      print('Access Token: $accessToken');

      _getActivitiesThisYear();
    } else {
      print('Failed to get access token: ${response.body}');
    }
  }

  Map<DateTime, bool> _activityDurations =
      {}; // Maps dates to whether activity duration > 20 minutes

  Future<void> _getActivitiesThisYear() async {
    final currentYear = DateTime(YEAR).year; //DateTime.now().year;
    final startDate = DateTime(currentYear, 1, 1).millisecondsSinceEpoch ~/
        1000; // Unix timestamp for Jan 1st
    const int perPage = 100; // Number of activities to fetch per page
    int page = 1;
    bool hasMoreActivities = true;

    Map<DateTime, bool> activityDurations = {};
    List<Map<String, dynamic>> allactivities = [];

    while (hasMoreActivities) {
      final url = Uri.parse(
          'https://www.strava.com/api/v3/athlete/activities?after=$startDate&per_page=$perPage&page=$page');
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      if (response.statusCode == 200) {
        final activities = jsonDecode(response.body) as List;
        // if (true) {
        // final activities = apireturn;
        // hasMoreActivities = false;
        if (activities.isEmpty) {
          hasMoreActivities = false;
        } else {
          for (var activity in activities) {
            allactivities.add(activity);
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
          page++; // Increment page to fetch the next set of activities
        }
      } else {
        print('Failed to fetch activities: ${response.body}');
        hasMoreActivities = false; // Stop fetching on error
      }
    }

    print(allactivities.length);

    setState(() {
      _activityDurations = activityDurations;
      _activities = allactivities;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(title: Text('Activities Calendar')),
      body: Padding(
        padding: const EdgeInsets.all(2.0),
        child: CalendarView(
            activityDurations: _activityDurations, allActivities: _activities),
      ),
    );
  }
}

class CalendarView extends StatelessWidget {
  final Map<DateTime, bool> activityDurations;
  final List<Map<String, dynamic>>
      allActivities; // List of all activities with detailed info

  CalendarView({required this.activityDurations, required this.allActivities});

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

    return Container(
      child: ListView.builder(
        itemCount: weeks.length,
        itemBuilder: (context, index) {
          final week = weeks[index];

          // Calculate stats for the week
          final weekStats = _calculateWeeklyStats(week);

          return Row(
            // crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 500,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: week.map((day) {
                    final isActivityDay = activityDurations
                        .containsKey(DateTime(day.year, day.month, day.day));
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
                        height: 15.5,
                        child: Center(
                          child: Text(
                            '${day.day}',
                            style: TextStyle(
                              color:
                                  isActivityDay ? Colors.white : Colors.black,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              // Iterate through the map
              for (var entry in weekStats.entries)
                if (entry.value > 0) ...[
                  Icon(
                    ikoonid[entry.key],
                    color: Colors.pink,
                    size: 15.5,
                  ),
                  Text(
                    _formatTime(
                        entry.value), // Use a helper method for formatting
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
            ],
          );
        },
      ),
    );
  }

  String _formatTime(int minutes) {
    int hours = minutes ~/ 60; // Calculate hours
    int remainingMinutes = minutes % 60; // Calculate remaining minutes

    if (hours > 0) {
      return '${hours} h ${remainingMinutes} min';
    } else {
      return '${remainingMinutes} min';
    }
  }

  Map<String, IconData> ikoonid = {
    'cycling': Icons.directions_bike,
    'running': Icons.directions_run,
    'swimming': Icons.pool,
    'skiing': Icons.downhill_skiing,
    'others': Icons.question_mark,
    'walking': Icons.directions_walk,
    'hiking': Icons.hiking_rounded,
  };

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
      final activityDate = DateTime.parse(activity['start_date_local']);
      final normalizedDate =
          DateTime(activityDate.year, activityDate.month, activityDate.day);
      if (week.contains(normalizedDate)) {
        final String type = activity['type'];
        final int duration =
            activity['elapsed_time'] ~/ 60; // Convert seconds to minutes
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
            print(type);
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

// class CalendarView extends StatelessWidget {
//   final Map<DateTime, bool> activityDurations;

//   CalendarView({required this.activityDurations});

//   @override
//   Widget build(BuildContext context) {
//     final now = DateTime.now();
//     final firstDayOfYear = DateTime(now.year, 1, 1);
//     final lastDayOfYear = DateTime(now.year, 12, 31);

//     // Adjust the first day to Monday if it isn't already
//     DateTime startOfFirstWeek =
//         firstDayOfYear.subtract(Duration(days: firstDayOfYear.weekday - 1));
//     DateTime endOfLastWeek =
//         lastDayOfYear.add(Duration(days: 7 - lastDayOfYear.weekday));

//     List<List<DateTime>> weeks = [];
//     DateTime currentDay = startOfFirstWeek;

//     // Generate weeks
//     while (currentDay.isBefore(endOfLastWeek)) {
//       List<DateTime> week = List.generate(
//         7,
//         (index) => currentDay.add(Duration(days: index)),
//       );
//       weeks.add(week);
//       currentDay = currentDay.add(Duration(days: 7));
//     }

//     return Container(
//       width: 600,
//       child: ListView.builder(
//         itemCount: weeks.length,
//         itemBuilder: (context, index) {
//           final week = weeks[index];

//           return Padding(
//             padding: const EdgeInsets.symmetric(vertical: 1.0),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: week.map((day) {
//                 final isActivityDay = activityDurations
//                     .containsKey(DateTime(day.year, day.month, day.day));
//                 final isLongActivity = isActivityDay &&
//                     activityDurations[DateTime(day.year, day.month, day.day)]!;

//                 return Expanded(
//                   child: Container(
//                     margin: EdgeInsets.all(1.0),
//                     decoration: BoxDecoration(
//                       color: isLongActivity
//                           ? Colors.green
//                           : isActivityDay
//                               ? Colors.yellow
//                               : Colors.grey[200],
//                       borderRadius: BorderRadius.circular(4.0),
//                     ),
//                     height: 20.0,
//                     child: Center(
//                       child: Text(
//                         '${day.day}',
//                         style: TextStyle(
//                           color: isActivityDay ? Colors.white : Colors.black,
//                           fontSize: 12,
//                         ),
//                       ),
//                     ),
//                   ),
//                 );
//               }).toList(),
//             ),
//           );
//         },
//       ),
//     );
//   }
// }

extension on DateTime {
  bool get isLeapYear {
    if (this.year % 4 != 0) return false;
    if (this.year % 100 == 0 && this.year % 400 != 0) return false;
    return true;
  }
}
