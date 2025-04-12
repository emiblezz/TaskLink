import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tasklink/models/jobseeker_profile_model.dart';
import 'package:tasklink/screens/auth/login_screen.dart';
import 'package:tasklink/services/auth_service.dart';
import 'package:tasklink/services/profile_service.dart';
import 'package:tasklink/utils/validators.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _skillsController = TextEditingController();
  final _experienceController = TextEditingController();
  final _educationController = TextEditingController();
  final _linkedinController = TextEditingController();
  final _scrollController = ScrollController();
  String? _cvUrl;
  String? _cvFileName;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _skillsController.dispose();
    _experienceController.dispose();
    _educationController.dispose();
    _linkedinController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final profileService = Provider.of<ProfileService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);

    if (authService.currentUser != null) {
      await profileService.fetchProfile(authService.currentUser!.id);

      if (profileService.profile != null) {
        setState(() {
          _skillsController.text = profileService.profile!.skills ?? '';
          _experienceController.text = profileService.profile!.experience ?? '';
          _educationController.text = profileService.profile!.education ?? '';
          _linkedinController.text = profileService.profile!.linkedinProfile ?? '';
          _cvUrl = profileService.profile!.cv;

          // Extract file name from URL
          if (_cvUrl != null && _cvUrl!.isNotEmpty) {
            final parts = _cvUrl!.split('/');
            _cvFileName = parts.last;
          }
        });
      }
    }
  }

  Future<void> _uploadCV() async {
    setState(() {
      _isUploading = true;
    });

    try {
      final profileService = Provider.of<ProfileService>(context, listen: false);
      final authService = Provider.of<AuthService>(context, listen: false);

      if (authService.currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You must be logged in to upload a CV'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final userId = authService.currentUser!.id;
      // Use simulated upload instead of actual file picking
      final newCvUrl = await profileService.simulateUploadCV(userId);

      if (newCvUrl != null) {
        setState(() {
          _cvUrl = newCvUrl;
          _cvFileName = "simulated-cv.pdf"; // Simulated filename
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('CV uploaded successfully (simulated)'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (profileService.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(profileService.errorMessage!),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState?.validate() ?? false) {
      final profileService = Provider.of<ProfileService>(context, listen: false);
      final authService = Provider.of<AuthService>(context, listen: false);

      if (authService.currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You must be logged in to save your profile'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final userId = authService.currentUser!.id;

      final profile = JobSeekerProfileModel(
        userId: userId,
        cv: _cvUrl,
        skills: _skillsController.text,
        experience: _experienceController.text,
        education: _educationController.text,
        linkedinProfile: _linkedinController.text,
      );

      final result = await profileService.saveProfile(profile);

      if (mounted) {
        if (result != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile saved successfully'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(profileService.errorMessage ?? 'Failed to save profile'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _logout() async {
    final authService = Provider.of<AuthService>(context, listen: false);

    // Show confirmation dialog
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      // Perform logout
      await authService.logout();

      if (!mounted) return;

      // Navigate to login screen and clear the navigation stack
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileService = Provider.of<ProfileService>(context);
    final mediaQuery = MediaQuery.of(context);
    final bottomPadding = mediaQuery.viewInsets.bottom + 100; // Add extra padding for keyboard

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(), // Dismiss keyboard when tapping outside
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Edit Profile'),
          actions: [
            // Logout button in app bar
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Logout',
              onPressed: _logout,
            ),
          ],
        ),
        body: profileService.isLoading
            ? const Center(child: CircularProgressIndicator())
            : LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              // Add extra padding at the bottom for keyboard
              padding: EdgeInsets.only(
                  left: 16.0,
                  right: 16.0,
                  top: 16.0,
                  bottom: bottomPadding
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // CV Upload
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Resume/CV',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),

                              if (_cvFileName != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                    horizontal: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.description),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _cvFileName!,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                              const SizedBox(height: 16),

                              ElevatedButton.icon(
                                onPressed: _isUploading ? null : _uploadCV,
                                icon: const Icon(Icons.upload_file),
                                label: _isUploading
                                    ? const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      height: 16,
                                      width: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Text('Uploading...'),
                                  ],
                                )
                                    : Text(_cvFileName == null
                                    ? 'Simulate CV Upload'
                                    : 'Update CV (Simulated)'),
                              ),
                              if (_cvFileName != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    'CV File: $_cvFileName',
                                    style: TextStyle(
                                      color: Colors.grey[700],
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              const Padding(
                                padding: EdgeInsets.only(top: 8.0),
                                child: Text(
                                  'Note: This is a simulated CV upload for Phase 2.',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Skills
                      TextFormField(
                        controller: _skillsController,
                        decoration: const InputDecoration(
                          labelText: 'Skills',
                          hintText: 'Enter your skills (e.g., JavaScript, Project Management)',
                          prefixIcon: Icon(Icons.assessment_outlined),
                        ),
                        validator: (value) => Validators.validateRequired(
                          value,
                          'Skills',
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Experience
                      TextFormField(
                        controller: _experienceController,
                        decoration: const InputDecoration(
                          labelText: 'Work Experience',
                          hintText: 'Describe your work experience',
                          alignLabelWithHint: true,
                          prefixIcon: Icon(Icons.work_outline),
                        ),
                        maxLines: 3,
                        validator: (value) => Validators.validateRequired(
                          value,
                          'Work experience',
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Education
                      TextFormField(
                        controller: _educationController,
                        decoration: const InputDecoration(
                          labelText: 'Education',
                          hintText: 'Enter your educational background',
                          alignLabelWithHint: true,
                          prefixIcon: Icon(Icons.school_outlined),
                        ),
                        maxLines: 3,
                        validator: (value) => Validators.validateRequired(
                          value,
                          'Education',
                        ),
                      ),
                      const SizedBox(height: 16),

                      // LinkedIn
                      TextFormField(
                        controller: _linkedinController,
                        decoration: const InputDecoration(
                          labelText: 'LinkedIn Profile',
                          hintText: 'Enter your LinkedIn profile URL',
                          prefixIcon: Icon(Icons.link),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Save Button
                      ElevatedButton(
                        onPressed: profileService.isLoading ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: profileService.isLoading
                            ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                            : const Text(
                          'Save Profile',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Logout Button
                      OutlinedButton.icon(
                        onPressed: _logout,
                        icon: const Icon(Icons.logout),
                        label: const Text('Logout'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          foregroundColor: Colors.red,
                        ),
                      ),

                      const SizedBox(height: 100), // Extra large bottom padding
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}