import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:tasklink/models/job_model.dart';
import 'package:tasklink/services/auth_service.dart';
import 'package:tasklink/services/job_service.dart';
import 'package:tasklink/screens/recruiter/create_job_screen.dart';

class JobDetailScreen extends StatefulWidget {
  final JobModel job;
  final bool isRecruiter;

  const JobDetailScreen({
    super.key,
    required this.job,
    this.isRecruiter = false,
  });

  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> {
  bool _isApplying = false;

  Future<void> _applyForJob() async {
    setState(() {
      _isApplying = true;
    });

    try {
      final jobService = Provider.of<JobService>(context, listen: false);
      final authService = Provider.of<AuthService>(context, listen: false);

      if (authService.currentUser == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You must be logged in to apply for jobs'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final result = await jobService.applyForJob(
        widget.job.id!,
        authService.currentUser!.id,
      );

      if (mounted) {
        if (result != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Application submitted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(jobService.errorMessage ?? 'Failed to apply for job'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isApplying = false;
        });
      }
    }
  }

  Future<void> _editJob() async {
    if (!widget.isRecruiter) return;

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => CreateJobScreen(job: widget.job),
      ),
    );

    if (result == true && mounted) {
      // Refresh job details
      JobService jobService = Provider.of<JobService>(context, listen: false);
      await jobService.fetchRecruiterJobs(widget.job.recruiterId);
    }
  }

  Future<void> _closeJob() async {
    if (!widget.isRecruiter) return;

    // Show confirmation dialog
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Close Job'),
        content: const Text(
          'Are you sure you want to close this job? '
              'It will no longer be visible to job seekers.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Close Job'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final jobService = Provider.of<JobService>(context, listen: false);
      final success = await jobService.closeJob(widget.job.id!);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Job closed successfully'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true); // Return true to indicate job was closed
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(jobService.errorMessage ?? 'Failed to close job'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Job Details'),
        actions: widget.isRecruiter
            ? [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _editJob,
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: _closeJob,
          ),
        ]
            : null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Job title and type
            Text(
              widget.job.jobTitle,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Chip(
                  label: Text(widget.job.jobType),
                  backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  labelStyle: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Chip(
                  label: Text(widget.job.status),
                  backgroundColor: widget.job.status == 'Open'
                      ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  labelStyle: TextStyle(
                    color: widget.job.status == 'Open' ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Deadline
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Application Deadline: ${DateFormat('MMM dd, yyyy').format(widget.job.deadline)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Posted date
            if (widget.job.datePosted != null)
              Row(
                children: [
                  const Icon(Icons.access_time, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Posted: ${DateFormat('MMM dd, yyyy').format(widget.job.datePosted!)}',
                  ),
                ],
              ),
            const SizedBox(height: 24),

            // Description section
            const Text(
              'Job Description',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(widget.job.description),
            const SizedBox(height: 24),

            // Requirements section
            const Text(
              'Requirements',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(widget.job.requirements),
            const SizedBox(height: 32),

            // Apply button (only for job seekers and if job is open)
            if (!widget.isRecruiter && widget.job.status == 'Open')
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isApplying ? null : _applyForJob,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isApplying
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Text(
                    'Apply Now',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}