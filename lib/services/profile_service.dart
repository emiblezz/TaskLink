import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:supabase/supabase.dart';
import 'package:tasklink/config/app_config.dart';
import 'package:tasklink/models/jobseeker_profile_model.dart';
import 'package:tasklink/services/file_service.dart';

class ProfileService extends ChangeNotifier {
  late final SupabaseClient _supabase;
  JobSeekerProfileModel? _profile;
  bool _isLoading = false;
  String? _errorMessage;

  ProfileService() {
    // Get Supabase client from the AppConfig instance
    _supabase = AppConfig().supabaseClient;
  }

  JobSeekerProfileModel? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Fetch profile data
  Future<JobSeekerProfileModel?> fetchProfile(String userId) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      // First check if user exists in users table
      final userResponse = await _supabase
          .from('users')
          .select()
          .eq('user_id', userId)
          .single();

      if (userResponse == null) {
        _errorMessage = 'User profile not found';
        _setLoading(false);
        return null;
      }

      // Then check if jobseeker profile exists
      final response = await _supabase
          .from('jobseeker_profiles')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response != null) {
        _profile = JobSeekerProfileModel.fromJson(response);
        _setLoading(false);
        return _profile;
      } else {
        // Profile doesn't exist yet, return an empty profile
        _profile = JobSeekerProfileModel(
          userId: userId,
          cv: null,
          skills: '',
          experience: '',
          education: '',
          linkedinProfile: '',
        );
        _setLoading(false);
        return _profile;
      }
    } catch (e) {
      _errorMessage = 'Error fetching profile: ${e.toString()}';
      _setLoading(false);
      return null;
    }
  }

  // Save or update profile
  Future<JobSeekerProfileModel?> saveProfile(JobSeekerProfileModel profile) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      // Check if profile exists
      final existingProfile = await _supabase
          .from('jobseeker_profiles')
          .select()
          .eq('user_id', profile.userId)
          .maybeSingle();

      if (existingProfile != null) {
        // Update existing profile
        final response = await _supabase
            .from('jobseeker_profiles')
            .update(profile.toJson())
            .eq('user_id', profile.userId)
            .select()
            .single();

        _profile = JobSeekerProfileModel.fromJson(response);
      } else {
        // Create new profile
        final response = await _supabase
            .from('jobseeker_profiles')
            .insert(profile.toJson())
            .select()
            .single();

        _profile = JobSeekerProfileModel.fromJson(response);
      }

      _setLoading(false);
      return _profile;
    } catch (e) {
      _errorMessage = 'Error saving profile: ${e.toString()}';
      _setLoading(false);
      return null;
    }
  }

  // Method to pick and upload CV using real file picker
  Future<String?> pickAndUploadCV(String userId) async {
    _errorMessage = null;

    try {
      // Use the real file picker
      final pickedFile = await FileService.pickCV();

      if (pickedFile == null) {
        return null; // User cancelled the picker
      }

      final fileName = pickedFile['name'] as String;
      final fileBytes = pickedFile['bytes'] as Uint8List;
      final isReal = pickedFile['isReal'] as bool? ?? false;

      // Upload to Supabase Storage
      final String filePath = 'cvs/$userId/$fileName';

      final uploadResponse = await _supabase
          .storage
          .from('cvs')
          .uploadBinary(
        filePath,
        fileBytes,
        fileOptions: FileOptions(
          contentType: _getContentType(fileName),
        ),
      );

      if (uploadResponse.isNotEmpty) {
        // Get the public URL
        final String publicUrl = _supabase
            .storage
            .from('cvs')
            .getPublicUrl(filePath);

        // Mark the URL if it's simulated
        if (!isReal) {
          return '$publicUrl#fallback';
        }

        return publicUrl;
      } else {
        _errorMessage = 'Failed to upload CV';
        return null;
      }
    } catch (e) {
      _errorMessage = 'Error uploading CV: ${e.toString()}';
      return null;
    }
  }

  // Helper method to determine content type from file name
  String _getContentType(String fileName) {
    if (fileName.toLowerCase().endsWith('.pdf')) {
      return 'application/pdf';
    } else if (fileName.toLowerCase().endsWith('.doc')) {
      return 'application/msword';
    } else if (fileName.toLowerCase().endsWith('.docx')) {
      return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
    }
    // Default
    return 'application/octet-stream';
  }

  // Helper to set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}