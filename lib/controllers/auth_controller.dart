import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_client.dart';
import '../models/user_model.dart';

class AuthState extends Equatable {
  final bool isLoading;
  final Session? session;
  final AppUserModel? profile;
  final String? errorMessage;

  const AuthState({
    this.isLoading = false,
    this.session,
    this.profile,
    this.errorMessage,
  });

  AuthState copyWith({
    bool? isLoading,
    Session? session,
    AppUserModel? profile,
    String? errorMessage,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      session: session ?? this.session,
      profile: profile ?? this.profile,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [isLoading, session, profile, errorMessage];
}

class AuthController extends Cubit<AuthState> {
  AuthController() : super(const AuthState());

  SupabaseClient get _client => AppSupabase.client;

  Future<void> signIn(String email, String password) async {
    print('SignIn started for: $email');
    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      print('Attempting Supabase sign in...');
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      print('SignIn successful, session: ${response.session?.user?.id}');
      
      // Load the profile after successful signin
      print('Loading profile after signin...');
      await loadProfile();
      
      print('Emitting success state with session');
      emit(state.copyWith(isLoading: false, session: response.session));
    } on AuthException catch (e) {
      print('Auth exception during signin: ${e.message}');
      emit(state.copyWith(isLoading: false, errorMessage: e.message));
    } catch (e) {
      print('General exception during signin: $e');
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String name,
    required String phone,
    int? age,
    required UserRole role,
    String? licenseUrl,
    String? landProofUrl,
    String? dimensions,
    String? address,
  }) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      final signUpRes = await _client.auth.signUp(
        email: email,
        password: password,
        data: {
          'name': name,
          'phone': phone,
          'age': age,
          'role': role == UserRole.owner ? 'owner' : 'driver',
        },
      );

      final userId = signUpRes.user!.id;
      await _client.from('users').insert({
        'id': userId,
        'name': name,
        'email': email,
        'phone': phone,
        'age': age,
        'role': role == UserRole.owner ? 'owner' : 'driver',
        'license_url': licenseUrl,
        'land_proof_url': landProofUrl,
        'dimensions': dimensions,
        'address': address,
        'is_verified': role == UserRole.driver ? false : null,
      });

      // Load the profile after successful signup
      await loadProfile();

      emit(state.copyWith(isLoading: false, session: signUpRes.session));
    } on AuthException catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.message));
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
    emit(const AuthState());
  }

  Future<void> _createBasicProfile(User user) async {
    // Get user metadata from Auth
    final email = user.email ?? 'unknown@email.com';
    final name = user.userMetadata?['name'] ?? user.userMetadata?['full_name'] ?? 'Unknown User';
    final phone = user.userMetadata?['phone'] ?? '+1234567890';
    final role = user.userMetadata?['role'] ?? 'driver'; // Default to driver
    
    print('Creating basic profile for user: $email with role: $role');
    
    await _client.from('users').insert({
      'id': user.id,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'is_verified': role == 'driver' ? false : null,
    });
    
    print('Basic profile created successfully');
  }

  Future<void> loadProfile() async {
    try {
      final user = _client.auth.currentUser;
      if (user != null) {
        print('Loading profile for user: ${user.id}');
        
        // First check if the users table exists and is accessible
        try {
          final tableCheck = await _client
              .from('users')
              .select('id')
              .limit(1);
          print('Users table accessible: ${tableCheck.length} rows found');
        } catch (e) {
          print('Users table access error: $e');
          throw Exception('Database table access error: $e');
        }
        
        // Add timeout to prevent hanging
        final response = await _client
            .from('users')
            .select()
            .eq('id', user.id)
            .maybeSingle()
            .timeout(const Duration(seconds: 10));
        
        print('Profile data received: $response');
        
        if (response == null) {
          print('No profile found in database, creating one...');
          // User exists in Auth but not in users table - create a basic profile
          await _createBasicProfile(user);
          // Retry loading the profile
          final retryResponse = await _client
              .from('users')
              .select()
              .eq('id', user.id)
              .single();
          final profile = AppUserModel.fromJson(retryResponse as Map<String, dynamic>);
          print('Profile created and loaded successfully: ${profile.role}');
          emit(state.copyWith(profile: profile, errorMessage: null));
          return;
        }
        
        final profile = AppUserModel.fromJson(response as Map<String, dynamic>);
        print('Profile loaded successfully: ${profile.role}');
        
        emit(state.copyWith(profile: profile, errorMessage: null));
      } else {
        print('No current user found');
        emit(state.copyWith(errorMessage: 'No authenticated user found'));
      }
    } catch (e) {
      // Profile loading failed - emit error state
      print('Profile loading error: $e');
      emit(state.copyWith(errorMessage: 'Failed to load user profile: $e'));
      
      // If we have a session but profile loading failed, we might need to create a default profile
      // or handle this case differently
      if (state.session != null) {
        print('Session exists but profile loading failed. User might need to complete registration.');
      }
    }
  }
}


