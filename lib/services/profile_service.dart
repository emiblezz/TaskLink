import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:supabase/supabase.dart';
import 'package:tasklink/config/app_config.dart';
import 'package:tasklink/models/jobseeker_profile_model.dart';


class ProfileService extends ChangeNotifier {
  final SupabaseClient _supabaseClient = AppConfig().supabaseClient;

  JobSeekerProfileModel? _profile;
  bool _isLoading = false;
  String? _errorMessage;

  JobSeekerProfileModel? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasProfile => _profile != null;

  // Get jobseeker profile
  Future<void> fetchProfile(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _supabaseClient
          .from('jobseeker_profiles')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response != null) {
        _profile = JobSeekerProfileModel.fromJson(response as Map<String, dynamic>);
      } else {
        _profile = null;
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create or update profile
  Future<JobSeekerProfileModel?> saveProfile(JobSeekerProfileModel profile) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final exists = await _checkProfileExists(profile.userId);

      final response = exists
          ? await _supabaseClient
          .from('jobseeker_profiles')
          .update(profile.toJson())
          .eq('user_id', profile.userId)
          .select()
          .single()
          : await _supabaseClient
          .from('jobseeker_profiles')
          .insert(profile.toJson())
          .select()
          .single();

      _profile = JobSeekerProfileModel.fromJson(response as Map<String, dynamic>);
      _isLoading = false;
      notifyListeners();
      return _profile;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // Check if profile exists
  Future<bool> _checkProfileExists(String userId) async {
    try {
      final response = await _supabaseClient
          .from('jobseeker_profiles')
          .select('profile_id')
          .eq('user_id', userId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      return false;
    }
  }

  // For Phase 2, we'll use a simulated CV upload that doesn't require a file picker
  // This is a temporary solution to avoid package compatibility issues
  Future<String?> simulateUploadCV(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Create a simulated CV URL (in a real app, this would be a URL to a file)
      final simulatedUrl = "https://example.com/cvs/$userId/simulated-cv.pdf";

      // If we have a profile, update it with the simulated CV URL
      if (_profile != null) {
        final updatedProfile = _profile!.copyWith(
          cv: simulatedUrl,
        );

        await saveProfile(updatedProfile);
      }

      _isLoading = false;
      notifyListeners();
      return simulatedUrl;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
