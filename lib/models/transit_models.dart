class TransitStopTime {
  const TransitStopTime({
    required this.stopId,
    required this.name,
    required this.time,
  });

  final String stopId;
  final String name;
  final String time;

  Map<String, Object?> toJson() => {
    'stopId': stopId,
    'name': name,
    'time': time,
  };

  factory TransitStopTime.fromJson(Map<String, dynamic> json) => TransitStopTime(
    stopId: json['stopId'] as String? ?? '',
    name: json['name'] as String? ?? '',
    time: json['time'] as String? ?? '',
  );
}

class TransitDirection {
  const TransitDirection({
    required this.id,
    required this.originName,
    required this.destinationName,
    required this.departures,
    required this.stops,
  });

  final String id;
  final String originName;
  final String destinationName;
  final List<String> departures;
  final List<TransitStopTime> stops;

  TransitDirection copyWith({
    String? id,
    String? originName,
    String? destinationName,
    List<String>? departures,
    List<TransitStopTime>? stops,
  }) => TransitDirection(
    id: id ?? this.id,
    originName: originName ?? this.originName,
    destinationName: destinationName ?? this.destinationName,
    departures: departures ?? this.departures,
    stops: stops ?? this.stops,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'originName': originName,
    'destinationName': destinationName,
    'departures': departures,
    'stops': stops.map((stop) => stop.toJson()).toList(),
  };

  factory TransitDirection.fromJson(Map<String, dynamic> json) => TransitDirection(
    id: json['id'] as String? ?? '0',
    originName: json['originName'] as String? ?? '',
    destinationName: json['destinationName'] as String? ?? '',
    departures: (json['departures'] as List<dynamic>? ?? const [])
        .map((time) => time.toString())
        .toList(),
    stops: (json['stops'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(TransitStopTime.fromJson)
        .toList(),
  );
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
  });

  final String id;
  final String code;
  final String name;
  final int stopCount;
  final List<TransitDirection> directions;
  final DateTime? updatedAt;
  final bool isManual;

  TransitLine copyWith({
    String? id,
    String? code,
    String? name,
    int? stopCount,
    List<TransitDirection>? directions,
    DateTime? updatedAt,
    bool? isManual,
  }) => TransitLine(
    id: id ?? this.id,
    code: code ?? this.code,
    name: name ?? this.name,
    stopCount: stopCount ?? this.stopCount,
    directions: directions ?? this.directions,
    updatedAt: updatedAt ?? this.updatedAt,
    isManual: isManual ?? this.isManual,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'code': code,
    'name': name,
    'stopCount': stopCount,
    'directions': directions.map((direction) => direction.toJson()).toList(),
    'updatedAt': updatedAt?.toIso8601String(),
    'isManual': isManual,
  };

  factory TransitLine.fromJson(Map<String, dynamic> json) => TransitLine(
    id: json['id'] as String? ?? '',
    code: json['code'] as String? ?? '',
    name: json['name'] as String? ?? '',
    stopCount: (json['stopCount'] as num?)?.toInt() ?? 0,
    directions: (json['directions'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(TransitDirection.fromJson)
        .toList(),
    updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? ''),
    isManual: json['isManual'] as bool? ?? false,
  );
}

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
    startsAt: DateTime.tryParse(json['startsAt'] as String? ?? '') ?? DateTime.now(),
    endsAt: DateTime.tryParse(json['endsAt'] as String? ?? ''),
    sourceName: json['sourceName'] as String?,
    sourceUrl: json['sourceUrl'] as String?,
    affectedLines: (json['affectedLines'] as List<dynamic>? ?? const [])
        .map((value) => value.toString())
        .toList(),
    isPublished: json['isPublished'] as bool? ?? false,
  );
}
