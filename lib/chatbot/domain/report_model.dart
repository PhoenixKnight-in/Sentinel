class ReportModel {
  final String incidentType;
  final double? latitude;
  final double? longitude;
  final String surroundings;
  final String alertChoice;
  final DateTime timestamp;

  const ReportModel({
    required this.incidentType,
    this.latitude,
    this.longitude,
    required this.surroundings,
    required this.alertChoice,
    required this.timestamp,
  });

  Map<String, dynamic> toFirestore() => {
    'incidentType': incidentType,
    'location': (latitude != null)
        ? {'lat': latitude, 'lng': longitude}
        : null,
    'surroundings':  surroundings,
    'alertChoice':   alertChoice,
    'status':        'submitted',
    'createdAt':     timestamp.toIso8601String(),
  };
}