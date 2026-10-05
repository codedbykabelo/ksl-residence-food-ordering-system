import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/app_state.dart';
import 'screens/auth_screens.dart';
import 'screens/staff_screens.dart';
import 'screens/student_screens.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final browserPath = Uri.base.path.toLowerCase();
    final initialRoute = browserPath == '/staff' || browserPath == '/staff/'
        ? '/staff'
        : '/';

    return ChangeNotifierProvider(
      create: (_) => AppState()..initialize(),
      child: MaterialApp(
        title: 'KSL Residence Food Ordering System',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF0E7C5C),
            brightness: Brightness.light,
          ),
          scaffoldBackgroundColor: const Color(0xFFF4F7F3),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF0E7C5C),
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          cardTheme: CardThemeData(
            elevation: 0,
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(20)),
            ),
          ),
        ),
        routes: {
          '/': (_) => const SplashScreen(),
          '/student-login': (_) => const StudentLoginScreen(),
          '/student-register': (_) => const StudentRegistrationScreen(),
          '/student-home': (_) => const StudentHomeScreen(),
          '/staff': (_) => const StaffLoginScreen(),
          '/staff-login': (_) => const StaffLoginScreen(),
          '/staff-dashboard': (_) => const StaffDashboardScreen(),
        },
        initialRoute: initialRoute,
      ),
    );
  }
}
