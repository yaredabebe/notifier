import 'package:flutter/material.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:workmanager/workmanager.dart';
import 'database/hive_service.dart';
import 'services/notification_service.dart';
import 'services/scheduler_service.dart';
import 'services/background_service.dart';
import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';
import 'app/app_theme.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize timezone for scheduling
  tz.initializeTimeZones();
  
  // Initialize encrypted database
  final hiveService = HiveService();
  await hiveService.init();
  
  // Initialize notification service
  final notificationService = NotificationService();
  await notificationService.init();
  
  // Initialize background service
  final backgroundService = BackgroundService();
  await backgroundService.init();
  
  // Schedule all existing events
  final schedulerService = SchedulerService();
  await schedulerService.scheduleAllEvents();
  
  // Start periodic check
  backgroundService.startPeriodicCheck();
  
  runApp(const NotifyApp());
}

class NotifyApp extends StatefulWidget {
  const NotifyApp({super.key});

  @override
  State<NotifyApp> createState() => _NotifyAppState();
}

class _NotifyAppState extends State<NotifyApp> {
  int _selectedIndex = 0;
  
  final List<Widget> _screens = [
    const HomeScreen(),
    const SettingsScreen(),
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