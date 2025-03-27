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

class MapTerraX extends StatefulWidget {
  // final List<Map<String, dynamic>> allactivities;
  const MapTerraX({
    super.key,
    // required this.allactivities,
  });

  @override
  State<MapTerraX> createState() => MapTerraXState();
}

enum TerraxMapType { loading, all, onfoot }

class MapTerraXState extends State<MapTerraX> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    load();
  }

  double totalAreaCovered = 0;
  double totalAreaCoveredPercentage = 0;
  double userTotalAreaCovered = 0;
  double userTotalAreaCoveredPercentage = 0;
  double totalAreaCoveredOnfoot = 0;
  double totalAreaCoveredPercentageOnfoot = 0;
  double userTotalAreaCoveredOnfoot = 0;
  double userTotalAreaCoveredPercentageOnfoot = 0;

  TerraxMapType mapType = TerraxMapType.loading;

  void load() async {
    String lambdaUrl =
        "https://6iks67rav1.execute-api.eu-north-1.amazonaws.com/default/request-areas";
    String token = await getToken();

    final response = await http.get(
      Uri.parse(lambdaUrl),
      headers: <String, String>{
        "Authorization": token,
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      // dynamic geojson = jsonDecode(data["total_area"]);
      // print(
      //     "TOTAL AREA: ${data["total_area"].toStringAsFixed(1)} km^2 and ${(data["total_area"] / 45335 * 100).toStringAsFixed(1)}%");

      List<List<List<LatLng>>> coordinates =
          getCoords(jsonDecode(data["total_area"]));

      // dynamic user_area = jsonDecode(data["user_area"]);
      List<List<List<LatLng>>> Usercoordinates =
          getCoords(jsonDecode(data["user_area"]));

      List<List<List<LatLng>>> coordinatesOnfoot =
          getCoords(jsonDecode(data["total_area_onfoot"]));
      List<List<List<LatLng>>> userCoordinatesOnfoot =
          getCoords(jsonDecode(data["user_area_onfoot"]));

      setState(() {
        _coordinates = coordinates;
        _usercoordinates = Usercoordinates;
        _coordinatesOnfoot = coordinatesOnfoot;
        _userCoordinatesOnfoot = userCoordinatesOnfoot;
        totalAreaCovered = data["total_area_size"];
        totalAreaCoveredPercentage = data["total_area_size"] / 45335 * 100;
        userTotalAreaCovered = data["user_area_size"];
        userTotalAreaCoveredPercentage = data["user_area_size"] / 45335 * 100;
        totalAreaCoveredOnfoot = data["total_area_size_onfoot"];
        totalAreaCoveredPercentageOnfoot =
            data["total_area_size_onfoot"] / 45335 * 100;
        userTotalAreaCoveredOnfoot = data["user_area_size_onfoot"];
        userTotalAreaCoveredPercentageOnfoot =
            data["user_area_size_onfoot"] / 45335 * 100;
        print("DONE LOADING");
        mapType = TerraxMapType.all;
      });
    }
  }

  List<List<List<LatLng>>> _coordinates = [];
  List<List<List<LatLng>>> _usercoordinates = [];
  List<List<List<LatLng>>> _coordinatesOnfoot = [];
  List<List<List<LatLng>>> _userCoordinatesOnfoot = [];
  // List<List<LatLng>> _holes = [];
  // List<List<LatLng>> _userholes = [];

  MapboxMapController? controller;
  void _onMapCreated(MapboxMapController controller) {
    this.controller = controller;
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

  List<List<List<LatLng>>> getCoords(dynamic geojson) {
    List<List<List<LatLng>>> coordinates = [];
    // List<List<LatLng>> holes = [];
    for (List<dynamic> item in geojson["coordinates"]) {
      // print(item.length);
      // bool first = true;
      List<List<LatLng>> coor = [];
      for (List<dynamic> items in item) {
        List<LatLng> a = [];
        for (List<dynamic> point in items) {
          a.add(LatLng(point[1], point[0]));
        }
        if (a.length > 5) {
          coor.add(a);
        }
      }
      if (coor.length > 0) {
        coordinates.add(coor);
      }
    }
    return coordinates;
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
                PolygonLayer(
                  polygons: [
                    if (mapType == TerraxMapType.all) ...[
                      for (List<List<LatLng>> coors in _coordinates) ...[
                        Polygon(
                          points: [
                            for (LatLng point in coors[0])
                              ll.LatLng(point.latitude, point.longitude),
                          ],
                          color: Color.fromARGB(30, 255, 0, 128),
                          holePointsList: [
                            if (coors.length > 1)
                              for (List<LatLng> coor in coors.sublist(1))
                                [
                                  for (LatLng point in coor)
                                    ll.LatLng(point.latitude, point.longitude),
                                ],
                          ],
                        ),
                      ],
                      for (List<List<LatLng>> coors in _usercoordinates) ...[
                        for (List<LatLng> coor in [coors[0]])
                          Polygon(
                            points: [
                              for (LatLng point in coor)
                                ll.LatLng(point.latitude, point.longitude),
                            ],
                            color: Color.fromARGB(30, 255, 0, 128),
                            // isFilled: true,
                            holePointsList: [
                              if (coors.length > 1)
                                for (List<LatLng> coor in coors.sublist(1))
                                  [
                                    for (LatLng point in coor)
                                      ll.LatLng(
                                          point.latitude, point.longitude),
                                  ],
                            ],
                          ),
                      ],
                    ],
                    if (mapType == TerraxMapType.onfoot) ...[
                      for (List<List<LatLng>> coors in _coordinatesOnfoot) ...[
                        Polygon(
                          points: [
                            for (LatLng point in coors[0])
                              ll.LatLng(point.latitude, point.longitude),
                          ],
                          color: Color.fromARGB(30, 255, 0, 128),
                          holePointsList: [
                            if (coors.length > 1)
                              for (List<LatLng> coor in coors.sublist(1))
                                [
                                  for (LatLng point in coor)
                                    ll.LatLng(point.latitude, point.longitude),
                                ],
                          ],
                        ),
                      ],
                      for (List<List<LatLng>> coors
                          in _userCoordinatesOnfoot) ...[
                        for (List<LatLng> coor in [coors[0]])
                          Polygon(
                            points: [
                              for (LatLng point in coor)
                                ll.LatLng(point.latitude, point.longitude),
                            ],
                            color: Color.fromARGB(30, 255, 0, 128),
                            holePointsList: [
                              if (coors.length > 1)
                                for (List<LatLng> coor in coors.sublist(1))
                                  [
                                    for (LatLng point in coor)
                                      ll.LatLng(
                                          point.latitude, point.longitude),
                                  ],
                            ],
                            // isFilled: true,
                          ),
                      ],
                    ]
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
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Material(
                    color: const Color.fromARGB(50, 45, 45, 45),
                    child: InkWell(
                      hoverColor: TreenixColors.primaryPink,
                      onTap: () {
                        if (mapType == TerraxMapType.all) {
                          setState(() {
                            mapType = TerraxMapType.onfoot;
                          });
                        } else if (mapType == TerraxMapType.onfoot) {
                          setState(() {
                            mapType = TerraxMapType.all;
                          });
                        }
                        // GoRouter.of(context).go('/terrax');
                      },
                      child: Container(
                        width: 150,
                        // height: 220,
                        padding: EdgeInsets.all(10),
                        child: Center(
                            child: switch (mapType) {
                          TerraxMapType.all => Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "All",
                                  style: TextStyle(
                                    fontSize: 25,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(height: 7),
                                Text(
                                  "You own",
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  "${userTotalAreaCovered.floor()} km²",
                                  style: TextStyle(
                                    fontSize: 23,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  "out of total",
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  "${totalAreaCovered.floor()} km²",
                                  style: TextStyle(
                                    fontSize: 23,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  "which is",
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  "${totalAreaCoveredPercentage.toStringAsFixed(1)} %",
                                  style: TextStyle(
                                    fontSize: 23,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  "of Estonia",
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          // TODO: Handle this case.
                          TerraxMapType.onfoot => Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "On foot",
                                  style: TextStyle(
                                    fontSize: 25,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(height: 7),
                                Text(
                                  "You own",
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  "${userTotalAreaCoveredOnfoot.floor()} km²",
                                  style: TextStyle(
                                    fontSize: 23,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  "out of total",
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  "${totalAreaCoveredOnfoot.floor()} km²",
                                  style: TextStyle(
                                    fontSize: 23,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  "which is",
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  "${totalAreaCoveredPercentageOnfoot.toStringAsFixed(1)} %",
                                  style: TextStyle(
                                    fontSize: 23,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  "of Estonia",
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          // TODO: Handle this case.
                          TerraxMapType.loading => Text(
                              "Loading",
                              style: TextStyle(
                                fontSize: 20,
                                color: Colors.white,
                              ),
                            ),
                        }),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
