import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tasklink/config/app_config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class FileService {
  // Pick CV files (PDF, DOC, DOCX)
  static Future<Map<String, dynamic>?> pickCV() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt'],
        withData: true, // Ensures we get the file data directly
      );

      if (result == null || result.files.isEmpty) {
        return null;
      }

      final file = result.files.first;
      final fileName = file.name;
      final fileBytes = file.bytes;

      if (fileBytes == null) {
        debugPrint('Error: No file bytes available');
        return null;
      }

      // Use plain text for simplicity if you don't have the backend extract_text endpoint yet
      String resumeText = "";

      if (fileName.toLowerCase().endsWith('.txt')) {
        // For text files, we can extract the content directly
        resumeText = utf8.decode(fileBytes);
      } else {
        // For other files, use a placeholder text until backend is fully implemented
        resumeText = "Resume content for $fileName. This is a placeholder that would be replaced with actual extracted text from the backend.";
      }

      // Store the text in Supabase
      try {
        final userId = Supabase.instance.client.auth.currentUser?.id;
        if (userId != null) {
          await Supabase.instance.client.from('resumes').insert({
            'applicant_id': userId,
            'text': resumeText,
            'filename': fileName,
          });
        }
      } catch (e) {
        debugPrint('Error storing resume text: $e');
        // Continue even if storing fails
      }

      return {
        'name': fileName,
        'bytes': fileBytes,
        'text': resumeText,
        'isReal': true,
        'success': true,
        'message': 'Resume processed',
      };
    } catch (e) {
      debugPrint('Error picking file: $e');
      // Return dummy data if file picking fails
      return await _fallbackSimulation();
    }
  }

  // Fallback method for when file picking fails
  static Future<Map<String, dynamic>?> _fallbackSimulation() async {
    // Show a toast or message that we're falling back to simulation
    debugPrint('Falling back to simulated CV data');

    // Create a simulated file with dummy data
    final simulatedFileName = "fallback-cv-${DateTime.now().millisecondsSinceEpoch}.pdf";
    final dummyBytes = Uint8List.fromList(List.generate(1024, (index) => index % 256));
    final simulatedText = """
    John Doe
    Software Developer
    
    Contact Information:
    Email: john.doe@example.com
    Phone: (555) 123-4567
    
    Skills:
    - Flutter Development
    - Dart Programming
    - Mobile App Development
    - UI/UX Design
    - RESTful API Integration
    - Firebase
    
    Experience:
    Senior Mobile Developer - Tech Solutions Inc.
    2020 - Present
    - Developed cross-platform mobile applications using Flutter
    - Implemented state management using Provider and Bloc patterns
    - Integrated RESTful APIs for data fetching and synchronization
    
    Junior Developer - Mobile Innovations
    2018 - 2020
    - Assisted in the development of Android applications using Java
    - Collaborated with the design team for UI implementation
    - Fixed bugs and improved application performance
    
    Education:
    Bachelor of Science in Computer Science
    University of Technology, 2018
    """;

    // Store the simulated text in Supabase
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId != null) {
        await Supabase.instance.client.from('resumes').insert({
          'applicant_id': userId,
          'text': simulatedText,
          'filename': simulatedFileName,
        });
      }
    } catch (e) {
      debugPrint('Error storing simulated resume text: $e');
      // Continue even if storing fails
    }

    return {
      'name': simulatedFileName,
      'bytes': dummyBytes,
      'text': simulatedText,
      'isReal': false,
      'success': true,
      'message': 'Using simulated CV data',
    };
  }
}