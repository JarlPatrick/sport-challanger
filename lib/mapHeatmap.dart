import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
// import 'package:mapbox_gl/mapbox_gl.dart';
import 'dart:convert';
import 'package:polyline_codec/polyline_codec.dart';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:flutter_map/flutter_map.dart';
import 'dart:html' as html;
import 'package:shared_preferences/shared_preferences.dart';

import '_colors.dart';
import 'dbscan.dart';

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

  void load() async {
    // String lambdaUrl =
    //     "https://6iks67rav1.execute-api.eu-north-1.amazonaws.com/default/request-all-athletes-activities";
    // String token = await getToken();

    // final response = await http.get(
    //   Uri.parse(lambdaUrl),
    //   headers: <String, String>{
    //     "Authorization": token,
    //   },
    // );

    // if (response.statusCode == 200) {
    final activities = jsonDecode(await fetchActivityJson());
    print("LOADED");

    List<Map<String, dynamic>> allactivities = [];

    for (var activity in activities) {
      if (activity["map_polyline"] != "" && activity["type"] != "VirtualRide") {
        allactivities.add(activity);
        if (DateTime.parse(activity['start_date']).isBefore(zeroDate)) {
          zeroDate = DateTime.parse(activity['start_date']);
        }
      }
    }
    print(allactivities.length);

    setState(() {
      _allactivities = allactivities;
      startDate = zeroDate;
      endValue = endDate.difference(startDate).inDays.toDouble();
      maxDays = endValue;
    });
    findStartpoints();
    // }
  }

  // List<List<LatLng>> clusters = [];
  List<List<Map<String, dynamic>>> clusters = [];
  List<LatLng> clusterCenterpoint = [];
  void findStartpoints() {
    List<LatLng> _starts = [];
    for (var act in _allactivities) {
      if (PolylineToLatLng(act["map_polyline"]).length > 0) {
        _starts.add(PolylineToLatLng(act["map_polyline"]).first);
      }
    }

    // List<List<LatLng>> clusters = dbscan(_starts, 100000, 0);

    List<List<int>> clusterIDs = dbscan(_starts, 100000, 0);

    clusterCenterpoint = [];
    // List<LatLng> clusters = [];
    for (List<int> singleIDs in clusterIDs) {
      List<Map<String, dynamic>> singleclust = [];
      List<LatLng> cluststarts = [];
      for (int id in singleIDs) {
        singleclust.add(_allactivities[id]);
        cluststarts
            .add(PolylineToLatLng(_allactivities[id]["map_polyline"]).first);
      }
      clusterCenterpoint.add(averageLatLng(cluststarts));
      clusters.add(singleclust);
    }

    setState(() {});

    // print(starts);
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

  List<LatLng> PolylineToLatLng(String polyline) {
    List<List<num>> points = PolylineCodec.decode(polyline);
    return points.map((p) => LatLng(p[0].toDouble(), p[1].toDouble())).toList();
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

  int highlighted = -1;
  bool markermode = false;

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
                initialCenter: LatLng(58.710327075722086, 25.12594825181547),
                // initialCenter:
                //     LatLng(51.509364, -0.128928), // Center the map over London
                initialZoom: 8,
                onTap: (tapPosition, point) {},
                onMapEvent: (p0) {
                  // print(p0.camera.zoom);
                  if (p0.camera.zoom < 5) {
                    if (markermode == false) {
                      setState(() {
                        markermode = true;
                      });
                    }
                  } else {
                    if (markermode == true) {
                      setState(() {
                        markermode = false;
                      });
                    }
                  }
                  // if(p0.camera.zoom)
                },
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
                if (markermode)
                  MarkerLayer(
                    markers: [
                      for (List<Map<String, dynamic>> clust in clusters)
                        Marker(
                          // point: PolylineToLatLng(clust.first["map_polyline"])
                          //     .first,
                          point: clusterCenterpoint[clusters.indexOf(clust)],
                          width: 30,
                          height: 30,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: InkWell(
                              hoverColor: TreenixColors.primaryPink,
                              onTap: () {
                                // print("hit");
                                setState(() {
                                  idList = [];
                                  for (Map<String, dynamic> act in clust) {
                                    idList.add(_allactivities.indexOf(act));
                                  }
                                });

                                // idList.add(int.parse(element.toString()));

                                // setState(() {
                                //   // idList = hitNotifier.value!.hitValues as List<int>;
                                //   // activityName = utf8
                                //   //     .decode(latin1.encode(_allactivities[id]["name"]));
                                //   // stravaID = _allactivities[id]["strava_activity_id"];
                                // });
                              },
                              child: Container(
                                color: TreenixColors.primaryPink,
                                width: 30,
                                height: 30,
                                // padding: EdgeInsets.all(10),
                                child: Center(
                                  child: Text(
                                    clust.length.toString(),
                                    style: TextStyle(
                                      fontSize: 10,
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
                else ...[
                  // Inside the map build...
                  MouseRegion(
                    hitTestBehavior: HitTestBehavior.deferToChild,
                    cursor: SystemMouseCursors
                        .click, // Use a special cursor to indicate interactivity
                    child: GestureDetector(
                      onTap: () {
                        print("hit");
                        // print(hitNotifier.value?.hitValues);
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
                          if (highlighted != -1) ...[
                            for (var act in _allactivities)
                              if (DateTime.parse(act['start_date'])
                                      .isBefore(endDate) &&
                                  DateTime.parse(act['start_date'])
                                      .isAfter(startDate) &&
                                  _allactivities.indexOf(act) != highlighted)
                                Polyline(
                                    strokeWidth: 1,
                                    // hitValue: utf8.decode(latin1.encode(act['name'])),
                                    hitValue: _allactivities.indexOf(act),
                                    points:
                                        PolylineToLatLng(act["map_polyline"]),
                                    color: const Color.fromARGB(
                                        255, 175, 175, 175)),
                            if (DateTime.parse(_allactivities[highlighted]
                                        ['start_date'])
                                    .isBefore(endDate) &&
                                DateTime.parse(_allactivities[highlighted]
                                        ['start_date'])
                                    .isAfter(startDate))
                              Polyline(
                                  strokeWidth: 2,
                                  // hitValue: utf8.decode(latin1.encode(act['name'])),
                                  hitValue: _allactivities
                                      .indexOf(_allactivities[highlighted]),
                                  points: PolylineToLatLng(
                                      _allactivities[highlighted]
                                          ["map_polyline"]),
                                  color: TreenixColors.primaryPink),
                          ] else
                            for (var act in _allactivities)
                              if (DateTime.parse(act['start_date'])
                                      .isBefore(endDate) &&
                                  DateTime.parse(act['start_date'])
                                      .isAfter(startDate) &&
                                  _allactivities.indexOf(act) != highlighted)
                                Polyline(
                                    // hitValue: utf8.decode(latin1.encode(act['name'])),
                                    hitValue: _allactivities.indexOf(act),
                                    points:
                                        PolylineToLatLng(act["map_polyline"]),
                                    color:
                                        const Color.fromARGB(255, 255, 0, 128)),
                        ],
                      ),
                    ),
                  ),
                ]
              ],
            ),
          ),
          if (MediaQuery.of(context).size.width > 600) ...[
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
                                    onHover: (value) {
                                      setState(() {
                                        if (value) {
                                          highlighted = i;
                                        } else {
                                          highlighted = -1;
                                        }
                                      });
                                    },
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
                                      padding: EdgeInsets.all(5),
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
                                              mainAxisAlignment:
                                                  MainAxisAlignment.spaceAround,
                                              mainAxisSize: MainAxisSize.max,
                                              children: [
                                                Text(
                                                  DateFormat("d MMM yyyy")
                                                      .format(DateTime.parse(
                                                          _allactivities[i]
                                                              ['start_date'])),
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                                Text(
                                                  "${(_allactivities[i]['distance'] / 1000).toStringAsFixed(1)} km",
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: Colors.white,
                                                  ),
                                                ),
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
                    startDate =
                        zeroDate.add(Duration(days: startValue.toInt()));
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
                    startDate =
                        zeroDate.add(Duration(days: startValue.toInt()));
                    endDate = zeroDate.add(Duration(days: endValue.toInt()));
                    // print(startDate);
                    // print(endDate);
                  });
                },
              ),
            ),
          ] else ...[
            Positioned(
              left: 20,
              top: 20,
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(25),
                    child: Material(
                      color: const Color.fromARGB(50, 45, 45, 45),
                      child: InkWell(
                        hoverColor: TreenixColors.primaryPink,
                        onTap: () {
                          GoRouter.of(context).go('/');
                        },
                        child: Container(
                          width: 50,
                          height: 50,
                          padding: EdgeInsets.all(10),
                          child: Center(
                            child: Icon(Icons.arrow_back),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  // Container(
                  //   height: MediaQuery.of(context).size.height - 200,
                  //   width: 250,
                  //   // decoration: BoxDecoration(
                  //   //   borderRadius: BorderRadius.circular(10),
                  //   //   color: const Color.fromARGB(50, 45, 45, 45),
                  //   // ),
                  //   child: SingleChildScrollView(
                  //     scrollDirection: Axis.vertical,
                  //     child: Container(
                  //       decoration: BoxDecoration(
                  //         borderRadius: BorderRadius.circular(10),
                  //         color: const Color.fromARGB(50, 45, 45, 45),
                  //       ),
                  //       child: ),
                  //   ),
                  // ),
                ],
              ),
            ),
            // Positioned(
            //   bottom: 40,
            //   child:
            // ),
            Positioned(
              bottom: 0,
              width: MediaQuery.of(context).size.width,
              child: Column(
                children: [
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: 200,
                    ),
                    child: Container(
                      width: MediaQuery.of(context).size.width,
                      // height: 200,
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(50, 45, 45, 45),
                      ),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: Column(
                          children: [
                            for (int i in idList) ...[
                              SizedBox(height: 3),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Material(
                                  color: const Color.fromARGB(50, 45, 45, 45),
                                  child: InkWell(
                                    hoverColor: TreenixColors.primaryPink,
                                    onHover: (value) {
                                      setState(() {
                                        if (value) {
                                          highlighted = i;
                                        } else {
                                          highlighted = -1;
                                        }
                                      });
                                    },
                                    onTap: () {
                                      // GoRouter.of(context).go('/');
                                      html.window.open(
                                          "https://www.strava.com/activities/" +
                                              _allactivities[i]
                                                  ["strava_activity_id"],
                                          '_blank');
                                    },
                                    child: Container(
                                      width: MediaQuery.of(context).size.width -
                                          20,
                                      // height: 40,
                                      padding: EdgeInsets.all(5),
                                      child: Center(
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceAround,
                                          mainAxisSize: MainAxisSize.max,
                                          children: [
                                            SizedBox(
                                              width: 200,
                                              child: Text(
                                                utf8.decode(latin1.encode(
                                                    _allactivities[i]["name"])),
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                            Text(
                                              DateFormat("d MMM yyyy").format(
                                                  DateTime.parse(
                                                      _allactivities[i]
                                                          ['start_date'])),
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: Colors.white,
                                              ),
                                            ),
                                            Text(
                                              "${(_allactivities[i]['distance'] / 1000).toStringAsFixed(1)} km",
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: Colors.white,
                                              ),
                                            ),
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
                  Container(
                    color: const Color.fromARGB(50, 45, 45, 45),
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
                          startDate =
                              zeroDate.add(Duration(days: startValue.toInt()));
                          endDate =
                              zeroDate.add(Duration(days: endValue.toInt()));
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
                          startDate =
                              zeroDate.add(Duration(days: startValue.toInt()));
                          endDate =
                              zeroDate.add(Duration(days: endValue.toInt()));
                          // print(startDate);
                          // print(endDate);
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
          ]
        ],
      ),
    );
  }
}
