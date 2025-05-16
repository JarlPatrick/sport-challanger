import 'dart:math';
import 'package:latlong2/latlong.dart';

List<List<int>> dbscan(
    List<LatLng> points, double epsilonMeters, int minPoints) {
  final distance = Distance();
  final labels = List.filled(points.length, -1);
  int clusterId = 0;

  for (int i = 0; i < points.length; i++) {
    if (labels[i] != -1) continue;

    final neighbors = _regionQuery(points, i, epsilonMeters, distance);
    if (neighbors.length < minPoints) {
      labels[i] = -2; // noise
      continue;
    }

    labels[i] = clusterId;
    final queue = List.of(neighbors);

    while (queue.isNotEmpty) {
      final j = queue.removeLast();
      if (labels[j] == -2) labels[j] = clusterId; // previously noise
      if (labels[j] != -1) continue;

      labels[j] = clusterId;
      final subNeighbors = _regionQuery(points, j, epsilonMeters, distance);
      if (subNeighbors.length >= minPoints) queue.addAll(subNeighbors);
    }

    clusterId++;
  }

  final clusters = <int, List<int>>{};
  for (int i = 0; i < labels.length; i++) {
    if (labels[i] >= 0) {
      clusters.putIfAbsent(labels[i], () => []).add(i);
    }
  }

  return clusters.values.toList();
}

List<int> _regionQuery(
    List<LatLng> points, int index, double epsilonMeters, Distance distance) {
  final neighbors = <int>[];
  for (int j = 0; j < points.length; j++) {
    if (j != index && distance(points[index], points[j]) < epsilonMeters) {
      neighbors.add(j);
    }
  }
  return neighbors;
}

LatLng averageLatLng(List<LatLng> points) {
  final lat =
      points.map((p) => p.latitude).reduce((a, b) => a + b) / points.length;
  final lon =
      points.map((p) => p.longitude).reduce((a, b) => a + b) / points.length;
  return LatLng(lat, lon);
}
