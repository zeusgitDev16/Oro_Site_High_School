import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:oro_site_high_school/backend/config/supabase_config.dart';
import 'package:oro_site_high_school/core/theme/app_theme.dart';
import 'package:oro_site_high_school/screens/auth_gate.dart';
import 'package:oro_site_high_school/flow/admin/popup_observer.dart';
import 'package:oro_site_high_school/backend/auth/auth_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Try to load environment variables
  try {
    await dotenv.load(fileName: ".env");
    print('✅ Environment variables loaded successfully');
  } catch (e) {
    print('⚠️ Could not load .env file: $e');
    print('⚠️ Using default/mock configuration');
    // The app will continue with default values from Environment class
  }
  
  // Initialize Supabase with backend configuration
  try {
    await SupabaseConfig.initialize();
    print('✅ Supabase initialized successfully');
  } catch (e) {
    print('⚠️ Supabase initialization failed: $e');
    print('⚠️ Running in offline/mock mode');
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Oro High Portal',
      theme: AppTheme.lightTheme,
      // Add NavigatorObserver to automatically close popups on route changes
      navigatorObservers: [PopupNavigatorObserver()],
      home: const AuthGate(),
    );
  }
}
