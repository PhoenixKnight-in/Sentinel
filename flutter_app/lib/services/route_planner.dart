import 'dart:math';

import 'safety_api.dart';

class GraphNode {
  final Stop stop;
  final Map<String, double> neighbors = {};

  GraphNode(this.stop);
}

class RoutePlanner {
  final Map<String, GraphNode> graph = {};

  void buildGraph(List<Stop> stops, {double maxEdgeDistanceM = 800}) {
    graph.clear();
    for (final stop in stops) {
      graph[stop.stopId] = GraphNode(stop);
    }

    for (int i = 0; i < stops.length; i++) {
      for (int j = i + 1; j < stops.length; j++) {
        final a = stops[i];
        final b = stops[j];
        final dist = _haversine(a.lat, a.lng, b.lat, b.lng);
        if (dist <= maxEdgeDistanceM) {
          final weight = (a.safetyScore + b.safetyScore) / 2.0;
          graph[a.stopId]!.neighbors[b.stopId] = weight;
          graph[b.stopId]!.neighbors[a.stopId] = weight;
        }
      }
    }
  }

  List<Stop>? findSafestPath(String fromStopId, String toStopId) {
    if (!graph.containsKey(fromStopId) || !graph.containsKey(toStopId)) {
      return null;
    }

    final best = <String, double>{};
    final prev = <String, String?>{};
    final unvisited = <String>{...graph.keys};

    for (final id in graph.keys) {
      best[id] = double.negativeInfinity;
      prev[id] = null;
    }
    best[fromStopId] = 100.0;

    while (unvisited.isNotEmpty) {
      final current = unvisited.reduce(
        (a, b) => (best[a] ?? double.negativeInfinity) >
                (best[b] ?? double.negativeInfinity)
            ? a
            : b,
      );
      if (current == toStopId) break;
      unvisited.remove(current);

      final node = graph[current];
      if (node == null) continue;

      for (final entry in node.neighbors.entries) {
        final neighbor = entry.key;
        if (!unvisited.contains(neighbor)) continue;
        final edgeSafety = entry.value;
        final candidate = min(best[current]!, edgeSafety);
        if (candidate > (best[neighbor] ?? double.negativeInfinity)) {
          best[neighbor] = candidate;
          prev[neighbor] = current;
        }
      }
    }

    if (fromStopId != toStopId && prev[toStopId] == null) return null;

    final path = <Stop>[];
    String? cursor = toStopId;
    while (cursor != null) {
      final n = graph[cursor];
      if (n == null) break;
      path.insert(0, n.stop);
      cursor = prev[cursor];
    }
    return path;
  }

  /// Generates a straight-line (direct) route between two coordinates
  /// by interpolating intermediate waypoints. Used as fallback when
  /// no bus stops are found nearby.
  List<Stop> buildDirectRoute({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
    int steps = 5,
  }) {
    final route = <Stop>[];
    for (int i = 0; i <= steps; i++) {
      final t = i / steps;
      final lat = fromLat + (toLat - fromLat) * t;
      final lng = fromLng + (toLng - fromLng) * t;
      final label = i == 0
          ? 'Your Location'
          : i == steps
              ? 'Destination'
              : 'Waypoint $i';
      route.add(Stop(
        stopId: 'direct_$i',
        stopName: label,
        lat: lat,
        lng: lng,
        safetyScore: 50, // neutral score for direct route
        grade: 'C',
      ));
    }
    return route;
  }

  Stop? nearestStop(List<Stop> stops, double lat, double lng) {
    if (stops.isEmpty) return null;
    Stop best = stops.first;
    double bestD = _haversine(lat, lng, best.lat, best.lng);
    for (final s in stops.skip(1)) {
      final d = _haversine(lat, lng, s.lat, s.lng);
      if (d < bestD) {
        best = s;
        bestD = d;
      }
    }
    return best;
  }

  double distanceM(double lat1, double lng1, double lat2, double lng2) =>
      _haversine(lat1, lng1, lat2, lng2);

  double _haversine(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371000.0;
    final dLat = _rad(lat2 - lat1);
    final dLon = _rad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_rad(lat1)) * cos(_rad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    return r * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  double _rad(double deg) => deg * pi / 180;
}