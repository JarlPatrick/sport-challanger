import 'package:Treenix/_colors.dart';
import 'package:flutter/material.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'dart:convert';
import 'package:polyline_codec/polyline_codec.dart';
import 'dart:math';

class MapView extends StatefulWidget {
  final List<Map<String, dynamic>> allactivities;
  MapView({
    super.key,
    required this.allactivities,
  });

  @override
  State<MapView> createState() => MapViewState();
}

class MapViewState extends State<MapView> {
  // List<Map<String, dynamic>> activities = [];
  MapboxMapController? controller;
  void _onMapCreated(MapboxMapController controller) {
    this.controller = controller;
  }

  void _onStyleLoaded() async {
    loadYear(2025);
    // addLinesToMap(activities);
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    if (controller != null) {
      controller!.clearLines();
    }
    loadYear(2025);
    // addLinesToMap(activities);
  }

  void loadYear(int year) {
    if (controller != null) {
      controller!.clearLines();
    }
    List<Map<String, dynamic>> activs = [];
    for (var activity in widget.allactivities) {
      final parsedDate = DateTime.parse(activity['start_date']);
      if (parsedDate.year == year) {
        activs.add(activity);
      }
    }
    addLinesToMap(activs);
    // addAreas();
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

  /// Convert degrees to radians
  double radians(double degrees) {
    return degrees * pi / 180;
  }

  List<LatLng> PolylineToLatLng(String polyline) {
    List<List<num>> points = PolylineCodec.decode(polyline);
    return points.map((p) => LatLng(p[0].toDouble(), p[1].toDouble())).toList();
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
        if (isClosed(langs, 100.0)) {
          // 10 meters threshold
          double area = calculateEnclosedArea(langs) / (1000 * 1000);
          // print("Enclosed Area: ${area.toStringAsFixed(1)} km^2");
        } else {
          // print("The polyline is not closed.");
        }
        controller!.addLine(
          LineOptions(
            geometry: langs!,
            lineColor: TreenixColors.primaryPink.toHexStringRGB(),
            lineWidth: 3.0,
          ),
        );
      }
    }
  }

  // void addAreas() {
  //   if (controller == null) {
  //     print("Error: MapController is null");
  //     return;
  //   }
  //   controller!.setTelemetryEnabled(true);
  //   controller!.addFill(
  //     FillOptions(
  //       geometry: [
  //         [
  //           LatLng(59.437, 24.753),
  //           LatLng(59.438, 24.755),
  //           LatLng(59.436, 24.757),
  //           LatLng(59.435, 24.754),
  //           LatLng(59.437, 24.753) // Close the loop
  //         ]
  //       ],
  //       fillColor: TreenixColors.primaryPink.toHexStringRGB(),
  //       fillOpacity: 1,
  //     ),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
      width: 1600,
      height: 700,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: MapboxMap(
          styleString: MapboxStyles.DARK,
          // styleString: MapboxStyles.MAPBOX_STREETS,
          initialCameraPosition: const CameraPosition(
            target:
                // LatLng(59.46706512548259, 24.824713815561047),
                LatLng(58.710327075722086, 25.12594825181547),
            zoom: 6.7,
          ),
          accessToken:
              "pk.eyJ1IjoicmE1bXU1IiwiYSI6ImNremp1ZGwydjBwNGIybmxsNmpiMG1pZHoifQ.B6kcgUxR8ljeGPpYDw1ImA",
          onMapCreated: _onMapCreated,
          onStyleLoadedCallback: _onStyleLoaded,
        ),
      ),
    );
  }
}
