import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class FileService {
  // Pick CV files (PDF, DOC, DOCX)
  static Future<Map<String, dynamic>?> pickCV() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx'],
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

      return {
        'name': fileName,
        'bytes': fileBytes,
        'isReal': true,
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

    return {
      'name': simulatedFileName,
      'bytes': dummyBytes,
      'isReal': false,
    };
  }
}