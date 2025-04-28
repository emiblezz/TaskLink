import 'package:flutter/material.dart';
import 'package:tasklink/models/job_model.dart';
import 'package:tasklink/services/ranking_service.dart';
//import 'package:tasklink/widgets/application_card.dart';
import 'package:tasklink/config/app_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


import '../../services/ai_services.dart';

class CVRankingScreen extends StatefulWidget {
  final JobModel job;

  const CVRankingScreen({Key? key, required this.job}) : super(key: key);

  @override
  _CVRankingScreenState createState() => _CVRankingScreenState();
}

class _CVRankingScreenState extends State<CVRankingScreen> {
  final RankingService _rankingService = RankingService(
    supabaseClient: Supabase.instance.client,
    aiService: AIService(baseUrl: AppConfig.backendUrl),
  );

  bool _isLoading = false;
  List<Map<String, dynamic>> _rankedApplications = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchRankedApplications();
  }

  Future<void> _fetchRankedApplications() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Check if we have stored ranking results
      final results = await Supabase.instance.client
          .from('ranking_results')
          .select('*')
          .eq('job_id', widget.job.id);

      if (results.isNotEmpty) {
        // We have stored results, fetch the applications
        List<Map<String, dynamic>> rankedApps = [];

        for (var result in results) {
          final appData = await Supabase.instance.client
              .from('applications')
              .select('*, applicant:profiles(*)')
              .eq('id', result['application_id'])
              .single();

          rankedApps.add({
            'application': appData,
            'score': result['score'],
            'matching_skills': result['matching_skills'],
            'missing_skills': result['missing_skills'],
          });
        }

        // Sort by score in descending order
        rankedApps.sort((a, b) => (b['score'] as num).compareTo(a['score'] as num));

        setState(() {
          _rankedApplications = rankedApps;
          _isLoading = false;
        });
      } else {
        // No stored results, perform ranking
        _rankApplications();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error fetching ranking results: $e';
      });
    }
  }

  Future<void> _rankApplications() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final rankedApplications = await _rankingService.rankApplications(
        widget.job.id! as String,
        widget.job.description!,
      );

      setState(() {
        _rankedApplications = rankedApplications;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error ranking applications: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('CV Ranking for ${widget.job.jobTitle}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _rankApplications,
            tooltip: 'Re-rank applications',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Ranking applications...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(_errorMessage!, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _rankApplications,
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    if (_rankedApplications.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_search, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text('No applications to rank for this job.'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _rankedApplications.length,
      itemBuilder: (context, index) {
        final rankedApp = _rankedApplications[index];
        final application = rankedApp['application'];
        final score = rankedApp['score'];
        final matchingSkills = rankedApp['matching_skills'];
        final missingSkills = rankedApp['missing_skills'];

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${application['applicant']['full_name']}',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getScoreColor(score),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Score: ${(score * 100).toStringAsFixed(1)}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (matchingSkills != null && matchingSkills.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Matching Skills:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: List.generate(
                          matchingSkills.length,
                              (i) => Chip(
                            label: Text(matchingSkills[i]),
                            backgroundColor: Colors.green.shade100,
                          ),
                        ),
                      ),
                    ],
                  ),
                if (missingSkills != null && missingSkills.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),
                      const Text(
                        'Missing Skills:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: List.generate(
                          missingSkills.length,
                              (i) => Chip(
                            label: Text(missingSkills[i]),
                            backgroundColor: Colors.red.shade100,
                          ),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        // Navigate to applicant profile
                      },
                      child: const Text('View Profile'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        // Navigate to application details
                      },
                      child: const Text('View Application'),
                    ),
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
    if (score >= 0.8) return Colors.green;
    if (score >= 0.6) return Colors.blue;
    if (score >= 0.4) return Colors.orange;
    return Colors.red;
  }
}