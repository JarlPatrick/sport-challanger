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
                PolylineLayer(
                  polylines: [
                    for (var act in _allactivities)
                      if (DateTime.parse(act['start_date']).isBefore(endDate) &&
                          DateTime.parse(act['start_date']).isAfter(startDate))
                        Polyline(
                          points: PolylineToLatLng(act["map_polyline"]),
                          color: TreenixColors.primaryPink,
                        )
                  ],
                ),
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
                        width: 150,
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
