import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tasklink/config/app_config.dart';
import 'package:tasklink/screens/auth/splash_screen.dart';
import 'package:tasklink/services/analytics_service.dart';
import 'package:tasklink/services/auth_service.dart';
import 'package:tasklink/services/job_service.dart';
import 'package:tasklink/services/notification_service.dart';
import 'package:tasklink/services/profile_service.dart';
import 'package:tasklink/services/ranking_service.dart';
import 'package:tasklink/services/search_service.dart';
import 'package:tasklink/utils/theme.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize AppConfig (this loads .env and SupabaseClient inside)
  await AppConfig().initialize();

  // Run the app
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => NotificationService()),
        ChangeNotifierProvider(create: (_) => ProfileService()),
        ChangeNotifierProvider(create: (_) => RankingService()),
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
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}