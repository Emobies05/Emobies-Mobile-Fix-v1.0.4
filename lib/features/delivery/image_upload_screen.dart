import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/theme.dart';
import '../../core/services/api_service.dart';
import '../../core/services/auth_service.dart';

class ImageUploadScreen extends StatefulWidget {
  final String complaintId;
  const ImageUploadScreen({super.key, required this.complaintId});

  @override
  State<ImageUploadScreen> createState() => _ImageUploadScreenState();
}

class _ImageUploadScreenState extends State<ImageUploadScreen> {
  final _api = ApiService(AuthService());
  final List<File> _images = [];
  bool _uploading = false;
  double _uploadProgress = 0;

  Future<void> _takePhoto() async {
    if (_images.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Max 5 photos', style: GoogleFonts.syne())),
      );
      return;
    }
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.camera, maxWidth: 1024);
    if (picked != null) {
      setState(() => _images.add(File(picked.path)));
    }
  }

  Future<void> _upload() async {
    if (_images.isEmpty) return;

    setState(() { _uploading = true; _uploadProgress = 0; });

    try {
      final urls = <String>[];
      for (var i = 0; i < _images.length; i++) {
        final url = await _api.uploadImage(_images[i], folder: 'delivery');
        urls.add(url);
        setState(() => _uploadProgress = (i + 1) / _images.length);
      }

      await _api.updateComplaintStatus(widget.complaintId, 'phone_collected', extra: {
        'images_before': urls,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Photos uploaded!', style: GoogleFonts.syne(color: EmobiesTheme.green)),
          backgroundColor: EmobiesTheme.card,
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      setState(() => _uploading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e', style: GoogleFonts.syne(color: EmobiesTheme.red))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EmobiesTheme.bg,
      appBar: AppBar(title: const Text('Upload Photos')),
      body: Column(
        children: [
          Expanded(
            child: _images.isEmpty
                ? Center(
                    child: GestureDetector(
                      onTap: _takePhoto,
                      child: Container(
                        padding: const EdgeInsets.all(40),
                        decoration: BoxDecoration(
                          color: EmobiesTheme.card,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: EmobiesTheme.border, style: BorderStyle.solid),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.camera_alt_outlined, color: EmobiesTheme.orange, size: 48),
                            const SizedBox(height: 12),
                            Text('Take Photo', style: GoogleFonts.syne(fontWeight: FontWeight.w800, fontSize: 16)),
                            Text('Document phone condition', style: GoogleFonts.syne(fontSize: 12, color: EmobiesTheme.text2)),
                          ],
                        ),
                      ),
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: _images.length + (_images.length < 5 ? 1 : 0),
                    itemBuilder: (_, i) {
                      if (i == _images.length) {
                        return GestureDetector(
                          onTap: _takePhoto,
                          child: Container(
                            decoration: BoxDecoration(
                              color: EmobiesTheme.card,
                              borderRadius: BorderRadius.circular(13),
                              border: Border.all(color: EmobiesTheme.border, style: BorderStyle.solid),
                            ),
                            child: const Icon(Icons.add_a_photo_outlined, color: EmobiesTheme.muted, size: 32),
                          ),
                        );
                      }
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(13),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.file(_images[i], fit: BoxFit.cover),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: GestureDetector(
                                onTap: () => setState(() => _images.removeAt(i)),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close, color: Colors.white, size: 16),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          // Upload button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: EmobiesTheme.surface,
              border: const Border(top: BorderSide(color: EmobiesTheme.border)),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  if (_uploading) ...[
                    LinearProgressIndicator(
                      value: _uploadProgress,
                      backgroundColor: EmobiesTheme.border,
                      valueColor: const AlwaysStoppedAnimation(EmobiesTheme.orange),
                    ),
                    const SizedBox(height: 8),
                    Text('${(_uploadProgress * 100).toStringAsFixed(0)}%',
                        style: GoogleFonts.jetBrainsMono(fontSize: 11, color: EmobiesTheme.muted)),
                    const SizedBox(height: 8),
                  ],
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _images.isEmpty || _uploading ? null : _upload,
                      child: Text('Upload ${ _images.length} Photo${_images.length > 1 ? 's' : ''}',
                          style: GoogleFonts.syne(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}