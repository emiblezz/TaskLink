
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppConfig {
  // Singleton instance
  static final AppConfig _instance = AppConfig._internal();
  factory AppConfig() => _instance;
  AppConfig._internal();

  // Initialize app configuration and services
  Future<void> initialize() async {
    try {
      // Load environment variables
      await dotenv.load();

      // Initialize Supabase
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
        debug: kDebugMode,
      );

      debugPrint('AppConfig initialized successfully');
    } catch (e) {
      debugPrint('Error initializing AppConfig: $e');
    }
  }
  SupabaseClient get supabaseClient => Supabase.instance.client;
  GoTrueClient get authClient => Supabase.instance.client.auth;
  // Supabase configuration - read from .env file
  static String get supabaseUrl =>
      dotenv.env['SUPABASE_URL'] ?? "https://tvsgsvnqdahjnvwdnufk.supabase.co";

  static String get supabaseAnonKey =>
      dotenv.env['SUPABASE_ANON_KEY'] ?? "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InR2c2dzdm5xZGFoam52d2RudWZrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDQwMDM2MDAsImV4cCI6MjA1OTU3OTYwMH0.vePVS5IadUZIqq1lwbanMUdlR-95G4zXUunfMSCrWAQ";

  // AI Backend configuration
  static String get backendUrl =>
      dotenv.env['BACKEND_URL'] ?? 'http://127.0.0.1:8000';

  // App metadata
  static const String appName = 'TaskLink';
  static const String appVersion = '1.0.0';
}
















