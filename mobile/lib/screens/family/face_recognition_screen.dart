import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import '../../providers/auth_provider.dart';
import '../../services/family_service.dart';
import '../../models/family_member.dart';
import 'package:mobile/core/config/theme.dart';

class FaceRecognitionScreen extends ConsumerStatefulWidget {
  const FaceRecognitionScreen({super.key});

  @override
  ConsumerState<FaceRecognitionScreen> createState() => _FaceRecognitionScreenState();
}

class _FaceRecognitionScreenState extends ConsumerState<FaceRecognitionScreen> {
  final _picker = ImagePicker();
  
  File? _image;
  bool _isProcessing = false;
  FamilyMember? _matchedMember;
  bool _noMatch = false;

  Future<void> _captureImage() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
      );
      
      if (photo != null) {
        setState(() {
          _image = File(photo.path);
          _isProcessing = true;
          _matchedMember = null;
          _noMatch = false;
        });
        
        final identifier = ref.read(authProvider).identifier;
        if (identifier != null) {
          final match = await ref.read(familyServiceProvider).recognizeFace(_image!, identifier);
          if (mounted) {
            setState(() {
              _isProcessing = false;
              if (match != null) {
                _matchedMember = match;
              } else {
                _noMatch = true;
              }
            });
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _noMatch = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Who is this?', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                clipBehavior: Clip.antiAlias,
                child: _image != null 
                  ? Image.file(_image!, fit: BoxFit.cover)
                  : const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt, size: 80, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'Point camera at person\nand tap button below',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 22, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            if (_isProcessing)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(width: 16),
                    Text('Recognizing...', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  ],
                ),
              )
            else if (_matchedMember != null)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.green, width: 2),
                ),
                child: Column(
                  children: [
                    const Text('This is', style: TextStyle(fontSize: 24, color: Colors.grey)),
                    const SizedBox(height: 4),
                    Text(_matchedMember!.name, style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: AppColors.green)),
                    const SizedBox(height: 8),
                    Text('Your ${_matchedMember!.relationship}', style: const TextStyle(fontSize: 26, color: Colors.grey)),
                  ],
                ),
              )
            else if (_noMatch)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.red, width: 2),
                ),
                child: const Column(
                  children: [
                     Text("I don't recognize this person", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.red), textAlign: TextAlign.center),
                     SizedBox(height: 8),
                     Text("Try asking them their name, or try taking another photo.", style: TextStyle(fontSize: 22, color: Colors.redAccent), textAlign: TextAlign.center),
                  ],
                ),
              ),
            
            const SizedBox(height: 24),
            
            ElevatedButton(
              onPressed: _isProcessing ? null : _captureImage,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 24),
              ),
              child: Text(
                _image == null ? 'Take Photo' : 'Try Again', 
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
