import 'package:Treenix/j-indexGraph.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:mapbox_gl/mapbox_gl.dart';
import 'dart:convert';
import 'package:polyline_codec/polyline_codec.dart';
import 'dart:math';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '_colors.dart';
import 'api_dummy.dart';
import 'calendar_view.dart';
import 'j-index.dart';
import 'mapTerraX.dart';
import 'mapView.dart';
import 'secret.dart';
import 'totals.dart';
import 'widget_streak.dart';
import 'yearSelector.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

int YEAR = 2025;

enum TreenixView { Map, Calendar, JGraph }

class _HomeState extends State<Home> {
  final GlobalKey<MapViewState> mapViewKey = GlobalKey<MapViewState>();
  final GlobalKey<MapTerraXState> mapTerraXKey = GlobalKey<MapTerraXState>();

  String? accessToken;
  List<Map<String, dynamic>> _activities = [];
  List<Map<String, dynamic>> _allactivities = [];
  bool calendarView = true;

  bool StravaConnected = true;

  TreenixView viewState = TreenixView.Calendar;

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
    // mapTerraXKey.currentState?.loadYear(year);
    setState(() {
      _activities = activities;
    });
  }

  Future<String> fetchActivityJson() async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = 'my_cached_data';
    final cacheTimeKey = 'my_cached_data_timestamp';
    final now = DateTime.now().millisecondsSinceEpoch;

    if (prefs.containsKey(cacheKey) && prefs.containsKey(cacheTimeKey)) {
      final cachedTime = prefs.getInt(cacheTimeKey)!;
      if (now - cachedTime < Duration(hours: 1).inMilliseconds) {
        return prefs.getString(cacheKey)!;
      }
    }

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
      prefs.setString(cacheKey, response.body);
      prefs.setInt(cacheTimeKey, now);
      return response.body;
    }

    return "";
  }

  Future<void> getActivities() async {
    // try {
    //   String lambdaUrl =
    //       "https://6iks67rav1.execute-api.eu-north-1.amazonaws.com/default/request-all-athletes-activities";
    //   String token = await getToken();

    //   final response = await http.get(
    //     Uri.parse(lambdaUrl),
    //     headers: <String, String>{
    //       "Authorization": token,
    //     },
    //   );

    //   if (response.statusCode == 200) {
    // final activities = jsonDecode(response.body);
    final activities = jsonDecode(await fetchActivityJson());

    List<Map<String, dynamic>> allactivities = [];
    for (var activity in activities) {
      allactivities.add(activity);
    }
    print(allactivities.length);

    setState(() {
      _allactivities = allactivities;
    });
    loadYear(YEAR);
    //   } else {
    //     print("Error: ${response.statusCode} - ${response.body}");
    //   }
    // } catch (e) {
    //   print("Exception: $e");
    // }
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

  void changeViewState(TreenixView state) {
    setState(() {
      viewState = state;
    });
  }

  void setYear(int year) {
    setState(() {
      YEAR = year;
    });
    loadYear(YEAR);
  }

  String summaryType = "minutes";
  void setSummryType(bool minutesTrue) {
    setState(() {
      if (minutesTrue) {
        summaryType = "minutes";
      } else {
        summaryType = "meters";
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    if (StravaConnected) {
      if (screenWidth > 600) {
        return Scaffold(
          backgroundColor: TreenixColors.lightGray,
          body: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Yearselector(
                          YEAR: YEAR,
                          setYearCallback: setYear,
                          setSummryTypeCallback: setSummryType,
                          viewStateCallback: changeViewState,
                        ),
                        SizedBox(width: 20),
                        // if (YEAR == 2025) ...[
                        TreenixStreak(
                          allActivities: _activities,
                          viewStateCallback: changeViewState,
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    JarlsNumber(
                      allActivities: _allactivities,
                      viewStateCallback: changeViewState,
                      year: YEAR,
                    ),
                    SizedBox(height: 20),
                    Row(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(width: 20),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Material(
                            color: TreenixColors.grayBackground,
                            child: InkWell(
                              hoverColor: TreenixColors.primaryPink,
                              onTap: () {
                                GoRouter.of(context).go('/heatmap');
                              },
                              child: Container(
                                width: 190,
                                height: 160,
                                padding: EdgeInsets.all(10),
                                child: Center(
                                  child: Text(
                                    "HEATMAP",
                                    style: TextStyle(
                                      fontSize: 20,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 20),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Material(
                            color: TreenixColors.grayBackground,
                            child: InkWell(
                              hoverColor: TreenixColors.primaryPink,
                              onTap: () {
                                GoRouter.of(context).go('/terrax');
                              },
                              child: Container(
                                width: 190,
                                height: 160,
                                padding: EdgeInsets.all(10),
                                child: Center(
                                  child: Text(
                                    "TERRAX",
                                    style: TextStyle(
                                      fontSize: 20,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 20),
                      ],
                    ),
                    SizedBox(
                      height: 20,
                    ),
                    Totals(allActivities: _activities),
                    SizedBox(
                      height: 20,
                    ),
                  ],
                ),
                switch (viewState) {
                  TreenixView.Calendar => CalendarView(
                      // activityDurations: _activityDurations,
                      allActivities: _activities,
                      YEAR: YEAR,
                      columns: true,
                      summaryType: summaryType,
                    ),
                  TreenixView.Map => MapView(
                      key: mapViewKey,
                      allactivities: _allactivities,
                    ),
                  TreenixView.JGraph => JindexGraph(
                      allactivities: _allactivities,
                      year: YEAR,
                    ),
                  // TreenixView.Test => MapTerraX(
                  //     key: mapTerraXKey,
                  //     allactivities: _allactivities,
                  //   ),
                }
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Container(
                      height: 170,
                      width: (MediaQuery.of(context).size.width - 40) / 3 + 10,
                      child: Yearselector(
                        YEAR: YEAR,
                        setYearCallback: setYear,
                        setSummryTypeCallback: setSummryType,
                        viewStateCallback: changeViewState,
                      ),
                    ),
                    SizedBox(width: 10),
                    Container(
                      height: 170,
                      width: (MediaQuery.of(context).size.width - 40) / 3 - 30,
                      child: TreenixStreak(
                        allActivities: _allactivities,
                        viewStateCallback: changeViewState,
                      ),
                    ),
                    SizedBox(width: 10),
                    Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Material(
                            color: TreenixColors.grayBackground,
                            child: InkWell(
                              hoverColor: TreenixColors.primaryPink,
                              onTap: () {
                                GoRouter.of(context).go('/heatmap');
                              },
                              child: Container(
                                width:
                                    (MediaQuery.of(context).size.width - 40) /
                                            3 -
                                        0,
                                height: 80,
                                padding: EdgeInsets.all(10),
                                child: Center(
                                  child: Text(
                                    "HEATMAP",
                                    style: TextStyle(
                                      fontSize: 20,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Material(
                            color: TreenixColors.grayBackground,
                            child: InkWell(
                              hoverColor: TreenixColors.primaryPink,
                              onTap: () {
                                GoRouter.of(context).go('/terrax');
                              },
                              child: Container(
                                width:
                                    (MediaQuery.of(context).size.width - 40) /
                                            3 -
                                        0,
                                height: 80,
                                padding: EdgeInsets.all(10),
                                child: Center(
                                  child: Text(
                                    "TERRAX",
                                    style: TextStyle(
                                      fontSize: 20,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                    // Container(
                    //   height: 170,
                    //   width: (MediaQuery.of(context).size.width - 40) / 3 + 30,
                    //   child: JarlsNumber(
                    //     allActivities: _allactivities,
                    //     viewStateCallback: changeViewState,
                    //     year: YEAR,
                    //   ),
                    // ),
                  ],
                ),
                SizedBox(height: 10),
                Container(
                  height: MediaQuery.of(context).size.height - 200,
                  width: MediaQuery.of(context).size.width - 20,
                  child: switch (viewState) {
                    TreenixView.Calendar => Column(
                        children: [
                          // Container(
                          //   height: 120,
                          //   width: MediaQuery.of(context).size.width - 20,
                          //   child: Totals(allActivities: _activities),
                          // ),
                          // SizedBox(height: 10),
                          Container(
                            height: MediaQuery.of(context).size.height - 200,
                            width: MediaQuery.of(context).size.width - 20,
                            child: CalendarView(
                              allActivities: _activities,
                              YEAR: YEAR,
                              columns: false,
                              summaryType: summaryType,
                            ),
                          ),
                        ],
                      ),
                    TreenixView.Map => MapView(
                        key: mapViewKey,
                        allactivities: _allactivities,
                      ),
                    TreenixView.JGraph => JindexGraph(
                        allactivities: _allactivities,
                        year: YEAR,
                      ),
                    // TreenixView.Test => Placeholder(),
                  },
                ),
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
