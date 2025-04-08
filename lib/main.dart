import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tasklink/config/app_config.dart';
import 'package:tasklink/screens/auth/splash_screen.dart';
import 'package:tasklink/services/auth_service.dart';
import 'package:tasklink/services/job_service.dart';
import 'package:tasklink/services/profile_service.dart';
import 'package:tasklink/utils/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize AppConfig and Supabase
  await AppConfig().initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => JobService()),
        ChangeNotifierProvider(create: (_) => ProfileService()),
      ],
      child: MaterialApp(
        title: 'TaskLink',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        debugShowCheckedModeBanner: false,
        home: const SplashScreen(),
      ),
    );
  }
}