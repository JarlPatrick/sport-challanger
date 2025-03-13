import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:mapbox_gl/mapbox_gl.dart';
import 'dart:convert';
import 'package:polyline_codec/polyline_codec.dart';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:flutter_map/flutter_map.dart';

import '_colors.dart';

class MapTerraX extends StatefulWidget {
  final List<Map<String, dynamic>> allactivities;
  const MapTerraX({
    super.key,
    required this.allactivities,
  });

  @override
  State<MapTerraX> createState() => MapTerraXState();
}

class MapTerraXState extends State<MapTerraX> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    load();
    loadYear(2025);
    // addLinesToMap(activities);
  }

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
      dynamic geojson = jsonDecode(data["geojson"]);
      print(
          "TOTAL AREA: ${data["total_area"].toStringAsFixed(1)} km^2 and ${(data["total_area"] / 45335 * 100).toStringAsFixed(1)}%");

      List<List<List<LatLng>>> coordinates = getCoords(geojson);
      // List<List<LatLng>> coordinates = ret[0];
      // List<List<LatLng>> holes = ret[1];

      dynamic user_area = jsonDecode(data["user_area"]);
      List<List<List<LatLng>>> Usercoordinates = getCoords(user_area);
      // List<List<LatLng>> Usercoordinates = ret[0];
      // List<List<LatLng>> Userholes = ret[1];

      setState(() {
        _coordinates = coordinates;
        // _holes = holes;
        _usercoordinates = Usercoordinates;
        // _userholes = Userholes;
        print("DONE LOADING");
      });
    }
  }

  List<List<List<LatLng>>> _coordinates = [];
  List<List<List<LatLng>>> _usercoordinates = [];
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
        coor.add(a);
        // if (first) {
        //   first = false;
        //   coordinates.add(a);
        // } else {
        //   holes.add(a);
        // }
        // print(items.length);
        // print(items);
      }
      // print(coor.length);
      coordinates.add(coor);
    }
    return coordinates;
  }

  void _onStyleLoaded() async {
    if (controller == null) return;

    loadYear(2025);

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
      dynamic geojson = jsonDecode(data["geojson"]);
      print(
          "TOTAL AREA: ${data["total_area"].toStringAsFixed(1)} km^2 and ${(data["total_area"] / 45335 * 100).toStringAsFixed(1)}%");
      List<List<List<LatLng>>> ret = getCoords(geojson);
      List<List<LatLng>> coordinates = ret[0];
      List<List<LatLng>> holes = ret[1];

      dynamic user_area = jsonDecode(data["user_area"]);
      ret = getCoords(user_area);
      List<List<LatLng>> Usercoordinates = ret[0];
      List<List<LatLng>> Userholes = ret[1];

      // setState(() {
      //   _coordinates = coordinates;
      //   print("DONE LOADING");
      // });

      if (controller == null) {
        print("Error: MapController is null");
        return;
      }
      controller!.addFill(
        FillOptions(
          geometry: coordinates,
          fillColor: TreenixColors.primaryPink.toHexStringRGB(),
          fillOpacity: 0.3,
          fillOutlineColor: TreenixColors.primaryPink.toHexStringRGB(),
        ),
      );
      controller!.addFill(
        FillOptions(
          geometry: Usercoordinates,
          fillColor: TreenixColors.primaryPink.toHexStringRGB(),
          fillOpacity: 0.5,
          fillOutlineColor: TreenixColors.primaryPink.toHexStringRGB(),
        ),
      );
    }
  }

  void loadYear(int year) {
    if (controller != null) {
      controller!.clearFills();
    }
    List<Map<String, dynamic>> activs = [];
    for (var activity in widget.allactivities) {
      final parsedDate = DateTime.parse(activity['start_date']);
      if (parsedDate.year == year) {
        activs.add(activity);
      }
    }
    // addLinesToMap(activs);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.max,
      children: [
        // ElevatedButton(
        //   onPressed: () {
        //     _onStyleLoaded();
        //   },
        //   child: Text("load"),
        // ),
        // Container(
        //   decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
        //   width: 700,
        //   height: 700,
        //   child: ClipRRect(
        //     borderRadius: BorderRadius.circular(20),
        //     child: MapboxMap(
        //       styleString: MapboxStyles.DARK,
        //       // styleString: MapboxStyles.MAPBOX_STREETS,
        //       initialCameraPosition: const CameraPosition(
        //         target: LatLng(58.710327075722086, 25.12594825181547),
        //         zoom: 6.7,
        //       ),
        //       accessToken:
        //           "pk.eyJ1IjoicmE1bXU1IiwiYSI6ImNremp1ZGwydjBwNGIybmxsNmpiMG1pZHoifQ.B6kcgUxR8ljeGPpYDw1ImA",
        //       onMapCreated: _onMapCreated,
        //       onStyleLoadedCallback: _onStyleLoaded,
        //     ),
        //   ),
        // ),
        Container(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
          width: 1600,
          height: 700,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: FlutterMap(
              options: MapOptions(
                initialCenter: ll.LatLng(58.710327075722086, 25.12594825181547),
                // initialCenter:
                //     LatLng(51.509364, -0.128928), // Center the map over London
                initialZoom: 7.5,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
                  subdomains: ['a', 'b', 'c'],
                  userAgentPackageName: 'com.example.app',
                ),
                PolygonLayer(
                  polygons: [
                    for (List<List<LatLng>> coors in _usercoordinates) ...[
                      Polygon(
                        points: [
                          for (LatLng point in coors[0])
                            ll.LatLng(point.latitude, point.longitude),
                        ],
                        color: Color.fromARGB(50, 255, 0, 128),
                        // holePointsList: [
                        //   if (coors.length > 1)
                        //     for (List<LatLng> coor in coors.sublist(1))
                        //       if (coor.length > 3)
                        //         [
                        //           for (LatLng point in coor)
                        //             ll.LatLng(point.latitude, point.longitude),
                        //         ],
                        // ],
                      ),
                    ],
                    for (List<List<LatLng>> coors in _coordinates) ...[
                      for (List<LatLng> coor in [coors[0]])
                        Polygon(
                          points: [
                            for (LatLng point in coor)
                              ll.LatLng(point.latitude, point.longitude),
                          ],
                          color: Color.fromARGB(25, 255, 0, 128),
                          // isFilled: true,
                        ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        )
      ],
    );
  }
}
