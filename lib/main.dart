import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'config/supabase_client.dart';
import 'config/theme.dart';
import 'controllers/auth_controller.dart';
import 'controllers/booking_controller.dart';
import 'controllers/slot_controller.dart';
import 'models/user_model.dart';
import 'views/auth/login_screen.dart';
import 'views/auth/register_screen.dart';
import 'views/driver/booking_screen.dart';
import 'views/driver/slot_list_screen.dart';
import 'views/driver/slot_detail_screen.dart';
import 'views/driver/navigation_screen.dart';
import 'views/driver/ar_view_screen.dart';
import 'views/driver/driver_dashboard.dart';
import 'views/owner/owner_dashboard.dart';
import 'views/owner/manage_space_screen.dart';
import 'views/owner/add_space_screen.dart';
import 'views/owner/analytics_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppSupabase.initialize(
    url: 'https://snuvppospaekzqsrtqfe.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNudXZwcG9zcGFla3pxc3J0cWZlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTY0Nzk1NzMsImV4cCI6MjA3MjA1NTU3M30.r0Dz5hQfpjVVfRWv2V_VoTy6PF6HYBiqkhenK23wRVU',
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
        theme: AppTheme.darkTheme(),
        darkTheme: AppTheme.darkTheme(),
        themeMode: ThemeMode.dark,
        debugShowCheckedModeBanner: false,
        home: const AuthWrapper(),
        routes: {
          '/login': (_) => const LoginScreen(),
          '/register': (_) => const RegisterScreen(),
          // Driver
          '/driver_dashboard': (_) => const DriverDashboard(),
          '/booking': (_) => const BookingScreen(),
          '/slot_list': (_) => const SlotListScreen(),
          '/slot_detail': (_) => const SlotDetailScreen(),
          '/navigation': (_) => const NavigationScreen(),
          '/ar_view': (_) => const ARViewScreen(),
          // Owner
          '/owner_dashboard': (_) => const OwnerDashboard(),
          '/manage_space': (_) {
            print('Route /manage_space accessed');
            return const ManageSpaceScreen();
          },
          '/add_space': (_) => const AddSpaceScreen(),
          '/analytics': (_) => const AnalyticsScreen(),
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthController, AuthState>(
      builder: (context, state) {
        // Show loading while checking auth state
        if (state.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // If user is authenticated, show appropriate dashboard
        if (state.session != null) {
          // Check user role from profile if available
          if (state.profile != null) {
            if (state.profile!.role == UserRole.driver) {
              return const DriverDashboard();
            } else {
              return const OwnerDashboard();
            }
          }

          // If there's an error loading profile, show error and logout option
          if (state.errorMessage != null) {
            return Scaffold(
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Profile Loading Failed',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Your account exists but your profile data could not be loaded.',
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error: ${state.errorMessage}',
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              context.read<AuthController>().loadProfile();
                            },
                            child: const Text('Retry'),
                          ),
                          OutlinedButton(
                            onPressed: () {
                              context.read<AuthController>().signOut();
                            },
                            child: const Text('Sign Out'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          // If profile is not loaded yet and no error, try to load it
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.read<AuthController>().loadProfile();
          });

          // Show loading while profile is being loaded
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading your profile...'),
                ],
              ),
            ),
          );
        }

        // If not authenticated, show login screen
        return const LoginScreen();
      },
    );
  }
}
