import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:polyline_codec/polyline_codec.dart';
import 'dart:math';

import 'api_dummy.dart';
import 'calendar_view.dart';
import 'j-index.dart';
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
  String? accessToken;
  List<Map<String, dynamic>> _activities = [];
  bool calendarView = true;

  @override
  void initState() {
    loadAccess();
    // _getActivitiesThisYear();
  }

  MapboxMapController? controller;
  void _onMapCreated(MapboxMapController controller) {
    this.controller = controller;
  }

  void _onStyleLoaded() async {
    addLinesToMap(_activities);
  }

  void loadAccess() async {
    final tokenUrl = Uri.parse('https://www.strava.com/oauth/token');
    String? authCode = Uri.base.queryParameters['code'];

    getStravaAccessToken(authCode!);
    // Exchange auth code for access token
    // final response = await http.post(
    //   tokenUrl,
    //   body: {
    //     'client_id': CLIENTID,
    //     'client_secret': CLENTSECRET,
    //     'code': authCode,
    //     'grant_type': 'authorization_code',
    //   },
    // );

    // if (response.statusCode == 200) {
    //   final data = jsonDecode(response.body);
    //   setState(() {
    //     accessToken = data['access_token'];
    //   });

    //   print('Access Token: $accessToken');

    //   _getActivitiesThisYear();
    // } else {
    //   print('Failed to get access token: ${response.body}');
    // }
  }

  Future<String?> getStravaAccessToken(String code) async {
    String lambdaUrl =
        "https://1t13kva7le.execute-api.eu-north-1.amazonaws.com/default/strava-get-access-token";
    try {
      final response = await http.post(
        Uri.parse(lambdaUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"code": code}),
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

  /// Check if the polyline is closed
  bool isClosed(List<LatLng> points, double thresholdMeters) {
    if (points.length < 3) return false;

    double distance = haversineDistance(points.first, points.last);
    return distance < thresholdMeters;
  }

  /// Compute the enclosed area using the Shoelace formula
  double calculateEnclosedArea(List<LatLng> points) {
    if (points.length < 3) return 0.0; // Not a polygon

    double sum = 0.0;
    for (int i = 0; i < points.length - 1; i++) {
      sum += (points[i].longitude * points[i + 1].latitude) -
          (points[i + 1].longitude * points[i].latitude);
    }

    // Closing segment
    sum += (points.last.longitude * points.first.latitude) -
        (points.first.longitude * points.last.latitude);

    return (sum.abs() / 2.0) *
        111319.9 *
        111319.9; // Convert degrees to square meters
  }

  /// Haversine formula to compute distance between two LatLng points
  double haversineDistance(LatLng p1, LatLng p2) {
    const double R = 6371000; // Earth radius in meters
    double lat1 = radians(p1.latitude);
    double lon1 = radians(p1.longitude);
    double lat2 = radians(p2.latitude);
    double lon2 = radians(p2.longitude);

    double dLat = lat2 - lat1;
    double dLon = lon2 - lon1;

    double a =
        pow(sin(dLat / 2), 2) + cos(lat1) * cos(lat2) * pow(sin(dLon / 2), 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return R * c;
  }

  /// Convert degrees to radians
  double radians(double degrees) {
    return degrees * pi / 180;
  }

  List<LatLng> PolylineToLatLng(String polyline) {
    List<List<num>> points = PolylineCodec.decode(polyline);
    return points.map((p) => LatLng(p[0].toDouble(), p[1].toDouble())).toList();
  }

  void addLinesToMap(List<Map<String, dynamic>> activities) {
    for (var act in activities) {
      String poly = act["map"]["summary_polyline"];
      if (poly != "") {
        List<LatLng> langs = PolylineToLatLng(poly);
        if (controller == null) {
          print("Error: MapController is null");
          return;
        }
        if (isClosed(langs, 100.0)) {
          // 10 meters threshold
          double area = calculateEnclosedArea(langs) / (1000 * 1000);
          print("Enclosed Area: ${area.toStringAsFixed(1)} km^2");
        } else {
          print("The polyline is not closed.");
        }
        controller!.addLine(
          LineOptions(
            geometry: langs!,
            lineColor: "#FF0000",
            lineWidth: 3.0,
          ),
        );
      }
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

    addLinesToMap(allactivities);
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth > 600) {
      return Scaffold(
        body: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: [
              !calendarView
                  ? Container(
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10)),
                      width: 1000,
                      height: 900,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: MapboxMap(
                          styleString: MapboxStyles.DARK,
                          initialCameraPosition: const CameraPosition(
                            target:
                                // LatLng(59.46706512548259, 24.824713815561047),
                                LatLng(58.810327075722086, 25.12594825181547),
                            zoom: 6.7,
                          ),
                          accessToken:
                              "pk.eyJ1IjoicmE1bXU1IiwiYSI6ImNremp1ZGwydjBwNGIybmxsNmpiMG1pZHoifQ.B6kcgUxR8ljeGPpYDw1ImA",
                          onMapCreated: _onMapCreated,
                          onStyleLoadedCallback: _onStyleLoaded,
                        ),
                      ),
                    )
                  : CalendarView(
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
                            if (controller != null) {
                              controller!.clearLines();
                            }
                            setState(() {
                              YEAR = YEAR - 1;
                            });
                            _getActivitiesThisYear();
                          },
                          child: Text("-", style: TextStyle(fontSize: 30))),
                      Text(YEAR.toString(), style: TextStyle(fontSize: 30)),
                      ElevatedButton(
                          onPressed: () {
                            if (controller != null) {
                              controller!.clearLines();
                            }
                            setState(() {
                              YEAR = YEAR + 1;
                            });
                            _getActivitiesThisYear();
                          },
                          child: Text("+", style: TextStyle(fontSize: 30))),
                    ],
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        calendarView = !calendarView;
                      });
                    },
                    child: Text("Toggle Calendar/Map",
                        style: TextStyle(fontSize: 30)),
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
