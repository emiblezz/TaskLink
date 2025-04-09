import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase/supabase.dart';
import 'package:gotrue/gotrue.dart';

class AppConfig {
  // Singleton pattern
  AppConfig._privateConstructor();
  static final AppConfig _instance = AppConfig._privateConstructor();
  factory AppConfig() => _instance;

  // Supabase client
  late SupabaseClient _supabaseClient;
  late GoTrueClient _authClient;

  // Initialize Supabase
  Future<void> initialize() async {
    try {
      await dotenv.load(fileName: ".env");
      print(".env file loaded successfully");

      final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
      final supabaseKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

      print("SUPABASE_URL: ${supabaseUrl.isNotEmpty ? 'Found' : 'Not found'}");
      print("SUPABASE_ANON_KEY: ${supabaseKey.isNotEmpty ? 'Found' : 'Not found'}");

      _supabaseClient = SupabaseClient(supabaseUrl, supabaseKey);
      _authClient = _supabaseClient.auth;
    } catch (e) {
      print("Error loading .env file: $e");

      // Fallback to hardcoded values if .env file loading fails
      final supabaseUrl = "https://tvsgsvnqdahjnvwdnufk.supabase.co";
      final supabaseKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InR2c2dzdm5xZGFoam52d2RudWZrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDQwMDM2MDAsImV4cCI6MjA1OTU3OTYwMH0.vePVS5IadUZIqq1lwbanMUdlR-95G4zXUunfMSCrWAQ";

      print("Using fallback Supabase credentials");
      _supabaseClient = SupabaseClient(supabaseUrl, supabaseKey);
      _authClient = _supabaseClient.auth;
    }
  }

  // Instance-level getters
  SupabaseClient get supabaseClient => _supabaseClient;
  GoTrueClient get authClient => _authClient;

  // App constants
  static const String appName = 'TaskLink';
  static const String appVersion = '1.0.0';

  // App-wide settings
  bool isDarkMode = false;
  String languageCode = 'en';
}
