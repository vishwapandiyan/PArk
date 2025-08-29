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
    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      emit(state.copyWith(isLoading: false, session: response.session));
    } on AuthException catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.message));
    } catch (e) {
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
}


