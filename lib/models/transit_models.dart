class TransitStopTime {
  const TransitStopTime({
    required this.stopId,
    required this.name,
    required this.time,
    this.isEstimated = false,
  });

  final String stopId;
  final String name;
  final String time;
  final bool isEstimated;

  Map<String, Object?> toJson() => {
    'stopId': stopId,
    'name': name,
    'time': time,
    'isEstimated': isEstimated,
  };

  factory TransitStopTime.fromJson(Map<String, dynamic> json) =>
      TransitStopTime(
        stopId: json['stopId'] as String? ?? '',
        name: json['name'] as String? ?? '',
        time: json['time'] as String? ?? '',
        isEstimated: json['isEstimated'] as bool? ?? false,
      );
}

class TransitTrip {
  const TransitTrip({
    required this.id,
    required this.departureTime,
    required this.stops,
    this.headsign = '',
    this.note = '',
  });

  final String id;
  final String departureTime;
  final String headsign;
  final String note;
  final List<TransitStopTime> stops;

  Map<String, Object?> toJson() => {
    'id': id,
    'departureTime': departureTime,
    'headsign': headsign,
    'note': note,
    'stops': stops.map((stop) => stop.toJson()).toList(),
  };

  factory TransitTrip.fromJson(Map<String, dynamic> json) => TransitTrip(
    id: json['id'] as String? ?? '',
    departureTime: json['departureTime'] as String? ?? '',
    headsign: json['headsign'] as String? ?? '',
    note: json['note'] as String? ?? '',
    stops: (json['stops'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(TransitStopTime.fromJson)
        .toList(),
  );
}

class TransitDirection {
  const TransitDirection({
    required this.id,
    required this.originName,
    required this.destinationName,
    required this.departures,
    required this.stops,
    this.serviceId = '',
    this.serviceLabel = '',
    this.dataWarning,
    this.trips = const [],
  });

  final String id;
  final String originName;
  final String destinationName;
  final List<String> departures;
  final List<TransitStopTime> stops;
  final String serviceId;
  final String serviceLabel;
  final String? dataWarning;
  final List<TransitTrip> trips;

  TransitDirection copyWith({
    String? id,
    String? originName,
    String? destinationName,
    List<String>? departures,
    List<TransitStopTime>? stops,
    String? serviceId,
    String? serviceLabel,
    String? dataWarning,
    List<TransitTrip>? trips,
  }) => TransitDirection(
    id: id ?? this.id,
    originName: originName ?? this.originName,
    destinationName: destinationName ?? this.destinationName,
    departures: departures ?? this.departures,
    stops: stops ?? this.stops,
    serviceId: serviceId ?? this.serviceId,
    serviceLabel: serviceLabel ?? this.serviceLabel,
    dataWarning: dataWarning ?? this.dataWarning,
    trips: trips ?? this.trips,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'originName': originName,
    'destinationName': destinationName,
    'departures': departures,
    'stops': stops.map((stop) => stop.toJson()).toList(),
    'serviceId': serviceId,
    'serviceLabel': serviceLabel,
    'dataWarning': dataWarning,
    'trips': trips.map((trip) => trip.toJson()).toList(),
  };

  factory TransitDirection.fromJson(Map<String, dynamic> json) =>
      TransitDirection(
        id: json['id'] as String? ?? '0',
        originName: json['originName'] as String? ?? '',
        destinationName: json['destinationName'] as String? ?? '',
        serviceId: json['serviceId'] as String? ?? '',
        serviceLabel: json['serviceLabel'] as String? ?? '',
        dataWarning: json['dataWarning'] as String?,
        departures: (json['departures'] as List<dynamic>? ?? const [])
            .map((time) => time.toString())
            .toList(),
        stops: (json['stops'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(TransitStopTime.fromJson)
            .toList(),
        trips: _tripsFromJson(json),
      );
}

List<TransitTrip> _tripsFromJson(Map<String, dynamic> json) {
  final rawTrips = json['trips'];
  final trips = rawTrips is List
      ? rawTrips
            .whereType<Map<String, dynamic>>()
            .map(TransitTrip.fromJson)
            .toList()
      : <TransitTrip>[];
  if (trips.isNotEmpty ||
      (json['departures'] as List<dynamic>? ?? const []).isEmpty) {
    return trips;
  }
  return _legacyTrips(json);
}

List<TransitTrip> _legacyTrips(Map<String, dynamic> json) {
  final departures = (json['departures'] as List<dynamic>? ?? const [])
      .map((time) => time.toString())
      .toList();
  final stops = (json['stops'] as List<dynamic>? ?? const [])
      .whereType<Map<String, dynamic>>()
      .map(TransitStopTime.fromJson)
      .toList();
  return [
    for (var i = 0; i < departures.length; i++)
      TransitTrip(
        id: '${json['id'] ?? 'legacy'}-$i',
        departureTime: departures[i],
        // The legacy editor stored one sample route for the whole schedule.
        // Keep it on the first departure only; later routes need verification.
        stops: i == 0 ? stops : const [],
      ),
  ];
}

List<TransitDirection> mergeCircularDirections(
  List<TransitDirection> directions,
) {
  final groups = <String, List<TransitDirection>>{};
  for (final direction in directions) {
    groups.putIfAbsent(direction.serviceId, () => []).add(direction);
  }

  final merged = <TransitDirection>[];
  for (final entry in groups.entries) {
    final group = entry.value;
    final trips = <TransitTrip>[];
    for (final direction in group) {
      if (direction.trips.isNotEmpty) {
        trips.addAll(direction.trips);
      } else if (direction.departures.isEmpty) {
        if (direction.stops.isNotEmpty) {
          trips.add(
            TransitTrip(
              id: '${direction.id}-legacy',
              departureTime: '',
              stops: direction.stops,
            ),
          );
        }
      } else {
        for (var i = 0; i < direction.departures.length; i++) {
          trips.add(
            TransitTrip(
              id: '${direction.id}-$i',
              departureTime: direction.departures[i],
              stops: i == 0 ? direction.stops : const [],
            ),
          );
        }
      }
    }
    final usedTripIds = <String>{};
    for (var i = 0; i < trips.length; i++) {
      final trip = trips[i];
      final baseId = trip.id.isEmpty ? 'trip-${entry.key}-$i' : trip.id;
      var tripId = baseId;
      var suffix = 2;
      while (!usedTripIds.add(tripId)) {
        tripId = '$baseId-$suffix';
        suffix++;
      }
      if (tripId != trip.id) {
        trips[i] = TransitTrip(
          id: tripId,
          departureTime: trip.departureTime,
          headsign: trip.headsign,
          note: trip.note,
          stops: trip.stops,
        );
      }
    }
    trips.sort((a, b) => a.departureTime.compareTo(b.departureTime));
    final routeStops = trips
        .map((trip) => trip.stops)
        .firstWhere((stops) => stops.isNotEmpty, orElse: () => const []);
    final warnings = group
        .map((direction) => direction.dataWarning)
        .whereType<String>()
        .toSet();
    final serviceLabel = group
        .map((direction) => direction.serviceLabel)
        .firstWhere((label) => label.isNotEmpty, orElse: () => '');
    merged.add(
      TransitDirection(
        id: 'circuit-${entry.key.isEmpty ? 'general' : entry.key}',
        originName: routeStops.isEmpty
            ? group
                  .map((direction) => direction.originName)
                  .firstWhere((name) => name.isNotEmpty, orElse: () => '')
            : routeStops.first.name,
        destinationName: 'Percorso circolare',
        departures: trips
            .map((trip) => trip.departureTime)
            .where((time) => time.isNotEmpty)
            .toList(),
        stops: routeStops,
        serviceId: entry.key,
        serviceLabel: serviceLabel.isEmpty
            ? transitServiceLabel(entry.key)
            : serviceLabel,
        dataWarning: warnings.isEmpty ? null : warnings.join(' '),
        trips: trips,
      ),
    );
  }
  return merged;
}

class TransitLine {
  const TransitLine({
    required this.id,
    required this.code,
    required this.name,
    required this.stopCount,
    required this.directions,
    this.updatedAt,
    this.isManual = false,
    this.dataWarning,
    this.isCircular = false,
    this.isVisible = true,
  });

  final String id;
  final String code;
  final String name;
  final int stopCount;
  final List<TransitDirection> directions;
  final DateTime? updatedAt;
  final bool isManual;
  final String? dataWarning;
  final bool isCircular;
  final bool isVisible;

  TransitLine copyWith({
    String? id,
    String? code,
    String? name,
    int? stopCount,
    List<TransitDirection>? directions,
    DateTime? updatedAt,
    bool? isManual,
    String? dataWarning,
    bool? isCircular,
    bool? isVisible,
  }) => TransitLine(
    id: id ?? this.id,
    code: code ?? this.code,
    name: name ?? this.name,
    stopCount: stopCount ?? this.stopCount,
    directions: directions ?? this.directions,
    updatedAt: updatedAt ?? this.updatedAt,
    isManual: isManual ?? this.isManual,
    dataWarning: dataWarning ?? this.dataWarning,
    isCircular: isCircular ?? this.isCircular,
    isVisible: isVisible ?? this.isVisible,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'code': code,
    'name': name,
    'stopCount': stopCount,
    'directions': directions.map((direction) => direction.toJson()).toList(),
    'updatedAt': updatedAt?.toIso8601String(),
    'isManual': isManual,
    'dataWarning': dataWarning,
    'isCircular': isCircular,
    'isVisible': isVisible,
  };

  factory TransitLine.fromJson(Map<String, dynamic> json) {
    final code = json['code'] as String? ?? '';
    final name = json['name'] as String? ?? '';
    final isCircular =
        json['isCircular'] == true || _isKnownCircularLine(code, name);
    final directions = (json['directions'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(TransitDirection.fromJson)
        .toList();
    return TransitLine(
      id: json['id'] as String? ?? '',
      code: code,
      name: name,
      stopCount: (json['stopCount'] as num?)?.toInt() ?? 0,
      directions: isCircular ? mergeCircularDirections(directions) : directions,
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? ''),
      isManual: json['isManual'] as bool? ?? false,
      dataWarning: json['dataWarning'] as String?,
      isCircular: isCircular,
      isVisible: json['isVisible'] as bool? ?? true,
    );
  }
}

bool _isKnownCircularLine(String code, String name) {
  final normalizedCode = code.trim().toUpperCase();
  final normalizedName = name.trim().toUpperCase();
  return normalizedCode == 'A' ||
      normalizedCode == 'B' ||
      normalizedCode == 'EST' ||
      normalizedCode == 'OVEST' ||
      normalizedName.contains('NAVETTA EST') ||
      normalizedName.contains('NAVETTA OVEST');
}

String transitServiceLabel(String serviceId) => switch (serviceId) {
  '1' => 'Feriale (lun–ven)',
  '2' => 'Sabato',
  'FESTIVO' => 'Festivo',
  'NIGHT_THSAT' => 'Notturno (gio e sab)',
  '' => 'Orari generali',
  _ => 'Calendario $serviceId',
};

class ServiceAlert {
  const ServiceAlert({
    required this.id,
    required this.title,
    required this.summary,
    required this.details,
    required this.severity,
    required this.startsAt,
    this.endsAt,
    this.sourceName,
    this.sourceUrl,
    this.affectedLines = const [],
    this.isPublished = true,
  });

  final String id;
  final String title;
  final String summary;
  final String details;
  final String severity;
  final DateTime startsAt;
  final DateTime? endsAt;
  final String? sourceName;
  final String? sourceUrl;
  final List<String> affectedLines;
  final bool isPublished;

  bool get isCurrentOrUpcoming =>
      isPublished && (endsAt == null || !endsAt!.isBefore(DateTime.now()));

  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'summary': summary,
    'details': details,
    'severity': severity,
    'startsAt': startsAt.toIso8601String(),
    'endsAt': endsAt?.toIso8601String(),
    'sourceName': sourceName,
    'sourceUrl': sourceUrl,
    'affectedLines': affectedLines,
    'isPublished': isPublished,
  };

  factory ServiceAlert.fromJson(Map<String, dynamic> json) => ServiceAlert(
    id: json['id'] as String? ?? '',
    title: json['title'] as String? ?? '',
    summary: json['summary'] as String? ?? '',
    details: json['details'] as String? ?? '',
    severity: json['severity'] as String? ?? 'info',
    startsAt:
        DateTime.tryParse(json['startsAt'] as String? ?? '') ?? DateTime.now(),
    endsAt: DateTime.tryParse(json['endsAt'] as String? ?? ''),
    sourceName: json['sourceName'] as String?,
    sourceUrl: json['sourceUrl'] as String?,
    affectedLines: (json['affectedLines'] as List<dynamic>? ?? const [])
        .map((value) => value.toString())
        .toList(),
    isPublished: json['isPublished'] as bool? ?? false,
  );
}
