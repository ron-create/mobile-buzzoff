import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Add dotenv import
import 'package:firebase_core/firebase_core.dart';
import 'routes/routes.dart'; // Import your routes file
import 'supabase/supabase_config.dart'; // Import your Supabase config
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'utils/notification_permission.dart';
import 'services/firebase_api.dart';
import 'theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'pages/userpages/settings.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized(); // Ensure Flutter is initialized
    await dotenv.load(fileName: "assets/.env");

    debugPrint('🚀 Starting app initialization...');

    // Initialize Firebase
    debugPrint('🔥 Initializing Firebase...');
    await Firebase.initializeApp();
    debugPrint('✅ Firebase initialized successfully');

    // Initialize Supabase first
    debugPrint('🔄 Initializing Supabase...');
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!,
      anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
    );
    debugPrint('✅ Supabase initialized successfully');
    
    // Initialize Firebase Cloud Messaging after Supabase
    debugPrint('📱 Initializing Firebase Cloud Messaging...');
    final firebaseApi = FirebaseApi();
    await firebaseApi.initNotifications();
    debugPrint('✅ Firebase Cloud Messaging initialized');

    debugPrint('🚀 App initialization completed');
    runApp(
      ChangeNotifierProvider(
        create: (_) => ThemeModeNotifier(),
        child: const MyApp(),
      ),
    );
  } catch (e) {
    debugPrint('❌ Error during app initialization: $e');
    rethrow;
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeModeNotifier>(context);
    return MaterialApp.router(
      title: 'BuzzOffPh',
      debugShowCheckedModeBanner: false,
      theme: appLightTheme,
      darkTheme: appDarkTheme,
      themeMode: themeNotifier.themeMode,
      routerConfig: appRouter,  // Router setup
      builder: (context, child) {
        // Listen to auth state changes
        supabase.auth.onAuthStateChange.listen((data) {
          final AuthChangeEvent event = data.event;
          if (event == AuthChangeEvent.signedIn) {
            // User signed in
            context.go('/home');
          } else if (event == AuthChangeEvent.signedOut) {
            // User signed out
            context.go('/');
          }
        });

        // Check and request notification permission
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!await NotificationPermission.hasBeenAsked()) {
            final granted = await NotificationPermission.requestPermission();
            if (!granted) {
              // Show a dialog explaining why notifications are important
              if (context.mounted) {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Enable Notifications'),
                    content: const Text(
                      'Notifications help you stay updated with important alerts about dengue cases and breeding sites in your area.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Not Now'),
                      ),
                      TextButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          await NotificationPermission.requestPermission();
                        },
                        child: const Text('Enable'),
                      ),
                    ],
                  ),
                );
              }
            }
          }
        });

        return child!;
      },
    );
  }
}
