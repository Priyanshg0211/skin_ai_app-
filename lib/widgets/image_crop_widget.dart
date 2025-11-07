import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';

class ImageCropWidget {
  static Future<File?> cropImage(File imageFile) async {
    try {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: imageFile.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Image',
            toolbarColor: const Color(0xFF6C63FF),
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
          ),
          IOSUiSettings(
            title: 'Crop Image',
          ),
        ],
      );

      if (croppedFile != null) {
        return File(croppedFile.path);
      }
      return null;
    } catch (e) {
      debugPrint('Error cropping image: $e');
      return null;
    }
  }

  static Future<Uint8List?> cropImageBytes(Uint8List imageBytes) async {
    File? tempFile;
    File? croppedFile;
    try {
      // Create temporary file
      final tempDir = Directory.systemTemp;
      tempFile = File('${tempDir.path}/temp_crop_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await tempFile.writeAsBytes(imageBytes);

      croppedFile = await cropImage(tempFile);
      
      if (croppedFile != null) {
        final croppedBytes = await croppedFile.readAsBytes();
        // Clean up temp files
        try {
          if (tempFile.existsSync()) await tempFile.delete();
          // Only delete cropped file if it's in temp directory
          if (croppedFile.path.contains('temp_crop_') && croppedFile.existsSync()) {
            await croppedFile.delete();
          }
        } catch (_) {
            // Ignore cleanup errors
          }
        return croppedBytes;
      }
      
      return null;
    } catch (e) {
      debugPrint('Error cropping image bytes: $e');
      return null;
    } finally {
      // Ensure cleanup
      try {
        if (tempFile != null && tempFile.existsSync()) await tempFile.delete();
        if (croppedFile != null && croppedFile.path.contains('temp_crop_') && croppedFile.existsSync()) {
          await croppedFile.delete();
        }
      } catch (_) {
        // Ignore cleanup errors
      }
    }
  }
}

