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
            ),
            SizedBox(
              width: 30,
            ),
            Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                SizedBox(height: 30),
                ElevatedButton(
                    onPressed: () {
                      YEAR = 2023;
                      _getActivitiesThisYear();
                    },
                    child: Text("2023", style: TextStyle(fontSize: 30))),
                SizedBox(height: 30),
                ElevatedButton(
                    onPressed: () {
                      YEAR = 2024;
                      _getActivitiesThisYear();
                    },
                    child: Text("2024", style: TextStyle(fontSize: 30))),
                SizedBox(height: 30),
                ElevatedButton(
                    onPressed: () {
                      YEAR = 2025;
                      _getActivitiesThisYear();
                    },
                    child: Text("2025", style: TextStyle(fontSize: 30))),
                SizedBox(height: 30),
                JarlsNumber(allActivities: _activities),
                SizedBox(height: 30),
                Totals(allActivities: _activities),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
