import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:master_lines/ui/desktop_scroll_behavior.dart';

void main() {
  Future<void> showList(WidgetTester tester, {required double width}) async {
    tester.view.physicalSize = Size(width, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final routes = SectionRouteObserver();
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(platform: TargetPlatform.linux),
        scrollBehavior: SectionScrollBehavior(routes),
        navigatorObservers: [routes],
        initialRoute: '/lines',
        onGenerateRoute: (settings) => MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => Scaffold(
            body: ListView.builder(
              itemExtent: 50,
              itemCount: 100,
              itemBuilder: (_, index) => Text('Item $index'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'desktop scrollbar stays visible and supports drag and track taps',
    (tester) async {
      await showList(tester, width: 1000);
      final scrollbar = tester.widget<Scrollbar>(find.byType(Scrollbar));
      expect(scrollbar.thumbVisibility, isTrue);
      expect(scrollbar.trackVisibility, isTrue);
      expect(scrollbar.interactive, isTrue);
      final scrollable = tester.state<ScrollableState>(
        find.byType(Scrollable).first,
      );
      await tester.dragFrom(const Offset(996, 30), const Offset(0, 180));
      await tester.pumpAndSettle();
      expect(scrollable.position.pixels, greaterThan(0));
      final afterDrag = scrollable.position.pixels;
      await tester.tapAt(const Offset(996, 550));
      await tester.pumpAndSettle();
      expect(scrollable.position.pixels, greaterThan(afterDrag));
    },
  );

  testWidgets('narrow layout retains the default scrollbar behavior', (
    tester,
  ) async {
    await showList(tester, width: 400);
    final scrollbar = tester.widget<Scrollbar>(find.byType(Scrollbar));
    expect(scrollbar.thumbVisibility, isNull);
    expect(scrollbar.trackVisibility, isNull);
  });
}
