import 'package:flutter/material.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'database/hive_service.dart';
import 'services/notification_service.dart';
import 'services/scheduler_service.dart';
import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';
import 'app/app_theme.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Add global error catcher
  FlutterError.onError = (FlutterErrorDetails details) {
    print('=' * 50);
    print('FLUTTER ERROR: ${details.exception}');
    print('Stack trace: ${details.stack}');
    print('=' * 50);
  };
  
  runApp(const LoadingApp());
  
  // Initialize after runApp to show loading screen
  await initializeApp();
}

Future<void> initializeApp() async {
  try {
    print('🟢 Starting app initialization...');
    
    // Initialize timezone
    tz.initializeTimeZones();
    print('✅ Timezone initialized');
    
    // Initialize Hive
    final hiveService = HiveService();
    await hiveService.init();
    print('✅ Hive initialized, events: ${hiveService.getEventCount()}');
    
    // Initialize notifications
    final notificationService = NotificationService();
    await notificationService.init();
    print('✅ Notification service initialized');
    
    // Schedule events
    final schedulerService = SchedulerService();
    await schedulerService.scheduleAllEvents();
    print('✅ Events scheduled');
    
    // Navigate to main app
    navigatorKey.currentState?.pushReplacement(
      MaterialPageRoute(builder: (_) => const NotifyApp()),
    );
  } catch (e, stackTrace) {
    print('❌ INITIALIZATION ERROR: $e');
    print('Stack trace: $stackTrace');
    
    // Show error screen
    navigatorKey.currentState?.pushReplacement(
      MaterialPageRoute(
        builder: (_) => ErrorScreen(error: e.toString(), stackTrace: stackTrace.toString()),
      ),
    );
  }
}

class LoadingApp extends StatelessWidget {
  const LoadingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NOTIFY',
      theme: AppTheme.lightTheme,
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text('Loading NOTIFY...'),
              SizedBox(height: 10),
              Text(
                'Please wait while we setup your alarms',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class NotifyApp extends StatefulWidget {
  const NotifyApp({super.key});

  @override
  State<NotifyApp> createState() => _NotifyAppState();
}

class _NotifyAppState extends State<NotifyApp> {
  int _selectedIndex = 0;
  
  final List<Widget> _screens = const [
    HomeScreen(),
    SettingsScreen(),
  ];
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NOTIFY - Important Moments',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      navigatorKey: navigatorKey,
      home: Scaffold(
        body: _screens[_selectedIndex],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Events',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
        ),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}

class ErrorScreen extends StatelessWidget {
  final String error;
  final String stackTrace;
  
  const ErrorScreen({super.key, required this.error, required this.stackTrace});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NOTIFY - Error',
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Initialization Error'),
          backgroundColor: Colors.red,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Failed to start app:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  error,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Stack trace:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      stackTrace,
                      style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  // Restart app
                  // In production, you might want to restart the app
                },
                child: const Text('Close App'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}