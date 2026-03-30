import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

const String baseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://10.0.2.2:8000',
);

// OSRM public API for road-following routes (no API key needed)
const String osrmBaseUrl = 'https://router.project-osrm.org';

class Stop {
  final String stopId;
  final String stopName;
  final double lat;
  final double lng;
  final int safetyScore;
  final String grade;

  const Stop({
    required this.stopId,
    required this.stopName,
    required this.lat,
    required this.lng,
    required this.safetyScore,
    required this.grade,
  });

  factory Stop.fromJson(Map<String, dynamic> json) => Stop(
        stopId: (json['stop_id'] ?? '').toString(),
        stopName: (json['stop_name'] ?? 'Unknown Stop').toString(),
        lat: (json['lat'] ?? 0.0).toDouble(),
        lng: (json['lng'] ?? 0.0).toDouble(),
        safetyScore: (json['safety_score'] ?? 0) as int,
        grade: (json['grade'] ?? 'F').toString(),
      );
}

class SafetyApiService {
  static Future<http.Response> _safeGet(Uri uri) async {
    try {
      return await http.get(uri);
    } on SocketException catch (e) {
      throw Exception(
        'Cannot reach API at $baseUrl (${e.message}). '
        'If using a physical phone, run backend on 0.0.0.0 and pass --dart-define=API_BASE_URL=http://<PC_LAN_IP>:8000',
      );
    }
  }

  static Future<List<Stop>> getNearbyStops(
    double lat,
    double lng, {
    int radiusM = 1000,
  }) async {
    final uri = Uri.parse(
      '$baseUrl/stops/nearby?lat=$lat&lng=$lng&radius_m=$radiusM',
    );
    final res = await _safeGet(uri);
    if (res.statusCode != 200) {
      throw Exception('Failed to fetch nearby stops: ${res.statusCode}');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return (data['stops'] as List<dynamic>)
        .map((s) => Stop.fromJson(s as Map<String, dynamic>))
        .where((s) => s.lat != 0.0 || s.lng != 0.0)
        .toList();
  }

  static Future<Map<String, dynamic>> getSafetyScore(String stopId) async {
    final uri = Uri.parse('$baseUrl/stops/$stopId/safety-score');
    final res = await _safeGet(uri);
    if (res.statusCode != 200) {
      throw Exception('Failed to fetch safety score: ${res.statusCode}');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<List<dynamic>> getHeatmap({
    required double north,
    required double south,
    required double east,
    required double west,
    int gridM = 500,
  }) async {
    final uri = Uri.parse(
      '$baseUrl/area/heatmap?north=$north&south=$south&east=$east&west=$west&grid_m=$gridM',
    );
    final res = await _safeGet(uri);
    if (res.statusCode != 200) {
      throw Exception('Failed to fetch heatmap: ${res.statusCode}');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return data['cells'] as List<dynamic>;
  }

  /// Fetches a road-following route from OSRM between two coordinates.
  /// Returns a list of LatLng points that follow actual roads.
  /// Falls back to straight line if OSRM is unreachable.
  static Future<List<LatLng>> getRoadRoute({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
  }) async {
    try {
      // OSRM expects coordinates as lng,lat (note: reversed from lat,lng)
      final uri = Uri.parse(
        '$osrmBaseUrl/route/v1/driving/$fromLng,$fromLat;$toLng,$toLat'
        '?overview=full&geometries=geojson',
      );

      final res = await http.get(uri).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final routes = data['routes'] as List<dynamic>?;
        if (routes != null && routes.isNotEmpty) {
          final geometry = routes[0]['geometry'] as Map<String, dynamic>;
          final coordinates = geometry['coordinates'] as List<dynamic>;
          return coordinates
              .map((c) {
                final coord = c as List<dynamic>;
                // OSRM returns [lng, lat]
                return LatLng(
                  (coord[1] as num).toDouble(),
                  (coord[0] as num).toDouble(),
                );
              })
              .toList();
        }
      }
    } catch (_) {
      // Fall through to straight line fallback
    }

    // Fallback: straight line
    return [LatLng(fromLat, fromLng), LatLng(toLat, toLng)];
  }
}