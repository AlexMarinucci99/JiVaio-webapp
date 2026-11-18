import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class SupabaseConfig {
  SupabaseConfig._();

  static const url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://lilkvangfedtkzwqmgzs.supabase.co',
  );
  static const publishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: 'sb_publishable_v8GDClT_w57s5IwivbkqNQ_D1u3damt',
  );
  static const _localAdminPreviewRequested = bool.fromEnvironment(
    'JIVAIO_LOCAL_ADMIN_PREVIEW',
  );
  static bool get localAdminPreviewEnabled =>
      kDebugMode && _localAdminPreviewRequested && !isConfigured;
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
