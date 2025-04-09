import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tasklink/models/application_model.dart';
import 'package:tasklink/models/job_model.dart';
import 'package:tasklink/models/jobseeker_profile_model.dart';
import 'package:tasklink/services/job_service.dart';
import 'package:tasklink/services/ranking_service.dart';
import 'package:tasklink/utils/theme.dart';

class CVRankingScreen extends StatefulWidget {
  final JobModel job;

  const CVRankingScreen({
    Key? key,
    required this.job,
  }) : super(key: key);

  @override
  State<CVRankingScreen> createState() => _CVRankingScreenState();
}

class _CVRankingScreenState extends State<CVRankingScreen> {
  bool _isLoading = false;
  bool _isRanking = false;
  List<Map<String, dynamic>> _rankings = [];
  String? _errorMessage;
  // Map to cache applicant names by ID
  Map<String, String> _applicantNames = {};

  @override
  void initState() {
    super.initState();
    _loadRankings();
  }

  Future<void> _loadRankings() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final rankingService = Provider.of<RankingService>(context, listen: false);
      final rankings = await rankingService.getRankingsForJob(widget.job.id!);

      // Load applicant names
      await _loadApplicantNames(rankings);

      setState(() {
        _rankings = rankings;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading rankings: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadApplicantNames(List<Map<String, dynamic>> rankings) async {
    try {
      // Extract unique applicant IDs
      final applicantIds = rankings
          .map((ranking) => ranking['application'] as ApplicationModel)
          .map((app) => app.applicantId)
          .toSet()
          .toList();

      // Get applicant names from your user service if needed
      // For now, we'll use a simple map with placeholder names
      final Map<String, String> names = {};
      for (final id in applicantIds) {
        // You might want to replace this with actual name fetching logic
        names[id] = "Applicant ${id.substring(0, 5)}...";
      }

      setState(() {
        _applicantNames = names;
      });
    } catch (e) {
      debugPrint('Error loading applicant names: $e');
    }
  }

  Future<void> _runRanking() async {
    setState(() {
      _isRanking = true;
      _errorMessage = null;
    });

    try {
      final rankingService = Provider.of<RankingService>(context, listen: false);
      final success = await rankingService.rankApplications(widget.job.id!);

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('CV ranking completed successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
        await _loadRankings();
      } else {
        setState(() {
          _errorMessage = 'Failed to rank applications';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error during ranking: $e';
      });
    } finally {
      setState(() {
        _isRanking = false;
      });
    }
  }

  Future<void> _updateApplicationStatus(int applicationId, String status) async {
    try {
      final jobService = Provider.of<JobService>(context, listen: false);
      await jobService.updateApplicationStatus(applicationId, status);

      // Refresh rankings after status update
      await _loadRankings();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Application marked as $status'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('AI Rankings: ${widget.job.jobTitle}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRankings,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildJobInfo(),
          _buildActionsBar(),
          if (_errorMessage != null) _buildErrorMessage(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _rankings.isEmpty
                ? _buildEmptyState()
                : _buildRankingsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildJobInfo() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.job.jobTitle,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Type: ${widget.job.jobType}',
              style: const TextStyle(
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Application count: ${_rankings.length}',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _isRanking ? null : _runRanking,
              icon: _isRanking
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
                  : const Icon(Icons.auto_awesome),
              label: Text(_isRanking ? 'Ranking...' : 'Rank Applicants'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red[300]!),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error,
            color: Colors.red,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_search,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          const Text(
            'No ranked applications yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Click "Rank Applicants" to analyze applications using AI ranking',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRankingsList() {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: _rankings.length,
      itemBuilder: (context, index) {
        final ranking = _rankings[index];
        final application = ranking['application'] as ApplicationModel;
        final profile = ranking['profile'] as JobSeekerProfileModel?;
        final score = (ranking['rank_score'] as num).toDouble();
        final status = ranking['recommendation_status'] as String;

        // Get applicant name from cache or use a placeholder
        final applicantName = _applicantNames[application.applicantId] ?? 'Unnamed Applicant';

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: _getBorderColor(score),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        applicantName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getScoreColor(score).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _getScoreColor(score),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getScoreIcon(score),
                            size: 16,
                            color: _getScoreColor(score),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${score.toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _getScoreColor(score),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Status: ${application.applicationStatus}',
                  style: TextStyle(
                    color: _getApplicationStatusColor(application.applicationStatus),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'AI Recommendation: $status',
                  style: TextStyle(
                    color: _getScoreColor(score),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                if (profile != null) ...[
                  const Text(
                    'Candidate Profile:',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (profile.skills?.isNotEmpty ?? false)
                    Text('Skills: ${profile.skills}'),
                  if (profile.education?.isNotEmpty ?? false)
                    Text('Education: ${profile.education}'),
                  if (profile.experience?.isNotEmpty ?? false)
                    Text(
                      'Experience: ${profile.experience}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (application.applicationStatus == 'Pending') ...[
                      OutlinedButton.icon(
                        onPressed: () => _updateApplicationStatus(
                            application.id!, 'Rejected'),
                        icon: const Icon(Icons.close, color: Colors.red),
                        label: const Text('Reject'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () => _updateApplicationStatus(
                            application.id!, 'Approved'),
                        icon: const Icon(Icons.check),
                        label: const Text('Approve'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ] else if (application.applicationStatus == 'Approved') ...[
                      OutlinedButton.icon(
                        onPressed: () => _updateApplicationStatus(
                            application.id!, 'Hired'),
                        icon: const Icon(Icons.person_add),
                        label: const Text('Hire'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.purple,
                        ),
                      ),
                    ]
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.blue;
    if (score >= 40) return Colors.orange;
    return Colors.red;
  }

  IconData _getScoreIcon(double score) {
    if (score >= 80) return Icons.verified;
    if (score >= 60) return Icons.thumb_up;
    if (score >= 40) return Icons.thumbs_up_down;
    return Icons.thumb_down;
  }

  Color _getBorderColor(double score) {
    if (score >= 80) return Colors.green.withOpacity(0.3);
    if (score >= 60) return Colors.blue.withOpacity(0.3);
    if (score >= 40) return Colors.orange.withOpacity(0.3);
    return Colors.red.withOpacity(0.3);
  }

  Color _getApplicationStatusColor(String status) {
    switch (status) {
      case 'Approved':
        return Colors.green;
      case 'Rejected':
        return Colors.red;
      case 'Hired':
        return Colors.purple;
      default:
        return Colors.grey[700]!;
    }
  }
}