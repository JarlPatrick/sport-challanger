import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:mapbox_gl/mapbox_gl.dart';
import 'dart:convert';
import 'package:polyline_codec/polyline_codec.dart';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:flutter_map/flutter_map.dart';
import 'dart:html' as html;

import '_colors.dart';

class MapHeatmap extends StatefulWidget {
  // final List<Map<String, dynamic>> allactivities;
  const MapHeatmap({
    super.key,
    // required this.allactivities,
  });

  @override
  State<MapHeatmap> createState() => MapHeatmapState();
}

// enum TerraxMapType { loading, all, onfoot }

class MapHeatmapState extends State<MapHeatmap> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    load();
  }

  // TerraxMapType mapType = TerraxMapType.loading;

  List<Map<String, dynamic>> _allactivities = [];
  DateTime zeroDate = DateTime.now();
  DateTime startDate = DateTime.now();
  DateTime endDate = DateTime.now();
  double startValue = 0;
  double endValue = 1;
  double minDays = 0;
  double maxDays = 1;

  void load() async {
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
      print("LOADED");
      final activities = jsonDecode(response.body);

      List<Map<String, dynamic>> allactivities = [];

      for (var activity in activities) {
        allactivities.add(activity);
        if (DateTime.parse(activity['start_date']).isBefore(zeroDate)) {
          zeroDate = DateTime.parse(activity['start_date']);
        }
      }

      setState(() {
        _allactivities = allactivities;
        startDate = zeroDate;
        endValue = endDate.difference(startDate).inDays.toDouble();
        maxDays = endValue;
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

  List<ll.LatLng> PolylineToLatLng(String polyline) {
    List<List<num>> points = PolylineCodec.decode(polyline);
    return points
        .map((p) => ll.LatLng(p[0].toDouble(), p[1].toDouble()))
        .toList();
  }

  final LayerHitNotifier hitNotifier = ValueNotifier(null);
  String activityName = "";
  String stravaID = "";
  List<int> idList = [];

  String _formatTime(int minutes) {
    int hours = minutes ~/ 60; // Calculate hours
    int remainingMinutes = minutes % 60; // Calculate remaining minutes

    return '${hours} h:${remainingMinutes.toString().padLeft(2, "0")} min';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            // decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            child: FlutterMap(
              options: MapOptions(
                initialCenter: ll.LatLng(58.710327075722086, 25.12594825181547),
                // initialCenter:
                //     LatLng(51.509364, -0.128928), // Center the map over London
                initialZoom: 8,
                onTap: (tapPosition, point) {},
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      // 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
                      // "https://{s}.basemaps.cartocdn.com/dark_nolabels/{z}/{x}/{y}{r}.png",
                      "https://{s}.basemaps.cartocdn.com/light_nolabels/{z}/{x}/{y}{r}.png",
                  subdomains: ['a', 'b', 'c'],
                  userAgentPackageName: 'com.example.app',
                ),
                // Inside the map build...
                MouseRegion(
                  hitTestBehavior: HitTestBehavior.deferToChild,
                  cursor: SystemMouseCursors
                      .click, // Use a special cursor to indicate interactivity
                  child: GestureDetector(
                    onTap: () {
                      print("hit");
                      print(hitNotifier.value?.hitValues);
                      int id = hitNotifier.value!.hitValues.first as int;
                      idList = [];
                      hitNotifier.value!.hitValues.forEach((element) {
                        idList.add(int.parse(element.toString()));
                      });

                      setState(() {
                        // idList = hitNotifier.value!.hitValues as List<int>;
                        // activityName = utf8
                        //     .decode(latin1.encode(_allactivities[id]["name"]));
                        // stravaID = _allactivities[id]["strava_activity_id"];
                      });
                    },
                    // And/or any other gesture callback
                    child: PolylineLayer(
                      hitNotifier: hitNotifier,
                      polylines: [
                        for (var act in _allactivities)
                          if (DateTime.parse(act['start_date'])
                                  .isBefore(endDate) &&
                              DateTime.parse(act['start_date'])
                                  .isAfter(startDate))
                            Polyline(
                              // hitValue: utf8.decode(latin1.encode(act['name'])),
                              hitValue: _allactivities.indexOf(act),
                              points: PolylineToLatLng(act["map_polyline"]),
                              color: TreenixColors.primaryPink,
                            )
                      ],
                    ),
                  ),
                ),
                // PolylineLayer(
                //   hitNotifier: hitNotifier,
                //   polylines: [
                //     for (var act in _allactivities)
                //       if (DateTime.parse(act['start_date']).isBefore(endDate) &&
                //           DateTime.parse(act['start_date']).isAfter(startDate))
                //         Polyline(
                //           hitValue: act['name'],
                //           points: PolylineToLatLng(act["map_polyline"]),
                //           color: TreenixColors.primaryPink,
                //         )
                //   ],
                // ),
              ],
            ),
          ),
          Positioned(
            left: 50,
            top: 50,
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Material(
                    color: const Color.fromARGB(50, 45, 45, 45),
                    child: InkWell(
                      hoverColor: TreenixColors.primaryPink,
                      onTap: () {
                        GoRouter.of(context).go('/');
                      },
                      child: Container(
                        width: 250,
                        // height: 40,
                        padding: EdgeInsets.all(10),
                        child: Center(
                          child: Text(
                            "HOME",
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
                Container(
                  height: MediaQuery.of(context).size.height - 200,
                  width: 250,
                  // decoration: BoxDecoration(
                  //   borderRadius: BorderRadius.circular(10),
                  //   color: const Color.fromARGB(50, 45, 45, 45),
                  // ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: const Color.fromARGB(50, 45, 45, 45),
                      ),
                      child: Column(
                        children: [
                          for (int i in idList) ...[
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Material(
                                color: const Color.fromARGB(50, 45, 45, 45),
                                child: InkWell(
                                  hoverColor: TreenixColors.primaryPink,
                                  onTap: () {
                                    // GoRouter.of(context).go('/');
                                    html.window.open(
                                        "https://www.strava.com/activities/" +
                                            _allactivities[i]
                                                ["strava_activity_id"],
                                        '_blank');
                                  },
                                  child: Container(
                                    width: 250,
                                    // height: 40,
                                    padding: EdgeInsets.all(10),
                                    child: Center(
                                      child: Column(
                                        children: [
                                          Text(
                                            utf8.decode(latin1.encode(
                                                _allactivities[i]["name"])),
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.white,
                                            ),
                                          ),
                                          Row(
                                            children: [
                                              SizedBox(width: 40),
                                              Text(
                                                "${(_allactivities[i]['distance'] / 1000).toStringAsFixed(1)} km",
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              Spacer(),
                                              Text(
                                                _formatTime(_allactivities[i]
                                                        ['moving_time'] ~/
                                                    60),
                                                // "${(_allactivities[i]['distance'] / 1000).toStringAsFixed(1)} km",
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              SizedBox(width: 40),
                                            ],
                                          )
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: 3),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 20,
            left: 25,
            width: MediaQuery.of(context).size.width - 50,
            child: RangeSlider(
              activeColor: TreenixColors.primaryPink,
              values: RangeValues(startValue, endValue),
              min: minDays,
              max: maxDays,
              divisions: maxDays.toInt(),
              onChanged: (values) {
                setState(() {
                  startValue = values.start;
                  endValue = values.end;
                  startDate = zeroDate.add(Duration(days: startValue.toInt()));
                  endDate = zeroDate.add(Duration(days: endValue.toInt()));
                });
              },
              labels: RangeLabels(
                zeroDate
                    .add(Duration(days: startValue.toInt()))
                    .toLocal()
                    .toString()
                    .split(' ')[0],
                zeroDate
                    .add(Duration(days: endValue.toInt()))
                    .toLocal()
                    .toString()
                    .split(' ')[0],
              ),
              onChangeEnd: (values) {
                setState(() {
                  startValue = values.start;
                  endValue = values.end;
                  startDate = zeroDate.add(Duration(days: startValue.toInt()));
                  endDate = zeroDate.add(Duration(days: endValue.toInt()));
                  // print(startDate);
                  // print(endDate);
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}
