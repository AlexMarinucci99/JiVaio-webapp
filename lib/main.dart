import 'package:flutter/material.dart';

import 'data/jivaio_store.dart';
import 'data/supabase_config.dart';
import 'theme/jivaio_theme.dart';
import 'ui/admin_access_page.dart';
import 'ui/public_pages.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseConfig.initialize();
  runApp(const JivaioRoot());
}

class JivaioRoot extends StatefulWidget {
  const JivaioRoot({super.key});

  @override
  State<JivaioRoot> createState() => _JivaioRootState();
}

class _JivaioRootState extends State<JivaioRoot> {
  late final JivaioStore _store;

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
    return MaterialApp(
      title: 'JiVaio · Linee e orari',
      debugShowCheckedModeBanner: false,
      theme: buildJivaioTheme(),
      onGenerateRoute: _route,
      initialRoute: '/',
    );
  }
}
