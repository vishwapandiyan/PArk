import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'config/supabase_client.dart';
import 'config/theme.dart';
import 'controllers/auth_controller.dart';
import 'controllers/booking_controller.dart';
import 'controllers/slot_controller.dart';
import 'views/auth/login_screen.dart';
import 'views/auth/register_screen.dart';
import 'views/auth/splash_screen.dart';
import 'views/driver/booking_screen.dart';
import 'views/driver/slot_list_screen.dart';
import 'views/driver/slot_detail_screen.dart';
import 'views/driver/navigation_screen.dart';
import 'views/driver/ar_view_screen.dart';
import 'views/driver/driver_dashboard.dart';
import 'views/owner/owner_dashboard.dart';
import 'views/owner/manage_space_screen.dart';
import 'views/owner/analytics_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppSupabase.initialize(
    url: const String.fromEnvironment('SUPABASE_URL', defaultValue: 'https://YOUR-PROJECT.supabase.co'),
    anonKey: const String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: 'YOUR-ANON-KEY'),
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => AuthController()),
        BlocProvider(create: (_) => SlotController()),
        BlocProvider(create: (_) => BookingController()),
      ],
      child: MaterialApp(
        title: 'Smart Parking',
        theme: AppTheme.lightTheme(),
        debugShowCheckedModeBanner: false,
        routes: {
          '/': (_) => const SplashScreen(),
          '/login': (_) => const LoginScreen(),
          '/register': (_) => const RegisterScreen(),
          '/dashboard': (_) => const _DashboardPlaceholder(),
          // Driver
          '/driver_dashboard': (_) => const DriverDashboard(),
          '/booking': (_) => const BookingScreen(),
          '/slots': (_) => const SlotListScreen(),
          '/slot_detail': (_) => const SlotDetailScreen(),
          '/navigation': (_) => const NavigationScreen(),
          '/ar_view': (_) => const ARViewScreen(),
          // Owner
          '/owner_dashboard': (_) => const OwnerDashboard(),
          '/manage_space': (_) => const ManageSpaceScreen(),
          '/analytics': (_) => const AnalyticsScreen(),
        },
      ),
    );
  }
}

class _DashboardPlaceholder extends StatelessWidget {
  const _DashboardPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pushReplacementNamed('/login'),
              child: const Text('Logout'),
            ),
            const SizedBox(height: 8),
            const Text('Driver/Owner dashboards will appear here.'),
          ],
        ),
      ),
    );
  }
}
