/// Returns original positions in timetable order, keeping equal or invalid
/// times in their original order. Hours beyond 24 retain GTFS service-day order.
List<int> timetableOrder(List<String> times) {
  int? seconds(String value) {
    final match = RegExp(r'^(\d{1,2}):([0-5]\d)(?::([0-5]\d))?$')
        .firstMatch(value.trim());
    if (match == null) return null;
    final hour = int.parse(match.group(1)!);
    if (hour >= 48) return null;
    return hour * 3600 +
        int.parse(match.group(2)!) * 60 +
        int.parse(match.group(3) ?? '0');
  }

  final indices = List.generate(times.length, (index) => index);
  indices.sort((a, b) {
    final first = seconds(times[a]);
    final second = seconds(times[b]);
    if (first == null && second == null) return a.compareTo(b);
    if (first == null) return 1;
    if (second == null) return -1;
    final comparison = first.compareTo(second);
    return comparison == 0 ? a.compareTo(b) : comparison;
  });
  return indices;
}
