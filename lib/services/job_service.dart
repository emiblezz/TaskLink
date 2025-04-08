import 'package:flutter/foundation.dart';
import 'package:supabase/supabase.dart';
import 'package:tasklink/config/app_config.dart';
import 'package:tasklink/models/job_model.dart';
import 'package:tasklink/models/application_model.dart';

class JobService extends ChangeNotifier {
  final SupabaseClient _supabaseClient = AppConfig().supabaseClient;

  List<JobModel> _jobs = [];
  List<ApplicationModel> _applications = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<JobModel> get jobs => _jobs;
  List<ApplicationModel> get applications => _applications;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

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