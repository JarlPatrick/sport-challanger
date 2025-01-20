import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'secret.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  String? accessToken;
  // final String clientId = '111297'; // Replace with your client ID
  // final String clientSecret = '9165c87e1af5ed7f4d8d5a89c564ae63af97cbc7';
  List<Map<String, dynamic>> _activities = [];

  @override
  void initState() {
    loadAccess();
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
    final currentYear = DateTime(2024).year; //DateTime.now().year;
    final startDate = DateTime(currentYear, 1, 1).millisecondsSinceEpoch ~/
        1000; // Unix timestamp for Jan 1st

    final url = Uri.parse(
        'https://www.strava.com/api/v3/athlete/activities?after=$startDate');
    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode == 200) {
      final activities = jsonDecode(response.body);
      print(activities.length);
      setState(() {
        _activityDurations = {};
        for (var activity in activities) {
          final parsedDate = DateTime.parse(activity['start_date']);
          final normalizedDate =
              DateTime(parsedDate.year, parsedDate.month, parsedDate.day);
          final durationSeconds = activity['elapsed_time'];
          final isLongActivity = durationSeconds > 20 * 60; // 20 minutes
          if (_activityDurations.containsKey(normalizedDate)) {
            // If a date already exists, ensure we mark it as long if any activity is long
            _activityDurations[normalizedDate] =
                _activityDurations[normalizedDate]! || isLongActivity;
          } else {
            _activityDurations[normalizedDate] = isLongActivity;
          }
        }
      });
    } else {
      print('Failed to fetch activities: ${response.body}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Activities Calendar')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: CalendarView(activityDurations: _activityDurations),
      ),
    );
  }
}

class CalendarView extends StatelessWidget {
  final Map<DateTime, bool> activityDurations;

  CalendarView({required this.activityDurations});

  @override
  Widget build(BuildContext context) {
    final now = DateTime(2024); //DateTime.now();
    final months =
        List.generate(12, (index) => DateTime(now.year, index + 1, 1));

    List<String> kuud = [
      "Jaanuar",
      "Veebruar",
      "Märts",
      "Aprill",
      "Mai",
      "Juuni",
      "Juuli",
      "August",
      "September",
      "Oktoober",
      "November",
      "Detsember"
    ];

    return ListView.builder(
      itemCount: months.length,
      itemBuilder: (context, index) {
        final firstDayOfMonth = months[index];
        final daysInMonth = List.generate(
          DateTime(firstDayOfMonth.year, firstDayOfMonth.month + 1, 0).day,
          (dayIndex) => DateTime(
              firstDayOfMonth.year, firstDayOfMonth.month, dayIndex + 1),
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GridView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              gridDelegate:
                  SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 31),
              itemCount: daysInMonth.length,
              itemBuilder: (context, dayIndex) {
                final day = daysInMonth[dayIndex];
                final isActivityDay = activityDurations
                    .containsKey(DateTime(day.year, day.month, day.day));
                final isLongActivity = isActivityDay &&
                    activityDurations[DateTime(day.year, day.month, day.day)]!;

                return Container(
                  margin: EdgeInsets.all(2.0),
                  decoration: BoxDecoration(
                    color: isLongActivity
                        ? Colors.green
                        : isActivityDay
                            ? Colors.yellow
                            : Colors.grey[200],
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                  child: Center(
                    child: Text(
                      '${day.day}',
                      style: TextStyle(
                        color: isActivityDay ? Colors.white : Colors.black,
                        fontSize: 12,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

extension on DateTime {
  bool get isLeapYear {
    if (this.year % 4 != 0) return false;
    if (this.year % 100 == 0 && this.year % 400 != 0) return false;
    return true;
  }
}
