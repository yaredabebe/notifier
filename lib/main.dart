import 'package:flutter/material.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'database/hive_service.dart';
import 'services/notification_service.dart';
import 'services/scheduler_service.dart';
import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';
import 'app/app_theme.dart';
import 'dart:async';
import 'package:flutter/services.dart';
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  // Catch all Flutter framework errors
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set up error handling for Flutter framework
  FlutterError.onError = (FlutterErrorDetails details) {
    print('=' * 60);
    print('🔥 FLUTTER FRAMEWORK ERROR 🔥');
    print('Error: ${details.exception}');
    print('Stack: ${details.stack}');
    print('=' * 60);
    
    // In production, you might want to send this to a crash reporting service
  };
  
  // Catch asynchronous errors
  runZonedGuarded(
    () async {
      try {
        print('🚀 Starting NOTIFY app...');
        
        // Initialize timezone
        print('📅 Initializing timezone...');
        tz.initializeTimeZones();
        print('✅ Timezone initialized');
        
        // Initialize Hive database
        print('💾 Initializing Hive database...');
        final hiveService = HiveService();
        await hiveService.init();
        print('✅ Hive initialized, found ${hiveService.getEventCount()} events');
        
        // Initialize notification service
        print('🔔 Initializing notification service...');
        final notificationService = NotificationService();
        await notificationService.init();
        print('✅ Notification service initialized');
        
        // Initialize scheduler service
        print('⏰ Initializing scheduler service...');
        final schedulerService = SchedulerService();
        await schedulerService.scheduleAllEvents();
        print('✅ Scheduler service initialized');
        
        // Run the app
        print('🎯 Running app...');
        runApp(const NotifyApp());
      } catch (e, stackTrace) {
        print('=' * 60);
        print('❌ APP INITIALIZATION FAILED ❌');
        print('Error: $e');
        print('Stack trace: $stackTrace');
        print('=' * 60);
        
        // Run error app
        runApp(ErrorApp(
          error: e.toString(),
          stackTrace: stackTrace.toString(),
        ));
      }
    },
    (error, stackTrace) {
      print('=' * 60);
      print('🔥 UNCAUGHT ASYNC ERROR 🔥');
      print('Error: $error');
      print('Stack: $stackTrace');
      print('=' * 60);
    },
  );
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
      debugShowCheckedModeBanner: false,
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
    );
  }
}

// Error screen that shows when initialization fails
class ErrorApp extends StatelessWidget {
  final String error;
  final String stackTrace;
  
  const ErrorApp({
    super.key,
    required this.error,
    required this.stackTrace,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NOTIFY - Error',
      theme: AppTheme.lightTheme,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Initialization Error'),
          backgroundColor: Colors.red,
          centerTitle: true,
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Error icon
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red.shade700,
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Error title
                const Center(
                  child: Text(
                    'Failed to Start App',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                
                const SizedBox(height: 8),
                
                const Center(
                  child: Text(
                    'The app encountered an error during initialization',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Error message
                const Text(
                  'Error Message:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Text(
                      error,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.red.shade700,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Stack trace
                const Text(
                  'Stack Trace:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SingleChildScrollView(
                      child: Text(
                        stackTrace,
                        style: const TextStyle(
                          fontSize: 11,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          // Copy error to clipboard
                          Clipboard.setData(ClipboardData(
                            text: 'Error: $error\n\nStack Trace:\n$stackTrace',
                          ));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Error copied to clipboard')),
                          );
                        },
                        icon: const Icon(Icons.copy),
                        label: const Text('Copy Error'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // Close the app
                          // For Android
                          SystemNavigator.pop();
                          // For iOS
                          // exit(0);
                        },
                        icon: const Icon(Icons.close),
                        label: const Text('Close App'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                // Help text
                Center(
                  child: TextButton(
                    onPressed: () {
                      // Show help dialog
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Need Help?'),
                          content: const Text(
                            'Common fixes:\n\n'
                            '1. Run "flutter clean"\n'
                            '2. Run "flutter pub get"\n'
                            '3. Run "flutter run --verbose"\n'
                            '4. Check if all dependencies are installed\n'
                            '5. Make sure Android SDK is up to date',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Close'),
                            ),
                          ],
                        ),
                      );
                    },
                    child: const Text('Need help?'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Add this import at the top for Clipboard and SystemNavigator
