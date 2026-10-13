import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../data/auth_repository.dart';

const _kTokenKey = 'auth_token';
const _kPhoneKey = 'auth_phone';

final authRepositoryProvider = Provider((ref) => AuthRepository());

final authStateProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(authRepositoryProvider));
});

class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final String? token;
  final String? phone;
  final String? error;

  const AuthState({
    this.isAuthenticated = false,
    this.isLoading = false,
    this.token,
    this.phone,
    this.error,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    String? token,
    String? phone,
    String? error,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      token: token ?? this.token,
      phone: phone ?? this.phone,
      error: error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repo;
  final _storage = const FlutterSecureStorage();

  AuthNotifier(this._repo) : super(const AuthState()) {
    _restore();
  }

  Future<void> _restore() async {
    try {
      final token = await _storage.read(key: _kTokenKey);
      final phone = await _storage.read(key: _kPhoneKey);
      if (token != null && token.isNotEmpty) {
        state = AuthState(
          isAuthenticated: true,
          token: token,
          phone: phone,
        );
      }
    } catch (_) {}
  }

  Future<void> sendCode(String phone) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repo.sendCode(phone);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> login(String phone, String code) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final token = await _repo.login(phone, code);
      await _storage.write(key: _kTokenKey, value: token);
      await _storage.write(key: _kPhoneKey, value: phone);
      state = AuthState(
        isAuthenticated: true,
        token: token,
        phone: phone,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: _kTokenKey);
    await _storage.delete(key: _kPhoneKey);
    state = const AuthState();
  }
}
