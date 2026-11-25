import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'i18n/app_language.dart';

import 'data/jivaio_store.dart';
import 'data/supabase_config.dart';
import 'theme/jivaio_theme.dart';
import 'ui/admin_access_page.dart';
import 'ui/desktop_scroll_behavior.dart';
import 'ui/public_pages.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseConfig.initialize();
  final language = await AppLanguage.load();
  runApp(JivaioRoot(language: language));
}

class JivaioRoot extends StatefulWidget {
  const JivaioRoot({required this.language, super.key});

  final AppLanguage language;

  @override
  State<JivaioRoot> createState() => _JivaioRootState();
}

class _JivaioRootState extends State<JivaioRoot> {
  late final JivaioStore _store;
  final SectionRouteObserver _sectionRoutes = SectionRouteObserver();

  @override
  void initState() {
    super.initState();
    _store = JivaioStore()..load();
  }

  @override
  void dispose() {
    _store.dispose();
    super.dispose();
  }

  Route<dynamic> _route(RouteSettings settings) {
    final name = settings.name ?? '/';
    if (name.startsWith('/line/')) {
      return MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => LineDetailPage(
          store: _store,
          lineId: Uri.decodeComponent(name.substring('/line/'.length)),
        ),
      );
    }
    if (name == '/' || name == '/lines' || name == '/alerts') {
      return PageRouteBuilder<void>(
        settings: settings,
        transitionDuration: const Duration(milliseconds: 240),
        reverseTransitionDuration: const Duration(milliseconds: 180),
        pageBuilder: (context, animation, secondaryAnimation) => switch (name) {
          '/lines' => LinesPage(store: _store),
          '/alerts' => AlertsPage(store: _store),
          _ => HomePage(store: _store),
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          if (MediaQuery.disableAnimationsOf(context)) return child;
          final curve = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );
          return FadeTransition(
            opacity: curve,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, .012),
                end: Offset.zero,
              ).animate(curve),
              child: child,
            ),
          );
        },
      );
    }
    return MaterialPageRoute<void>(
      settings: settings,
      builder: (_) => switch (name) {
        '/lines' => LinesPage(store: _store),
        '/alerts' => AlertsPage(store: _store),
        '/admin' => AdminAccessPage(store: _store),
        _ => HomePage(store: _store),
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return LanguageScope(
      language: widget.language,
      child: AnimatedBuilder(
        animation: widget.language,
        builder: (context, _) => MaterialApp(
          locale: Locale(widget.language.code),
          supportedLocales: languageNames.keys.map(Locale.new),
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          title: tr(context, 'JiVaio · Linee e orari'),
          debugShowCheckedModeBanner: false,
          theme: buildJivaioTheme(),
          scrollBehavior: SectionScrollBehavior(_sectionRoutes),
          navigatorObservers: [_sectionRoutes],
          onGenerateRoute: _route,
          initialRoute: '/',
        ),
      ),
    );
  }
}
