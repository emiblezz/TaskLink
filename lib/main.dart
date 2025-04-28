import 'package:flutter/material.dart';
// Use specific imports to avoid naming conflicts
import 'package:provider/provider.dart' hide Provider;
import 'package:provider/provider.dart' as provider_pkg show Provider;
import 'package:tasklink/config/app_config.dart';
import 'package:tasklink/screens/auth/splash_screen.dart';
import 'package:tasklink/services/ai_services.dart';
import 'package:tasklink/services/analytics_service.dart';
import 'package:tasklink/services/auth_service.dart';
import 'package:tasklink/services/job_service.dart';
import 'package:tasklink/services/notification_service.dart';
import 'package:tasklink/services/profile_service.dart';
import 'package:tasklink/services/ranking_service.dart';
import 'package:tasklink/services/search_service.dart';
import 'package:tasklink/utils/deep_link_handler.dart';
import 'package:tasklink/utils/theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize AppConfig (this loads .env and SupabaseClient inside)
  await AppConfig().initialize();

  // Setup deep links for auth flow
  await DeepLinkHandler.setupDeepLinks();

  // Run the app
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Create AIService instance
    final aiService = AIService(baseUrl: AppConfig.backendUrl);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => NotificationService()),
        ChangeNotifierProvider(create: (_) => ProfileService()),
        // Updated RankingService provider using specific namespace
        provider_pkg.Provider<RankingService>(
          create: (_) => RankingService(
            supabaseClient: Supabase.instance.client,
            aiService: aiService,
          ),
        ),
        ChangeNotifierProvider(create: (_) => SearchService()),
        ChangeNotifierProvider(create: (_) => AnalyticsService()),
        // JobService needs access to AuthService and NotificationService
        ChangeNotifierProxyProvider2<AuthService, NotificationService, JobService>(
          create: (_) => JobService(),
          update: (_, authService, notificationService, jobService) {
            jobService!.setAuthService(authService);
            jobService.setNotificationService(notificationService);
            return jobService;
          },
        ),
      ],
      child: Consumer<AuthService>(
        builder: (context, authService, _) {
          return MaterialApp(
            title: 'TaskLink',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.system,
            debugShowCheckedModeBanner: false,
            // Use navigator key for deep linking
            navigatorKey: DeepLinkHandler.navigatorKey,
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}