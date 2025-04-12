import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase/supabase.dart';
import 'package:gotrue/gotrue.dart';
import 'package:tasklink/config/app_config.dart';
import 'package:tasklink/models/user_model.dart';
import 'package:tasklink/services/supabase_service.dart';
import 'package:tasklink/utils/constants.dart';
import 'package:gotrue/gotrue.dart';

class AuthService extends ChangeNotifier {
  final SupabaseClient _supabaseClient = AppConfig().supabaseClient;
  final GoTrueClient _authClient = AppConfig().authClient;
  final SupabaseService _supabaseService = SupabaseService();

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  bool _rememberMe = false;
  bool get rememberMe => _rememberMe;

  UserModel? get currentUser => _currentUser;

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  bool get isAuthenticated => _currentUser != null;

  bool get isJobSeeker => _currentUser?.roleId == AppConstants.jobSeekerRoleId;

  bool get isRecruiter => _currentUser?.roleId == AppConstants.recruiterRoleId;

  bool get isAdmin => _currentUser?.roleId == AppConstants.adminRoleId;

  set rememberMe(bool value) {
    _rememberMe = value;
    _saveRememberMePreference(value);
    notifyListeners();
  }
  Future<void> _loadRememberMePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _rememberMe = prefs.getBool(AppConstants.rememberMeKey) ?? false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading remember me preference: $e');
    }
  }
  Future<void> _saveRememberMePreference(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AppConstants.rememberMeKey, value);
    } catch (e) {
      debugPrint('Error saving remember me preference: $e');
    }
  }
  // Initialize and check if user is already logged in
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Load remember me preference
      await _loadRememberMePreference();

      // Check for session expiry if rememberMe was false
      final prefs = await SharedPreferences.getInstance();
      final sessionExpiry = prefs.getInt(AppConstants.sessionExpiryKey);

      if (sessionExpiry != null) {
        final expiryDate = DateTime.fromMillisecondsSinceEpoch(sessionExpiry);
        if (DateTime.now().isAfter(expiryDate)) {
          // Session expired, sign out
          await logout();
          _isLoading = false;
          notifyListeners();
          return;
        }
      }

      // Check if user is already authenticated
      final authUser = _authClient.currentUser;
      if (authUser != null) {
        // Get user data from database
        _currentUser = await _supabaseService.getUserById(authUser.id);
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Register a new user
  Future<bool> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required int roleId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Create the auth user
      final authResponse = await _authClient.signUp(
        email: email,
        password: password,
      );

      if (authResponse.user == null) {
        throw Exception('Failed to create user');
      }

      // Create the user in our database
      final user = UserModel(
        id: authResponse.user!.id,
        name: name,
        email: email,
        phone: phone,
        roleId: roleId,
        profileStatus: 'Active',
        dateJoined: DateTime.now(),
      );

      await _supabaseService.createOrUpdateUser(user);

      // Sign out after registration (they need to verify email first)
      await _authClient.signOut();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Log in a user
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Sign in with email and password
      final authResponse = await _authClient.signInWithPassword(
        email: email,
        password: password,
      );

      if (authResponse.user == null) {
        throw Exception('Failed to log in');
      }

      // Get user data from database
      _currentUser = await _supabaseService.getUserById(authResponse.user!.id);

      if (_currentUser == null) {
        throw Exception('User not found in database');
      }

      // Save session data
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          AppConstants.userDataKey, jsonEncode(_currentUser!.toJson()));
      await prefs.setInt(AppConstants.roleKey, _currentUser!.roleId);

      // If rememberMe is false, set a session expiry
      if (!_rememberMe) {
        // Session will expire after 1 day instead of the default longer time
        // We can't directly control session length, but we can clear it ourselves later
        await prefs.setInt(AppConstants.sessionExpiryKey,
            DateTime.now().add(const Duration(days: 1)).millisecondsSinceEpoch);
      } else {
        // Remove any existing expiry
        await prefs.remove(AppConstants.sessionExpiryKey);
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Log out a user
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authClient.signOut();
      _currentUser = null;

      // Clear saved session data
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConstants.userDataKey);
      await prefs.remove(AppConstants.roleKey);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Reset password
  Future<bool> resetPassword(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authClient.resetPasswordForEmail(email);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Update user profile
  Future<bool> updateUserProfile({
    required String name,
    required String phone,
  }) async {
    if (_currentUser == null) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Update user in database
      final updatedUser = _currentUser!.copyWith(
        name: name,
        phone: phone,
      );

      final result = await _supabaseService.createOrUpdateUser(updatedUser);

      if (result != null) {
        _currentUser = result;

        // Update saved session data
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
            AppConstants.userDataKey, jsonEncode(_currentUser!.toJson()));

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        throw Exception('Failed to update profile');
      }
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  Future<bool> completePasswordReset({required String newPassword}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // If the user is following a password reset link, they'll already have an active session
      // Update their password using the UpdateUserAttributes method
      await _authClient.updateUser(
        UserAttributes(
          password: newPassword,
        ),
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
  String _getReadableErrorMessage(String error) {
    if (error.contains('email not found')) {
      return 'This email is not registered in our system.';
    } else if (error.contains('invalid email')) {
      return 'Please enter a valid email address.';
    } else if (error.contains('too many requests')) {
      return 'Too many attempts. Please try again later.';
    } else if (error.contains('closed')) {
      return 'Connection error. Please check your internet.';
    }
    return 'An error occurred. Please try again.';
  }
}