import 'package:flutter/material.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'dart:convert';
import 'package:polyline_codec/polyline_codec.dart';
import 'dart:math';

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
    loadYear(2025);
    // addLinesToMap(activities);
  }

  MapboxMapController? controller;
  void _onMapCreated(MapboxMapController controller) {
    this.controller = controller;
  }

  void _onStyleLoaded() async {
    if (controller == null) return;

    loadYear(2025);
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
    addLinesToMap(activs);
  }

  void addLinesToMap(List<Map<String, dynamic>> activities) {
    if (controller == null) {
      print("Error: MapController is null");
      return;
    }
    for (var act in activities) {
      // print(act);
      String poly = act["map_polyline"];
      // print(act["name"]);
      // print(poly);
      if (poly != "") {
        List<LatLng> langs = PolylineToLatLng(poly);
        if (isClosed(langs, 1000.0)) {
          // 10 meters threshold
          double area = calculateEnclosedArea(langs) / (1000 * 1000);
          // print("Enclosed Area: ${area.toStringAsFixed(1)} km^2");
          controller!.addFill(
            FillOptions(
              geometry: [langs],
              fillColor: TreenixColors.primaryPink.toHexStringRGB(),
              fillOpacity: 0.5,
              fillOutlineColor: TreenixColors.primaryPink.toHexStringRGB(),
            ),
          );
        } else {
          // print("The polyline is not closed.");
        }
      }
    }
  }

  /// Convert degrees to radians
  double radians(double degrees) {
    return degrees * pi / 180;
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

  List<LatLng> PolylineToLatLng(String polyline) {
    List<List<num>> points = PolylineCodec.decode(polyline);
    return points.map((p) => LatLng(p[0].toDouble(), p[1].toDouble())).toList();
  }

  /// Check if the polyline is closed
  bool isClosed(List<LatLng> points, double thresholdMeters) {
    if (points.length < 3) return false;

    double distance = haversineDistance(points.first, points.last);
    return distance < thresholdMeters;
  }

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
        Container(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
          width: 700,
          height: 700,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: MapboxMap(
              styleString: MapboxStyles.DARK,
              // styleString: MapboxStyles.MAPBOX_STREETS,
              initialCameraPosition: const CameraPosition(
                target: LatLng(58.710327075722086, 25.12594825181547),
                zoom: 6.7,
              ),
              accessToken:
                  "pk.eyJ1IjoicmE1bXU1IiwiYSI6ImNremp1ZGwydjBwNGIybmxsNmpiMG1pZHoifQ.B6kcgUxR8ljeGPpYDw1ImA",
              onMapCreated: _onMapCreated,
              onStyleLoadedCallback: _onStyleLoaded,
            ),
          ),
        ),
      ],
    );
  }
}
