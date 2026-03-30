import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../services/route_planner.dart';
import '../services/safety_api.dart';

enum RouteMode { transit, direct, road }

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  LatLng? _userLocation;
  LatLng? _destination;
  List<Stop> _nearbyStops = [];
  List<Stop> _safestPath = [];
  List<LatLng> _roadPolyline = []; // road-following points from OSRM
  bool _loading = false;
  bool _locating = true;
  String? _error;
  bool _awaitingDestination = false;
  RouteMode _routeMode = RouteMode.transit;

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    setState(() {
      _locating = true;
      _error = null;
    });
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        setState(() {
          _error = 'Location service is disabled. Please enable GPS.';
          _locating = false;
        });
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() {
          _error = 'Location permission denied.';
          _locating = false;
        });
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final userLatLng = LatLng(pos.latitude, pos.longitude);
      setState(() {
        _userLocation = userLatLng;
        _locating = false;
        _awaitingDestination = true;
        _error = null;
      });

      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) _mapController.move(userLatLng, 15.0);
      });

      await _loadNearbyStops(pos.latitude, pos.longitude);
    } catch (e) {
      setState(() {
        _error = 'Failed to get location: $e';
        _locating = false;
      });
    }
  }

  Future<void> _loadNearbyStops(double lat, double lng) async {
    setState(() => _loading = true);
    try {
      final stops =
          await SafetyApiService.getNearbyStops(lat, lng, radiusM: 5000);
      setState(() => _nearbyStops = stops);
    } catch (e) {
      setState(() => _error = 'Failed to load nearby stops: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _onMapTap(LatLng tappedPoint) async {
    if (_userLocation == null) {
      setState(
          () => _error = 'Still acquiring your location, please wait...');
      return;
    }
    setState(() {
      _destination = tappedPoint;
      _safestPath = [];
      _roadPolyline = [];
      _awaitingDestination = false;
      _error = null;
    });
    await _findSafestRoute(tappedPoint);
  }

  Future<void> _findSafestRoute(LatLng destination) async {
    if (_userLocation == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final originStops = await SafetyApiService.getNearbyStops(
        _userLocation!.latitude,
        _userLocation!.longitude,
        radiusM: 5000,
      );
      final destStops = await SafetyApiService.getNearbyStops(
        destination.latitude,
        destination.longitude,
        radiusM: 5000,
      );

      final planner = RoutePlanner();

      // No stops at all → road route via OSRM
      if (originStops.isEmpty && destStops.isEmpty) {
        await _fetchAndSetRoadRoute(destination);
        return;
      }

      // One side missing → road route via OSRM
      if (originStops.isEmpty || destStops.isEmpty) {
        await _fetchAndSetRoadRoute(destination,
            warning:
                'No bus stops found ${originStops.isEmpty ? "near your location" : "near destination"}. Showing road route instead.');
        return;
      }

      // Normal: try transit graph
      final dedup = <String, Stop>{};
      for (final s in [...originStops, ...destStops]) {
        dedup[s.stopId] = s;
      }
      planner.buildGraph(dedup.values.toList());

      final originStop = planner.nearestStop(
        originStops,
        _userLocation!.latitude,
        _userLocation!.longitude,
      );
      final destStop = planner.nearestStop(
        destStops,
        destination.latitude,
        destination.longitude,
      );

      if (originStop == null || destStop == null) {
        await _fetchAndSetRoadRoute(destination,
            warning: 'Could not find route anchors. Showing road route.');
        return;
      }

      final path =
          planner.findSafestPath(originStop.stopId, destStop.stopId);

      if (path == null || path.isEmpty) {
        await _fetchAndSetRoadRoute(destination,
            warning:
                'Bus stops found but no connected path. Showing road route instead.');
        return;
      }

      // Got a transit path — also fetch road polyline between first and last stop
      final roadPoints = await SafetyApiService.getRoadRoute(
        fromLat: _userLocation!.latitude,
        fromLng: _userLocation!.longitude,
        toLat: destination.latitude,
        toLng: destination.longitude,
      );

      setState(() {
        _safestPath = path;
        _roadPolyline = roadPoints;
        _routeMode = RouteMode.transit;
        _awaitingDestination = false;
      });
    } catch (e) {
      setState(() => _error = 'Failed to plan route: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _fetchAndSetRoadRoute(LatLng destination,
      {String? warning}) async {
    final roadPoints = await SafetyApiService.getRoadRoute(
      fromLat: _userLocation!.latitude,
      fromLng: _userLocation!.longitude,
      toLat: destination.latitude,
      toLng: destination.longitude,
    );
    setState(() {
      _roadPolyline = roadPoints;
      _safestPath = [];
      _routeMode = RouteMode.road;
      _error = warning;
    });
  }

  void _resetRoute() {
    setState(() {
      _destination = null;
      _safestPath = [];
      _roadPolyline = [];
      _error = null;
      _awaitingDestination = true;
      _routeMode = RouteMode.transit;
    });
  }

  Color _safetyColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    if (score >= 40) return Colors.deepOrange;
    return Colors.red;
  }

  // The active polyline points to draw
  List<LatLng> get _activePolyline {
    if (_routeMode == RouteMode.road) return _roadPolyline;
    if (_roadPolyline.isNotEmpty) return _roadPolyline;
    return _safestPath.map((s) => LatLng(s.lat, s.lng)).toList();
  }

  Color get _polylineColor {
    switch (_routeMode) {
      case RouteMode.transit:
        return Colors.blue;
      case RouteMode.road:
        return Colors.green.shade700;
      case RouteMode.direct:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final polyline = _activePolyline;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Safe Transit Map'),
        actions: [
          if (_destination != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Reset route',
              onPressed: _resetRoute,
            ),
          IconButton(
            icon: const Icon(Icons.my_location),
            tooltip: 'Re-center on my location',
            onPressed: () {
              if (_userLocation != null) {
                _mapController.move(_userLocation!, 15.0);
              } else {
                _getUserLocation();
              }
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _userLocation ?? const LatLng(13.0827, 80.2707),
              initialZoom: 15,
              onTap: (_, point) => _onMapTap(point),
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'safe_transit_flutter',
              ),
              // Road-following polyline
              if (polyline.length > 1)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: polyline,
                      strokeWidth: 5,
                      color: _polylineColor,
                      strokeCap: StrokeCap.round,
                    ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  if (_userLocation != null)
                    Marker(
                      point: _userLocation!,
                      width: 48,
                      height: 48,
                      child: const Icon(Icons.my_location,
                          color: Colors.blue, size: 32),
                    ),
                  if (_destination != null)
                    Marker(
                      point: _destination!,
                      width: 48,
                      height: 56,
                      child: const Icon(Icons.location_pin,
                          color: Colors.red, size: 40),
                    ),
                  ..._nearbyStops.map(
                    (stop) => Marker(
                      point: LatLng(stop.lat, stop.lng),
                      width: 32,
                      height: 32,
                      child: GestureDetector(
                        onTap: () => _showStopDetails(stop),
                        child: Icon(
                          Icons.directions_bus,
                          color: _safetyColor(stop.safetyScore),
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                  // Transit stop markers on path
                  ..._safestPath
                      .where((s) => !s.stopId.startsWith('direct_'))
                      .map(
                        (stop) => Marker(
                          point: LatLng(stop.lat, stop.lng),
                          width: 20,
                          height: 20,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                      ),
                ],
              ),
            ],
          ),

          // Locating overlay
          if (_locating)
            Container(
              color: Colors.black45,
              child: const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Getting your location...',
                            style: TextStyle(fontSize: 16)),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Route planning spinner
          if (_loading && !_locating)
            const Positioned(
              top: 16,
              right: 16,
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 8),
                      Text('Finding route...'),
                    ],
                  ),
                ),
              ),
            ),

          // Tap hint
          if (_awaitingDestination && !_locating && _error == null)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Card(
                color: Colors.blue.shade50,
                child: const Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      Icon(Icons.touch_app, color: Colors.blue),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Your location found! Tap anywhere on the map to set your destination.',
                          style: TextStyle(color: Colors.blue),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Error / warning banner
          if (_error != null)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Card(
                color: Colors.orange.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline,
                          color: Colors.orange),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style:
                              const TextStyle(color: Colors.deepOrange),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close,
                            color: Colors.deepOrange, size: 18),
                        onPressed: () => setState(() => _error = null),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Route card
          if (polyline.length > 1 || _safestPath.isNotEmpty)
            Positioned(
              bottom: 20,
              left: 16,
              right: 16,
              child: _RouteCard(
                path: _safestPath,
                routeMode: _routeMode,
                onReset: _resetRoute,
              ),
            ),
        ],
      ),
    );
  }

  void _showStopDetails(Stop stop) {
    showModalBottomSheet(
      context: context,
      builder: (_) => _StopDetailSheet(stop: stop),
    );
  }
}

class _RouteCard extends StatelessWidget {
  final List<Stop> path;
  final RouteMode routeMode;
  final VoidCallback onReset;

  const _RouteCard({
    required this.path,
    required this.routeMode,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final sum = path.fold<int>(0, (acc, s) => acc + s.safetyScore);
    final avgScore = path.isEmpty ? 0 : (sum ~/ path.length);

    String title;
    IconData icon;
    Color iconColor;
    String subtitle;

    switch (routeMode) {
      case RouteMode.transit:
        title = 'Safest Transit Route';
        icon = Icons.directions_bus;
        iconColor = Colors.blue;
        subtitle = '${path.length} stops · Avg safety: $avgScore/100';
        break;
      case RouteMode.road:
        title = 'Road Route';
        icon = Icons.directions_car;
        iconColor = Colors.green.shade700;
        subtitle = 'Following actual roads via OSRM';
        break;
      case RouteMode.direct:
        title = 'Direct Route';
        icon = Icons.straighten;
        iconColor = Colors.grey;
        subtitle = 'Straight-line path (no roads available)';
        break;
    }

    return Card(
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 18, color: iconColor),
                    const SizedBox(width: 6),
                    Text(title,
                        style: Theme.of(context).textTheme.titleMedium),
                  ],
                ),
                TextButton.icon(
                  onPressed: onReset,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Reset'),
                ),
              ],
            ),
            Text(subtitle),
            if (path.isNotEmpty) ...[
              const SizedBox(height: 8),
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: path.length,
                  separatorBuilder: (_, __) =>
                      const Icon(Icons.arrow_forward, size: 16),
                  itemBuilder: (_, i) => Chip(
                    label: Text(path[i].stopName,
                        style: const TextStyle(fontSize: 11)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StopDetailSheet extends StatefulWidget {
  final Stop stop;

  const _StopDetailSheet({required this.stop});

  @override
  State<_StopDetailSheet> createState() => _StopDetailSheetState();
}

class _StopDetailSheetState extends State<_StopDetailSheet> {
  Map<String, dynamic>? _details;

  @override
  void initState() {
    super.initState();
    SafetyApiService.getSafetyScore(widget.stop.stopId).then((data) {
      if (mounted) setState(() => _details = data);
    }).catchError((_) {
      if (mounted) {
        setState(() => _details = {'error': 'Failed to load details'});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final details = _details;
    if (details == null) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (details['error'] != null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(details['error'] as String),
      );
    }
    final alerts =
        (details['actionable_alerts'] as List<dynamic>? ?? const []);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.stop.stopName,
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
              'Safety Score: ${details['overall_safety_score']} (${details['grade']})'),
          const SizedBox(height: 8),
          ...alerts.map(
            (a) => Row(
              children: [
                const Icon(Icons.warning, color: Colors.orange, size: 16),
                const SizedBox(width: 4),
                Expanded(
                    child: Text(a.toString(),
                        style: const TextStyle(fontSize: 12))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}