import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import '../../config/theme.dart';

class ImageViewerScreen extends StatelessWidget {
  final List<String> imageUrls;
  const ImageViewerScreen({super.key, required this.imageUrls});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EmobiesTheme.bg,
      appBar: AppBar(
        title: Text('${imageUrls.length} Photos', style: GoogleFonts.syne(fontWeight: FontWeight.w800)),
        backgroundColor: Colors.black.withOpacity(0.5),
      ),
      body: imageUrls.isEmpty
          ? Center(child: Text('No photos', style: GoogleFonts.syne(color: EmobiesTheme.muted)))
          : PhotoViewGallery.builder(
              itemCount: imageUrls.length,
              builder: (context, index) {
                return PhotoViewGalleryPageOptions(
                  imageProvider: NetworkImage(imageUrls[index]),
                  minScale: PhotoViewComputedScale.contained * 0.8,
                  maxScale: PhotoViewComputedScale.covered * 2,
                );
              },
              scrollPhysics: const BouncingScrollPhysics(),
              backgroundDecoration: BoxDecoration(color: EmobiesTheme.bg),
              loadingBuilder: (context, event) => const Center(
                child: CircularProgressIndicator(color: EmobiesTheme.orange),
              ),
            ),
    );
  }
}