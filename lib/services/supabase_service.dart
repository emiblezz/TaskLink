import 'package:supabase/supabase.dart';
import 'package:tasklink/config/app_config.dart';
import 'package:tasklink/models/user_model.dart';
import 'package:tasklink/models/role_model.dart';
import 'package:tasklink/models/jobseeker_profile_model.dart';

class SupabaseService {
  final SupabaseClient _supabaseClient = AppConfig().supabaseClient;

  // Getter for external access if needed
  SupabaseClient get supabase => _supabaseClient;

  // Get the current authenticated user
  Future<UserModel?> getCurrentUser() async {
    try {
      final authUser = _supabaseClient.auth.currentSession?.user;
      if (authUser == null) return null;

      final response = await _supabaseClient
          .from('users')
          .select()
          .eq('id', authUser.id)
          .single();

      return UserModel.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      print('Error getting current user: $e');
      return null;
    }
  }

  // Get user by ID
  Future<UserModel?> getUserById(String userId) async {
    try {
      final response = await _supabaseClient
          .from('users')
          .select()
          .eq('user_id', userId)
          .single();

      print('User response: $response');
      return UserModel.fromJson(response);
    } catch (e) {
      print('Error getting user by ID: $e');
      return null;
    }
  }

  // Get job seeker profile
  Future<JobSeekerProfileModel?> getJobSeekerProfile(String userId) async {
    try {
      final response = await _supabaseClient
          .from('jobseeker_profiles')
          .select()
          .eq('user_id', userId)
          .single();

      if (response != null) {
        return JobSeekerProfileModel.fromJson(response as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('Error getting job seeker profile: $e');
      return null;
    }
  }

  // Get all roles
  Future<List<RoleModel>> getAllRoles() async {
    try {
      final response = await _supabaseClient
          .from('roles')
          .select()
          .order('id');

      return (response as List)
          .map((role) => RoleModel.fromJson(role))
          .toList();
    } catch (e) {
      print('Error getting roles: $e');
      return [];
    }
  }

  // Create or update a user
  Future<UserModel?> createOrUpdateUser(UserModel user) async {
    try {
      final jsonData = user.toJson();
      print('Upserting user data: $jsonData');

      final response = await _supabaseClient
          .from('users')
          .upsert(jsonData)
          .select()
          .single();

      print('Upsert response: $response');
      return UserModel.fromJson(response);
    } catch (e) {
      print('Error creating/updating user: $e');
      return null;
    }
  }

  // Delete a user
  Future<bool> deleteUser(String userId) async {
    try {
      await _supabaseClient
          .from('users')
          .delete()
          .eq('id', userId);
      return true;
    } catch (e) {
      print('Error deleting user: $e');
      return false;
    }
  }

  // Get job applications with user profiles
  Future<List<Map<String, dynamic>>> getJobApplicationsWithProfiles(int jobId) async {
    try {
      final applications = await _supabaseClient
          .from('applications')
          .select('*, users:applicant_id(*)')
          .eq('job_id', jobId);

      if (applications is List) {
        return applications.map((item) {
          if (item is Map<String, dynamic>) return item;
          return <String, dynamic>{};
        }).toList();
      }
      return [];
    } catch (e) {
      print('Error getting applications with profiles: $e');
      return [];
    }
  }
}
