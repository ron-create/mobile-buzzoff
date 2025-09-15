import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:go_router/go_router.dart';
import '../../utils/responsive.dart';
import '../../theme/app_theme.dart';
import '../../supabase/supabase_config.dart';

class InfographicsCard extends StatefulWidget {
  final Map<String, dynamic> infographic;
  final VoidCallback? onTap;
  final bool compact;

  const InfographicsCard({
    super.key,
    required this.infographic,
    this.onTap,
    this.compact = false,
  });

  @override
  State<InfographicsCard> createState() => _InfographicsCardState();
}

class _InfographicsCardState extends State<InfographicsCard> {
  bool _isLoading = false;

    @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap ?? () => _showFullScreenModal(context),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        margin: EdgeInsets.symmetric(horizontal: Responsive.padding(context, 4)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12), // Less rounded
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 10),
              spreadRadius: 0,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
              spreadRadius: 0,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12), // Less rounded
          child: _buildImage(),
        ),
      ),
    );
  }

  Widget _buildImage() {
    if (widget.infographic['image_url'] != null) {
      final imageUrl = widget.infographic['image_url']!;
      
      // Since we're using Supabase storage, all URLs will be network URLs
      return Image.network(
        imageUrl,
        fit: BoxFit.cover, // Changed to cover for better card display
        width: double.infinity,
        height: double.infinity,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _buildPlaceholder();
        },
        errorBuilder: (context, error, stackTrace) {
          print('Error loading image: $error');
          return _buildPlaceholder();
        },
      );
    } else {
      return _buildPlaceholder();
    }
  }

  Widget _buildPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withOpacity(0.1),
            AppColors.accent.withOpacity(0.1),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.health_and_safety,
          size: Responsive.icon(context, 48),
          color: AppColors.primary,
        ),
      ),
    );
  }

  void _showFullScreenModal(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => _FullScreenInfographic(
          infographic: widget.infographic,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }
}

class _FullScreenInfographic extends StatelessWidget {
  final Map<String, dynamic> infographic;

  const _FullScreenInfographic({
    required this.infographic,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Full screen image
            if (infographic['image_url'] != null)
              Container(
                width: double.infinity,
                height: double.infinity,
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Image.network(
                    infographic['image_url']!,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return _buildFullScreenPlaceholder(context);
                    },
                    errorBuilder: (context, error, stackTrace) {
                      print('Full screen error: $error');
                      return _buildFullScreenPlaceholder(context);
                    },
                  ),
                ),
              )
            else
              _buildFullScreenPlaceholder(context),
            
            // Close button overlay
            Positioned(
              top: Responsive.vertical(context, 20),
              right: Responsive.padding(context, 20),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(
                    Icons.close,
                    color: Colors.white,
                    size: Responsive.icon(context, 28),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFullScreenPlaceholder(BuildContext context) {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.border,
          width: 1,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.health_and_safety,
              size: Responsive.icon(context, 64),
              color: AppColors.primary,
            ),
            SizedBox(height: Responsive.vertical(context, 16)),
            Text(
              'Infographic Image',
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
                fontSize: Responsive.font(context, 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Service class for Supabase infographics
class SupabaseInfographicsService {
  static const String _bucketName = 'infographics';
  
  // Simple fetch from infographics bucket
  static Future<List<Map<String, dynamic>>> getDengueInfographics() async {
    try {
      print('Fetching from bucket: $_bucketName');
      
      // Get files from bucket
      final List<dynamic> files = await supabase.storage
          .from(_bucketName)
          .list();
      
      print('Found ${files.length} files');
      
      if (files.isEmpty) {
        print('No files found');
        return [];
      }
      
      // Convert to simple list with image URLs
      final List<Map<String, dynamic>> infographics = [];
      
      for (final file in files) {
        final fileName = file.name; // Use .name property instead of ['name']
        if (fileName != null && _isImageFile(fileName)) {
          final imageUrl = supabase.storage
              .from(_bucketName)
              .getPublicUrl(fileName);
          
          infographics.add({
            'image_url': imageUrl,
          });
          
          print('Added: $fileName -> $imageUrl');
        }
      }
      
      // Take first 5 and shuffle
      infographics.shuffle();
      final result = infographics.take(5).toList();
      
      print('Returning ${result.length} infographics');
      return result;
      
    } catch (e) {
      print('Error: $e');
      return [];
    }
  }
  
  // Check if file is image
  static bool _isImageFile(String fileName) {
    final imageExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp'];
    final lowerFileName = fileName.toLowerCase();
    return imageExtensions.any((ext) => lowerFileName.endsWith(ext));
  }
}
