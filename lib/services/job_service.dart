import 'package:flutter/foundation.dart';
import 'package:supabase/supabase.dart';
import 'package:tasklink/config/app_config.dart';
import 'package:tasklink/models/job_model.dart';
import 'package:tasklink/models/application_model.dart';
import 'package:tasklink/services/auth_service.dart';
import 'package:tasklink/services/notification_service.dart';

class JobService extends ChangeNotifier {
  final SupabaseClient _supabaseClient = AppConfig().supabaseClient;
  AuthService? _authService;
  NotificationService? _notificationService;

  List<JobModel> _jobs = [];
  List<ApplicationModel> _applications = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<JobModel> get jobs => _jobs;
  List<ApplicationModel> get applications => _applications;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Allow setting services from outside
  void setAuthService(AuthService authService) {
    _authService = authService;
  }

  void setNotificationService(NotificationService notificationService) {
    _notificationService = notificationService;
  }

  // Get all jobs
  Future<void> fetchJobs() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _supabaseClient
          .from('job_postings')
          .select()
          .eq('status', 'Open')
          .order('date_posted', ascending: false);

      _jobs = (response as List).map((job) => JobModel.fromJson(job)).toList();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get recruiter's jobs
  Future<void> fetchRecruiterJobs(String recruiterId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _supabaseClient
          .from('job_postings')
          .select()
          .eq('recruiter_id', recruiterId)
          .order('date_posted', ascending: false);

      _jobs = (response as List).map((job) => JobModel.fromJson(job)).toList();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get job by ID
  Future<JobModel?> getJobById(int jobId) async {
    try {
      final response = await _supabaseClient
          .from('job_postings')
          .select()
          .eq('job_id', jobId)
          .single();

      return JobModel.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      _errorMessage = e.toString();
      return null;
    }
  }

  // Create a new job
  Future<JobModel?> createJob(JobModel job) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _supabaseClient
          .from('job_postings')
          .insert(job.toJson())
          .select()
          .single();

      final newJob = JobModel.fromJson(response as Map<String, dynamic>);
      _jobs.add(newJob);

      // Send notifications if the service is available
      if (_notificationService != null && _authService != null && _authService!.currentUser != null) {
        // This is a simplified version - you'd need to get job seeker IDs
        // For now, we're just demonstrating the concept
        try {
          // Get job seekers - this is simplified and would need to be replaced
          // with your actual implementation to fetch job seekers
          List<String> jobSeekerIds = await _getJobSeekerIds();

          await _notificationService!.notifyNewJob(
            jobSeekerIds: jobSeekerIds,
            jobTitle: newJob.jobTitle,
            companyName: _authService!.currentUser!.name,
          );
        } catch (notificationError) {
          print('Error sending job notifications: $notificationError');
          // Continue execution even if notifications fail
        }
      }

      _isLoading = false;
      notifyListeners();
      return newJob;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // Helper method to get job seeker IDs
  // This is a placeholder - implement your actual logic
  Future<List<String>> _getJobSeekerIds() async {
    try {
      // Example implementation - replace with your actual query
      final response = await _supabaseClient
          .from('users')
          .select('user_id')
          .eq('role_id', 1) // Assuming 1 is the job seeker role ID
          .limit(20); // Limit to avoid notifying too many users

      return (response as List).map((user) => user['user_id'] as String).toList();
    } catch (e) {
      print('Error fetching job seeker IDs: $e');
      return [];
    }
  }

  // Update job
  Future<JobModel?> updateJob(JobModel job) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _supabaseClient
          .from('job_postings')
          .update(job.toJson())
          .eq('job_id', job.id)
          .select()
          .single();

      final updatedJob = JobModel.fromJson(response as Map<String, dynamic>);

      // Update the job in the list
      final index = _jobs.indexWhere((j) => j.id == job.id);
      if (index != -1) {
        _jobs[index] = updatedJob;
      }

      _isLoading = false;
      notifyListeners();
      return updatedJob;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // Close a job
  Future<bool> closeJob(int jobId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _supabaseClient
          .from('job_postings')
          .update({'status': 'Closed'})
          .eq('job_id', jobId);

      // Update the job in the list
      final index = _jobs.indexWhere((j) => j.id == jobId);
      if (index != -1) {
        _jobs[index] = _jobs[index].copyWith(status: 'Closed');
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

  // Apply for a job
  Future<ApplicationModel?> applyForJob(int jobId, String applicantId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final application = ApplicationModel(
        jobId: jobId,
        applicantId: applicantId,
        dateApplied: DateTime.now(),
      );

      final response = await _supabaseClient
          .from('applications')
          .insert(application.toJson())
          .select()
          .single();

      final newApplication = ApplicationModel.fromJson(response as Map<String, dynamic>);
      _applications.add(newApplication);

      // Send notification if services are available
      if (_notificationService != null && _authService != null && _authService!.currentUser != null) {
        try {
          final job = await getJobById(jobId);
          if (job != null) {
            await _notificationService!.notifyJobApplication(
              recruiterId: job.recruiterId,
              jobTitle: job.jobTitle,
              applicantName: _authService!.currentUser!.name,
            );
          }
        } catch (notificationError) {
          print('Error sending application notification: $notificationError');
          // Continue execution even if notification fails
        }
      }

      _isLoading = false;
      notifyListeners();
      return newApplication;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // Get user applications
  Future<void> fetchUserApplications(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _supabaseClient
          .from('applications')
          .select()
          .eq('applicant_id', userId)
          .order('date_applied', ascending: false);

      _applications = (response as List).map((app) => ApplicationModel.fromJson(app)).toList();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get applications for a job
  Future<List<ApplicationModel>> getJobApplications(int jobId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _supabaseClient
          .from('applications')
          .select()
          .eq('job_id', jobId)
          .order('date_applied', ascending: false);

      final applications = (response as List).map((app) => ApplicationModel.fromJson(app)).toList();
      _isLoading = false;
      notifyListeners();
      return applications;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return [];
    }
  }

  // Get application by ID
  Future<ApplicationModel?> getApplicationById(int applicationId) async {
    try {
      final response = await _supabaseClient
          .from('applications')
          .select()
          .eq('application_id', applicationId)
          .single();

      return ApplicationModel.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      _errorMessage = e.toString();
      return null;
    }
  }

  // Update application status
  Future<bool> updateApplicationStatus(int applicationId, String status) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _supabaseClient
          .from('applications')
          .update({'application_status': status})
          .eq('application_id', applicationId);

      // Update the application in the list
      final index = _applications.indexWhere((a) => a.id == applicationId);
      if (index != -1) {
        _applications[index] = _applications[index].copyWith(applicationStatus: status);
      }

      // Send notification if services are available
      if (_notificationService != null) {
        try {
          final application = await getApplicationById(applicationId);
          if (application != null) {
            final job = await getJobById(application.jobId);
            if (job != null) {
              await _notificationService!.notifyStatusChange(
                applicantId: application.applicantId,
                jobTitle: job.jobTitle,
                status: status,
              );
            }
          }
        } catch (notificationError) {
          print('Error sending status update notification: $notificationError');
          // Continue execution even if notification fails
        }
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

  // Search jobs
  Future<List<JobModel>> searchJobs(String query) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _supabaseClient
          .from('job_postings')
          .select()
          .eq('status', 'Open')
          .or('job_title.ilike.%$query%,description.ilike.%$query%,requirements.ilike.%$query%')
          .order('date_posted', ascending: false);

      final searchResults = (response as List).map((job) => JobModel.fromJson(job)).toList();
      _isLoading = false;
      notifyListeners();
      return searchResults;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return [];
    }
  }

  // Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}