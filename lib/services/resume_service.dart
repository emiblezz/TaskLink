import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tasklink/services/ai_services.dart';

class ResumeService {
  final SupabaseClient _supabaseClient;
  final AIService _aiService;

  ResumeService({
    required SupabaseClient supabaseClient,
    required AIService aiService,
  })  : _supabaseClient = supabaseClient,
        _aiService = aiService;

  // Upload a resume file and extract text
  Future<Map<String, dynamic>> uploadResume(PlatformFile file) async {
    try {
      final userId = _supabaseClient.auth.currentUser!.id;
      final fileName = file.name;
      final fileExtension = path.extension(fileName).toLowerCase();

      // Check if file type is supported
      if (!['.pdf', '.docx', '.doc', '.txt'].contains(fileExtension)) {
        return {
          'success': false,
          'message': 'Unsupported file type. Please upload PDF, DOCX, DOC or TXT files.'
        };
      }

      // Upload file to Supabase Storage
      String fileText = '';

      if (kIsWeb) {
        // Web platform - upload bytes
        final bytes = file.bytes!;
        await _supabaseClient.storage.from('resumes').uploadBinary(
          '$userId/$fileName',
          bytes,
          fileOptions: FileOptions(contentType: file.extension),
        );

        // Extract text from file
        fileText = await _extractTextFromFile(bytes, fileExtension);
      } else {
        // Mobile platform - upload file
        final filePath = file.path!;
        await _supabaseClient.storage.from('resumes').upload(
          '$userId/$fileName',
          File(filePath),
          fileOptions: FileOptions(contentType: file.extension),
        );

        // Extract text from file
        fileText = await _extractTextFromFile(File(filePath).readAsBytesSync(), fileExtension);
      }

      // If text extraction was successful, store the text in the database
      if (fileText.isNotEmpty) {
        await _supabaseClient.from('resumes').insert({
          'applicant_id': userId,
          'text': fileText,
          'filename': fileName,
        });

        return {
          'success': true,
          'message': 'Resume uploaded successfully!',
          'text': fileText,
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to extract text from the resume. Please try another file.',
        };
      }
    } catch (e) {
      debugPrint('Error uploading resume: $e');
      return {
        'success': false,
        'message': 'Error uploading resume: $e',
      };
    }
  }

  // Extract text from file - Fixed to accept a single Uint8List
  Future<String> _extractTextFromFile(Uint8List fileBytes, String fileExtension) async {
    try {
      // For this implementation, we'll use the backend to extract text
      // You would need to add an endpoint to your FastAPI backend for text extraction

      // For now, let's assume we can just read the text directly for simplicity
      // In a real implementation, you'd send the file to your backend for processing

      if (fileExtension == '.txt') {
        return utf8.decode(fileBytes);
      } else {
        // For PDF and DOCX files, you would typically send them to your backend
        // For now, we'll return a placeholder message
        return "Sample resume text. In a real implementation, you would process PDF and DOCX files to extract text.";
      }
    } catch (e) {
      debugPrint('Error extracting text: $e');
      return '';
    }
  }

  // Get resume for current user
  Future<Map<String, dynamic>?> getCurrentUserResume() async {
    try {
      final userId = _supabaseClient.auth.currentUser!.id;
      final response = await _supabaseClient
          .from('resumes')
          .select('*')
          .eq('applicant_id', userId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();  // Changed from single() to maybeSingle() to handle case where no record exists

      return response;
    } catch (e) {
      debugPrint('Error fetching resume: $e');
      return null;
    }
  }
}