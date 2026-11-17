import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/jivaio_store.dart';
import '../data/supabase_config.dart';
import 'admin_page.dart';

class AdminAccessPage extends StatefulWidget {
  const AdminAccessPage({required this.store, super.key});

  final JivaioStore store;

  @override
  State<AdminAccessPage> createState() => _AdminAccessPageState();
}

class _AdminAccessPageState extends State<AdminAccessPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  StreamSubscription<AuthState>? _authSubscription;
  int _checkVersion = 0;
  bool _isChecking = true;
  bool _isSigningIn = false;
  bool _isAdmin = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    if (SupabaseConfig.isInitialized) {
      final client = Supabase.instance.client;
      _authSubscription = client.auth.onAuthStateChange.listen((event) {
        unawaited(_checkSession(event.session));
      });
      unawaited(_checkSession(client.auth.currentSession));
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _checkSession(Session? session) async {
    final version = ++_checkVersion;
    if (!mounted) return;
    if (session == null) {
      setState(() {
        _isAdmin = false;
        _isChecking = false;
      });
      return;
    }

    setState(() => _isChecking = true);
    try {
      final membership = await Supabase.instance.client
          .from('admin_users')
          .select('user_id')
          .eq('user_id', session.user.id)
          .maybeSingle();
      if (!mounted || version != _checkVersion) return;
      if (membership == null) {
        setState(() {
          _isAdmin = false;
          _isChecking = false;
          _message = 'Questo account non è abilitato al gestionale.';
        });
        await Supabase.instance.client.auth.signOut();
        return;
      }
      setState(() {
        _isAdmin = true;
        _isChecking = false;
        _message = null;
      });
    } catch (_) {
      if (!mounted || version != _checkVersion) return;
      setState(() {
        _isAdmin = false;
        _isChecking = false;
        _message = 'Non riesco a verificare i permessi. Riprova tra poco.';
      });
      await Supabase.instance.client.auth.signOut();
    }
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSigningIn = true;
      _message = null;
    });
    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: _email.text.trim(),
        password: _password.text,
      );
    } on AuthException {
      if (mounted) {
        setState(() => _message = 'Email o password non validi.');
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _message =
              'Accesso non riuscito. Verifica la connessione e riprova.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSigningIn = false);
      }
    }
  }

  Future<void> _signOut() async {
    await Supabase.instance.client.auth.signOut();
    if (mounted) Navigator.of(context).pushReplacementNamed('/admin');
  }

  @override
  Widget build(BuildContext context) {
    if (!SupabaseConfig.isConfigured || !SupabaseConfig.isInitialized) {
      return _AccessScaffold(
        child: _AccessMessage(
          icon: Icons.lock_outline,
          title: 'Gestionale non configurato',
          body: SupabaseConfig.initializationError ?? 'L’accesso amministratore è protetto. Configura Supabase Auth e la chiave pubblica del progetto per entrare.',
          actionLabel: 'Torna alla home',
          onAction: () => Navigator.of(context).pushReplacementNamed('/'),
        ),
      );
    }

    if (_isChecking) {
      return const _AccessScaffold(
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_isAdmin) {
      return AdminPage(store: widget.store, onSignOut: _signOut);
    }

    return _AccessScaffold(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.admin_panel_settings_outlined, size: 42),
                  const SizedBox(height: 12),
                  Text(
                    'Accesso amministratore',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 22),
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.username],
                    decoration: const InputDecoration(labelText: 'Email'),
                    validator: (value) =>
                        (value == null || !value.contains('@'))
                        ? 'Inserisci un’email valida'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _password,
                    obscureText: true,
                    autofillHints: const [AutofillHints.password],
                    decoration: const InputDecoration(labelText: 'Password'),
                    validator: (value) => (value == null || value.isEmpty)
                        ? 'Inserisci la password'
                        : null,
                    onFieldSubmitted: (_) => _signIn(),
                  ),
                  if (_message != null) ...[
                    const SizedBox(height: 14),
                    Text(
                      _message!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _isSigningIn ? null : _signIn,
                    child: _isSigningIn
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Accedi'),
                  ),
                  TextButton(
                    onPressed: () =>
                        Navigator.of(context).pushReplacementNamed('/'),
                    child: const Text('Torna alla home'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AccessScaffold extends StatelessWidget {
  const _AccessScaffold({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: Padding(padding: const EdgeInsets.all(24), child: child),
      ),
    ),
  );
}

class _AccessMessage extends StatelessWidget {
  const _AccessMessage({
    required this.icon,
    required this.title,
    required this.body,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String body;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 480),
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 42),
            const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
            Text(body, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            FilledButton(onPressed: onAction, child: Text(actionLabel)),
          ],
        ),
      ),
    ),
  );
}
