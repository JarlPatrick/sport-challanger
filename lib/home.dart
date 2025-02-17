import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mapbox_gl/mapbox_gl.dart';
import 'dart:convert';
import 'package:polyline_codec/polyline_codec.dart';
import 'dart:math';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '_colors.dart';
import 'api_dummy.dart';
import 'calendar_view.dart';
import 'j-index.dart';
import 'mapView.dart';
import 'secret.dart';
import 'totals.dart';
import 'widget_streak.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

int YEAR = 2025;

class _HomeState extends State<Home> {
  final GlobalKey<MapViewState> mapViewKey = GlobalKey<MapViewState>();

  String? accessToken;
  List<Map<String, dynamic>> _activities = [];
  List<Map<String, dynamic>> _allactivities = [];
  bool calendarView = true;

  bool StravaConnected = true;

  @override
  void initState() {
    loadAccess();
  }

  void loadAccess() async {
    // final tokenUrl = Uri.parse('https://www.strava.com/oauth/token');
    String? authCode = Uri.base.queryParameters['code'];

    String? access_token;
    if (authCode != null) {
      access_token = await getStravaAccessToken(authCode);
    } else {
      access_token = await getStravaAccessToken("");
    }

    if (access_token != null) {
      setState(() {
        accessToken = access_token;
      });
      // _getActivitiesThisYear();
      getActivities();
    } else {
      setState(() {
        StravaConnected = false;
      });
    }
  }

  Future<String> getToken() async {
    final result = await Amplify.Auth.fetchAuthSession();
    // print(result);
    // print("");
    var a = result.toString().split("idToken")[1];
    var b = a.split('"')[2];
    var token = b.split('\"')[0];
    return token;
  }

  Future<String?> getStravaAccessToken(String code) async {
    String lambdaUrl =
        "https://6iks67rav1.execute-api.eu-north-1.amazonaws.com/default/strava-get-access-token";
    try {
      String token = await getToken();

      final response = await http.post(
        Uri.parse(lambdaUrl),
        headers: <String, String>{
          "Authorization": token,
        },
        body: jsonEncode({
          "code": code,
        }),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print(data);
        return data["access_token"];
      } else {
        print("Error: ${response.statusCode} - ${response.body}");
        return null;
      }
    } catch (e) {
      print("Exception: $e");
      return null;
    }
  }

  Map<DateTime, bool> _activityDurations =
      {}; // Maps dates to whether activity duration > 20 minutes

  Future<void> loadYear(int year) async {
    List<Map<String, dynamic>> activities = [];
    for (var activity in _allactivities) {
      final parsedDate = DateTime.parse(activity['start_date']);
      if (parsedDate.year == year) {
        activities.add(activity);
      }
    }
    mapViewKey.currentState?.loadYear(year);
    setState(() {
      _activities = activities;
    });
  }

  Future<void> _getActivitiesThisYear() async {
    getActivities();
    List<Map<String, dynamic>> activitiesThisYear = [];
    // for (var activity in _) return;
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
        //   print(activities);
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

    // addLinesToMap(allactivities);
  }

  Future<void> getActivities() async {
    try {
      String lambdaUrl =
          "https://6iks67rav1.execute-api.eu-north-1.amazonaws.com/default/request-all-athletes-activities";
      String token = await getToken();

      final response = await http.get(
        Uri.parse(lambdaUrl),
        headers: <String, String>{
          "Authorization": token,
        },
      );

      if (response.statusCode == 200) {
        final activities = jsonDecode(response.body);

        Map<DateTime, bool> activityDurations = {};
        List<Map<String, dynamic>> allactivities = [];

        for (var activity in activities) {
          allactivities.add(activity);
          final parsedDate = DateTime.parse(activity['start_date']);
          // print(parsedDate);
          final normalizedDate =
              DateTime(parsedDate.year, parsedDate.month, parsedDate.day);
          final durationSeconds = activity['moving_time'];
          // print(durationSeconds);
          final isLongActivity = durationSeconds > 20 * 60; // 20 minutes

          if (activityDurations.containsKey(normalizedDate)) {
            activityDurations[normalizedDate] =
                activityDurations[normalizedDate]! || isLongActivity;
          } else {
            activityDurations[normalizedDate] = isLongActivity;
          }
        }

        print(allactivities.length);

        setState(() {
          _activityDurations = activityDurations;
          _allactivities = allactivities;
        });
        loadYear(YEAR);
      } else {
        print("Error: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      print("Exception: $e");
    }
  }

  Future<void> _authenticate() async {
    // Generate Strava OAuth URL
    final String redirectUri =
        'https://treenix.ee/'; // Replace with your redirect URI
    final authUrl = Uri.parse('https://www.strava.com/oauth/mobile/authorize?'
        'client_id=$CLIENTID&response_type=code&redirect_uri=$redirectUri&approval_prompt=auto&scope=read,activity:read_all');

    // Open the URL in the browser
    await launchUrl(authUrl);
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    if (StravaConnected) {
      if (screenWidth > 600) {
        return Scaffold(
          backgroundColor: TreenixColors.lightGray,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(width: 30),
                    Container(
                      height: 160,
                      width: 400,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: TreenixColors.grayBackground,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: TreenixColors.lightGray,
                                ),
                                onPressed: () {
                                  setState(() {
                                    YEAR = YEAR - 1;
                                  });
                                  loadYear(YEAR);
                                  // _getActivitiesThisYear();
                                },
                                child: Text(
                                  "-",
                                  style: TextStyle(
                                    fontSize: 40,
                                    color: TreenixColors.primaryPink,
                                  ),
                                ),
                              ),
                              SizedBox(width: 15),
                              Text(
                                YEAR.toString(),
                                style: TextStyle(
                                  fontSize: 40,
                                  color: TreenixColors.primaryPink,
                                ),
                              ),
                              SizedBox(width: 15),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: TreenixColors.lightGray,
                                ),
                                onPressed: () {
                                  setState(() {
                                    YEAR = YEAR + 1;
                                  });
                                  loadYear(YEAR);
                                },
                                child: Text(
                                  "+",
                                  style: TextStyle(
                                    fontSize: 40,
                                    color: TreenixColors.primaryPink,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 20),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: TreenixColors.lightGray,
                            ),
                            onPressed: () {
                              setState(() {
                                calendarView = !calendarView;
                              });
                            },
                            child: Text(
                              "Toggle Calendar/Map",
                              style: TextStyle(
                                fontSize: 25,
                                color: TreenixColors.primaryPink,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // ElevatedButton(
                    //     onPressed: () {
                    //       getActivities();
                    //     },
                    //     child: Text("PING")),
                    SizedBox(width: 20),
                    // if (YEAR == 2025) ...[
                    TreenixStreak(allActivities: _activities),
                    SizedBox(width: 20),
                    // ],
                    JarlsNumber(allActivities: _activities),
                    SizedBox(width: 20),
                    Totals(allActivities: _activities),
                  ],
                ),
                SizedBox(
                  height: 20,
                ),
                !calendarView
                    ? MapView(
                        key: mapViewKey,
                        allactivities: _allactivities,
                      )
                    : CalendarView(
                        activityDurations: _activityDurations,
                        allActivities: _activities,
                        YEAR: YEAR,
                        columns: true,
                      ),
              ],
            ),
          ),
        );
      } else {
        return Scaffold(
          backgroundColor: TreenixColors.lightGray,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.max,
              children: [
                SizedBox(height: 10),
                Container(
                  height: 120,
                  width: MediaQuery.of(context).size.width - 20,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: TreenixColors.grayBackground,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: TreenixColors.lightGray,
                            ),
                            onPressed: () {
                              setState(() {
                                YEAR = YEAR - 1;
                              });
                              loadYear(YEAR);
                              // _getActivitiesThisYear();
                            },
                            child: Text(
                              "-",
                              style: TextStyle(
                                fontSize: 40,
                                color: TreenixColors.primaryPink,
                              ),
                            ),
                          ),
                          SizedBox(width: 15),
                          Text(
                            YEAR.toString(),
                            style: TextStyle(
                              fontSize: 40,
                              color: TreenixColors.primaryPink,
                            ),
                          ),
                          SizedBox(width: 15),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: TreenixColors.lightGray,
                            ),
                            onPressed: () {
                              setState(() {
                                YEAR = YEAR + 1;
                              });
                              loadYear(YEAR);
                            },
                            child: Text(
                              "+",
                              style: TextStyle(
                                fontSize: 40,
                                color: TreenixColors.primaryPink,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: TreenixColors.lightGray,
                        ),
                        onPressed: () {
                          setState(() {
                            calendarView = !calendarView;
                          });
                        },
                        child: Text(
                          "Toggle Calendar/Map",
                          style: TextStyle(
                            fontSize: 25,
                            color: TreenixColors.primaryPink,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 10),
                if (!calendarView) ...[
                  Container(
                    height: MediaQuery.of(context).size.height - 150,
                    width: MediaQuery.of(context).size.width - 20,
                    child: MapView(
                      key: mapViewKey,
                      allactivities: _allactivities,
                    ),
                  )
                ] else ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Container(
                        // height: 140,
                        width: (MediaQuery.of(context).size.width - 30) / 2,
                        child: TreenixStreak(allActivities: _activities),
                      ),
                      SizedBox(width: 10),
                      Container(
                        // height: 140,
                        width: (MediaQuery.of(context).size.width - 30) / 2,
                        child: JarlsNumber(allActivities: _activities),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  Container(
                    height: 120,
                    width: MediaQuery.of(context).size.width - 20,
                    child: Totals(allActivities: _activities),
                  ),
                  SizedBox(height: 10),
                  Container(
                    height: MediaQuery.of(context).size.height - 460,
                    width: MediaQuery.of(context).size.width - 20,
                    child: CalendarView(
                      activityDurations: _activityDurations,
                      allActivities: _activities,
                      YEAR: YEAR,
                      columns: false,
                    ),
                  ),
                  SizedBox(height: 10),
                ]
              ],
            ),
          ),
        );
      }
    } else {
      return Scaffold(
        body: Container(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Treenix?', style: TextStyle(fontSize: 30)),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => _authenticate(),
                  child: Text(
                    'START',
                    style: TextStyle(fontSize: 30),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }
}
