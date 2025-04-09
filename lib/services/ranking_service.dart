import 'package:flutter/material.dart';
import 'package:tasklink/models/application_model.dart';
import 'package:tasklink/models/job_model.dart';
import 'package:tasklink/models/jobseeker_profile_model.dart';
import 'package:tasklink/config/app_config.dart';

class RankingService extends ChangeNotifier {
  final _supabase = AppConfig().supabaseClient; // Fixed: using instance access instead of static
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  // Get all applications for a job
  Future<List<ApplicationModel>> getApplicationsForJob(int jobId) async {
    try {
      _isLoading = true;
      notifyListeners();

      final response = await _supabase
          .from('applications')
          .select()
          .eq('job_id', jobId);

      _isLoading = false;
      notifyListeners();

      return (response as List)
          .map((json) => ApplicationModel.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error getting applications: $e');
      _isLoading = false;
      notifyListeners();
      return [];
    }
  }

  // Get ranking for an application
  Future<Map<String, dynamic>?> getRanking(int applicationId) async {
    try {
      final response = await _supabase
          .from('cv_rankings')
          .select()
          .eq('application_id', applicationId)
          .maybeSingle();

      return response;
    } catch (e) {
      debugPrint('Error getting ranking: $e');
      return null;
    }
  }

  // Rank applications for a job
  Future<bool> rankApplications(int jobId) async {
    try {
      _isLoading = true;
      notifyListeners();

      debugPrint('Starting ranking for job $jobId');

      // Get job details
      final jobResponse = await _supabase
          .from('job_postings')
          .select()
          .eq('job_id', jobId)
          .single();

      final job = JobModel.fromJson(jobResponse);
      debugPrint('Got job details for ${job.jobTitle}');

      // Get all applications for this job
      final applications = await getApplicationsForJob(jobId);
      debugPrint('Found ${applications.length} applications for this job');

      for (final application in applications) {
        // Get applicant profile
        final profileResponse = await _supabase
            .from('jobseeker_profiles')
            .select()
            .eq('user_id', application.applicantId)
            .maybeSingle();

        if (profileResponse == null) {
          debugPrint('No profile found for applicant ${application.applicantId}');
          continue;
        }

        final profile = JobSeekerProfileModel.fromJson(profileResponse);
        debugPrint('Processing profile for ${profile.userId}');

        // Calculate match score
        final matchResult = calculateMatchScore(job, profile);
        final score = matchResult['score'];
        debugPrint('Calculated score: $score');

        // Check if ranking already exists
        final existingRanking = await getRanking(application.id!);

        try {
          if (existingRanking != null) {
            // Update existing ranking without matched_skills column
            debugPrint('Updating existing ranking ${existingRanking['ranking_id']}');
            await _supabase
                .from('cv_rankings')
                .update({
              'rank_score': score,
              'recommendation_status': _getRecommendationStatus(score),
            })
                .eq('ranking_id', existingRanking['ranking_id']);
          } else {
            // Create new ranking without matched_skills column
            debugPrint('Creating new ranking for application ${application.id}');
            await _supabase.from('cv_rankings').insert({
              'application_id': application.id,
              'applicant_id': application.applicantId,
              'rank_score': score,
              'recommendation_status': _getRecommendationStatus(score),
            });
          }
        } catch (e) {
          debugPrint('Error updating or inserting ranking: $e');
          // Continue with other applications even if one fails
        }
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error ranking applications: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Calculate match score between job and profile
  Map<String, dynamic> calculateMatchScore(
      JobModel job, JobSeekerProfileModel profile) {
    // Extract skills from job requirements
    final jobSkills = _extractSkills(job.requirements);

    // Get candidate skills
    final candidateSkills = _extractSkills(profile.skills ?? '');

    // Calculate skill match
    final matchedSkills = jobSkills.where((skill) {
      return candidateSkills.any((candidateSkill) =>
      candidateSkill.toLowerCase().contains(skill.toLowerCase()) ||
          skill.toLowerCase().contains(candidateSkill.toLowerCase()));
    }).toList();

    final skillScore = jobSkills.isEmpty
        ? 0.0
        : (matchedSkills.length / jobSkills.length) * 50; // 50% weight to skills

    // Calculate experience match (simple algorithm)
    final experienceScore = _calculateExperienceScore(profile.experience ?? '') * 30; // 30% weight

    // Calculate education match (simple algorithm)
    final educationScore = _calculateEducationScore(profile.education ?? '') * 20; // 20% weight

    // Total score
    final totalScore = skillScore + experienceScore + educationScore;

    // Return detailed result
    return {
      'score': totalScore,
      'skillScore': skillScore,
      'experienceScore': experienceScore,
      'educationScore': educationScore,
      'matchedSkills': matchedSkills,
    };
  }

  // Extract skills from text
  List<String> _extractSkills(String text) {
    // Simple implementation: split by commas and clean up
    final skills = text
        .split(RegExp(r'[,;]'))
        .map((skill) => skill.trim())
        .where((skill) => skill.isNotEmpty)
        .toList();

    return skills;
  }

  // Calculate experience score (0.0 to 1.0)
  double _calculateExperienceScore(String experience) {
    if (experience.isEmpty) return 0.0;

    // Simple scoring based on length and keywords
    final length = experience.length;
    final hasKeywords = RegExp(r'\b(year|years|month|months|experience)\b', caseSensitive: false).hasMatch(experience);

    if (length > 200 && hasKeywords) return 1.0;
    if (length > 100 && hasKeywords) return 0.8;
    if (length > 50) return 0.5;

    return 0.3;
  }

  // Calculate education score (0.0 to 1.0)
  double _calculateEducationScore(String education) {
    if (education.isEmpty) return 0.0;

    // Simple scoring based on keywords
    final hasDegree = RegExp(r'\b(degree|bachelor|master|phd|diploma)\b', caseSensitive: false).hasMatch(education);
    final hasUniversity = RegExp(r'\b(university|college|institute|school)\b', caseSensitive: false).hasMatch(education);

    if (hasDegree && hasUniversity) return 1.0;
    if (hasDegree || hasUniversity) return 0.7;

    return 0.4;
  }

  // Get recommendation status based on score
  String _getRecommendationStatus(double score) {
    if (score >= 80) return 'Highly Recommended';
    if (score >= 60) return 'Recommended';
    if (score >= 40) return 'Consider';
    return 'Not Recommended';
  }

  // Get all rankings for a job
  Future<List<Map<String, dynamic>>> getRankingsForJob(int jobId) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Get all applications for the job
      final applications = await getApplicationsForJob(jobId);

      final rankings = <Map<String, dynamic>>[];

      for (final application in applications) {
        if (application.id == null) continue;

        // Get the ranking for this application
        final ranking = await getRanking(application.id!);

        if (ranking != null) {
          // Get profile information
          final profileResponse = await _supabase
              .from('jobseeker_profiles')
              .select()
              .eq('user_id', application.applicantId)
              .maybeSingle();

          final profile = profileResponse != null
              ? JobSeekerProfileModel.fromJson(profileResponse)
              : null;

          rankings.add({
            ...ranking,
            'application': application,
            'profile': profile,
          });
        }
      }

      // Sort by rank score (descending)
      rankings.sort((a, b) => (b['rank_score'] as num).compareTo(a['rank_score'] as num));

      _isLoading = false;
      notifyListeners();
      return rankings;
    } catch (e) {
      debugPrint('Error getting rankings: $e');
      _isLoading = false;
      notifyListeners();
      return [];
    }
  }
}