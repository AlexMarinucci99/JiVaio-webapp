import 'package:flutter/material.dart';

/// Tracks the named page beneath dialogs, which have anonymous routes.
class SectionRouteObserver extends NavigatorObserver {
  final List<Route<dynamic>> _routes = [];

  bool get supportsPersistentScrollbars {
    for (final route in _routes.reversed) {
      final name = route.settings.name;
      if (name != null) {
        return name == '/admin' ||
            name == '/lines' ||
            name.startsWith('/line/');
      }
    }
    return false;
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _routes.add(route);

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _routes.remove(route);

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _routes.remove(route);

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    final index = _routes.indexOf(oldRoute!);
    if (index >= 0) {
      if (newRoute == null) {
        _routes.removeAt(index);
      } else {
        _routes[index] = newRoute;
      }
    }
  }
}

class SectionScrollBehavior extends MaterialScrollBehavior {
  const SectionScrollBehavior(this.routes);

  final SectionRouteObserver routes;

  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    final platform = getPlatform(context);
    final desktop =
        platform == TargetPlatform.linux ||
        platform == TargetPlatform.macOS ||
        platform == TargetPlatform.windows;
    if (desktop &&
        MediaQuery.sizeOf(context).width >= 650 &&
        routes.supportsPersistentScrollbars &&
        axisDirectionToAxis(details.direction) == Axis.vertical) {
      return Scrollbar(
        controller: details.controller,
        thumbVisibility: true,
        trackVisibility: true,
        interactive: true,
        child: child,
      );
    }
    return super.buildScrollbar(context, child, details);
  }
}
