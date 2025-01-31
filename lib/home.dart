import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'api_dummy.dart';
import 'calendar_view.dart';
import 'j-index.dart';
import 'secret.dart';
import 'totals.dart';

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
    final endDate =
        DateTime(currentYear + 1, 1, 1).millisecondsSinceEpoch ~/ 1000;
    print(startDate);
    const int perPage = 100; // Number of activities to fetch per page
    int page = 1;
    bool hasMoreActivities = true;

    Map<DateTime, bool> activityDurations = {};
    List<Map<String, dynamic>> allactivities = [];

    while (hasMoreActivities) {
      final url = Uri.parse(
          'https://www.strava.com/api/v3/athlete/activities?after=$startDate&before=$endDate&per_page=$perPage&page=$page');
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      if (response.statusCode == 200) {
        final activities = jsonDecode(response.body) as List;
        // if (true) {
        //   final activities = apireturn;
        //   hasMoreActivities = false;
        if (activities.isEmpty) {
          hasMoreActivities = false;
        } else {
          for (var activity in activities) {
            allactivities.add(activity);
            final parsedDate = DateTime.parse(activity['start_date']);
            final normalizedDate =
                DateTime(parsedDate.year, parsedDate.month, parsedDate.day);
            final durationSeconds = activity['moving_time'];
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
    double screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth > 600) {
      return Scaffold(
        // appBar: AppBar(title: Text('Activities Calendar')),
        body: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: [
              CalendarView(
                activityDurations: _activityDurations,
                allActivities: _activities,
                YEAR: YEAR,
                columns: true,
              ),
              SizedBox(
                width: 30,
              ),
              Column(
                mainAxisSize: MainAxisSize.max,
                children: [
                  SizedBox(height: 30),
                  Row(
                    children: [
                      ElevatedButton(
                          onPressed: () {
                            setState(() {
                              YEAR = YEAR - 1;
                            });
                            _getActivitiesThisYear();
                          },
                          child: Text("-", style: TextStyle(fontSize: 30))),
                      Text(YEAR.toString(), style: TextStyle(fontSize: 30)),
                      ElevatedButton(
                          onPressed: () {
                            setState(() {
                              YEAR = YEAR + 1;
                            });
                            _getActivitiesThisYear();
                          },
                          child: Text("+", style: TextStyle(fontSize: 30))),
                    ],
                  ),
                  SizedBox(height: 20),
                  if (YEAR == 2025) ...[
                    TreenixStreak(allActivities: _activities),
                    SizedBox(height: 20),
                  ],
                  JarlsNumber(allActivities: _activities),
                  SizedBox(height: 20),
                  Totals(allActivities: _activities),
                ],
              ),
            ],
          ),
        ),
      );
    } else {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.max,
            children: [
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.max,
                children: [
                  TreenixStreak(allActivities: _activities),
                  SizedBox(width: 10),
                  JarlsNumber(allActivities: _activities),
                ],
              ),
              SizedBox(height: 10),
              // SizedBox(height: 10),
              Container(
                height: 400,
                width: 400,
                child: CalendarView(
                  activityDurations: _activityDurations,
                  allActivities: _activities,
                  YEAR: YEAR,
                  columns: false,
                ),
              ),
              SizedBox(height: 10),
              Totals(allActivities: _activities),
            ],
          ),
        ),
      );
    }
  }
}

class TreenixStreak extends StatelessWidget {
  final List<Map<String, dynamic>> allActivities;

  const TreenixStreak({
    required this.allActivities,
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
        color: const Color.fromARGB(255, 255, 184, 251),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          children: [
            Text(
              "Streak",
              style: TextStyle(fontSize: 20),
            ),
            Text(
              streak.toString(),
              style: TextStyle(fontSize: 50),
            ),
          ],
        ),
      ),
    );
  }
}
