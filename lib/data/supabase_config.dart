import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  SupabaseConfig._();

  static const url = String.fromEnvironment('SUPABASE_URL');
  static const publishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );
  static bool get isConfigured => url.isNotEmpty && publishableKey.isNotEmpty;

  static bool isInitialized = false;
  static String? initializationError;

  static Future<void> initialize() async {
    if (!isConfigured) {
      return;
    }
    try {
      await Supabase.initialize(url: url, publishableKey: publishableKey);
      isInitialized = true;
    } catch (_) {
      initializationError =
          'Controlla URL e publishable key del progetto Supabase.';
    }
  }
}
