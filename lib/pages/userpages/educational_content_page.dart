import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import '../../actions/educational_content_actions.dart';
import '../../utils/responsive.dart';
import 'chatbot_page.dart';

class EducationalContentDetailPage extends StatefulWidget {
  final String contentId;

  const EducationalContentDetailPage({super.key, required this.contentId});

  @override
  State<EducationalContentDetailPage> createState() =>
      _EducationalContentDetailPageState();
}

class _EducationalContentDetailPageState extends State<EducationalContentDetailPage> with SingleTickerProviderStateMixin {
  final EducationalContentAction _action = EducationalContentAction();
  Map<String, dynamic>? _content;
  bool _isLoading = true;
  VideoPlayerController? _videoController;
  AnimationController? _animController;
  Animation<double>? _fade;
  Animation<Offset>? _slide;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    _fade = CurvedAnimation(parent: _animController!, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.02), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animController!, curve: Curves.easeOutCubic));
    _loadContent();
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _animController?.dispose();
    super.dispose();
  }

  Future<void> _loadContent() async {
    final content = await _action.fetchSingleEducationalContent(widget.contentId);
    if (mounted) {
      setState(() {
        _content = content;
        _isLoading = false;
      });
      _animController?.forward();
      // Initialize video controller if content has a video
      if (content?['file'] != null && _isVideoFile(content!['file'])) {
        _initializeVideo(content['file']);
      }
    }
    // Record view
    await _action.recordContentView(widget.contentId);
  }

  bool _isVideoFile(String url) {
    final extension = url.split('.').last.toLowerCase();
    return ['mp4', 'webm', 'ogg'].contains(extension);
  }

  Future<void> _initializeVideo(String url) async {
    try {
      _videoController = VideoPlayerController.network(url);
      await _videoController!.initialize();
      // Don't autoplay
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Error initializing video: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error loading video')),
        );
      }
    }
  }

  Widget _buildVideoPlayer() {
    if (_videoController == null || !_videoController!.value.isInitialized) {
      return Container(
        width: double.infinity,
        height: 200,
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return AspectRatio(
      aspectRatio: _videoController!.value.aspectRatio,
      child: Stack(
        alignment: Alignment.center,
        children: [
          VideoPlayer(_videoController!),
          // Video controls overlay
          GestureDetector(
            onTap: () {
              setState(() {
                if (_videoController!.value.isPlaying) {
                  _videoController!.pause();
                } else {
                  _videoController!.play();
                }
              });
            },
            child: Container(
              color: Colors.black.withOpacity(0.3),
              child: Center(
                child: Icon(
                  _videoController!.value.isPlaying ? Icons.pause : Icons.play_arrow,
                  size: 64,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          // Video controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.7),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Progress bar
                  VideoProgressIndicator(
                    _videoController!,
                    allowScrubbing: true,
                    colors: const VideoProgressColors(
                      playedColor: Colors.red,
                      bufferedColor: Colors.white54,
                      backgroundColor: Colors.white24,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Control buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Replay 10 seconds
                      IconButton(
                        icon: const Icon(Icons.replay_10, color: Colors.white),
                        onPressed: () {
                          final newPosition = _videoController!.value.position - const Duration(seconds: 10);
                          _videoController!.seekTo(newPosition);
                        },
                      ),
                      // Play/Pause
                      IconButton(
                        icon: Icon(
                          _videoController!.value.isPlaying ? Icons.pause : Icons.play_arrow,
                          color: Colors.white,
                          size: 32,
                        ),
                        onPressed: () {
                          setState(() {
                            if (_videoController!.value.isPlaying) {
                              _videoController!.pause();
                            } else {
                              _videoController!.play();
                            }
                          });
                        },
                      ),
                      // Forward 10 seconds
                      IconButton(
                        icon: const Icon(Icons.forward_10, color: Colors.white),
                        onPressed: () {
                          final newPosition = _videoController!.value.position + const Duration(seconds: 10);
                          _videoController!.seekTo(newPosition);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openFile(String? url, String? fileType) async {
    if (url == null) return;
    
    try {
      final uri = Uri.parse(url);
      if (!await canLaunchUrl(uri)) {
        throw 'Could not launch $url';
      }
      
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
        webViewConfiguration: const WebViewConfiguration(
          enableJavaScript: true,
          enableDomStorage: true,
        ),
      );
    } catch (e) {
      debugPrint('Error launching URL: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open file: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildFilePreview(String? url, String? fileType) {
    if (url == null) return const SizedBox.shrink();

    // Check file type from URL or fileType field
    final extension = url.split('.').last.toLowerCase();
    final isImage = ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(extension);
    final isVideo = ['mp4', 'webm', 'ogg'].contains(extension);
    final isPDF = extension == 'pdf';
    final isDocument = ['doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx'].contains(extension);

    if (isImage) {
      return GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => Scaffold(
                backgroundColor: Colors.black,
                appBar: AppBar(
                  backgroundColor: Colors.black,
                  iconTheme: const IconThemeData(color: Colors.white),
                  title: const Text('Image', style: TextStyle(color: Colors.white)),
                ),
                body: Center(
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: Image.network(
                      url,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey.shade900,
                        child: const Center(child: Icon(Icons.error_outline, size: 40, color: Colors.white)),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(Responsive.screenWidth(context) < 600 ? 12 : 24),
          child: Container(
            color: Colors.grey.shade200,
            constraints: BoxConstraints(
              maxHeight: 320,
              minWidth: double.infinity,
            ),
            child: Image.network(
              url,
              width: double.infinity,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => Container(
                color: Colors.grey.shade300,
                child: const Icon(Icons.error_outline, size: 40, color: Colors.grey),
              ),
            ),
          ),
        ),
      );
    } else if (isVideo) {
      return GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => Scaffold(
                backgroundColor: Colors.black,
                appBar: AppBar(
                  backgroundColor: Colors.black,
                  iconTheme: const IconThemeData(color: Colors.white),
                  title: const Text('Video Player', style: TextStyle(color: Colors.white)),
                ),
                body: Center(
                  child: _buildVideoPlayer(),
                ),
              ),
            ),
          );
        },
        child: Container(
          width: double.infinity,
          height: 200,
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (_videoController != null && _videoController!.value.isInitialized)
                AspectRatio(
                  aspectRatio: _videoController!.value.aspectRatio,
                  child: VideoPlayer(_videoController!),
                ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.play_circle_fill,
                  size: 64,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    } else if (isPDF || isDocument) {
      return GestureDetector(
        onTap: () => _openFile(url, fileType),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(
                isPDF ? Icons.picture_as_pdf : Icons.description,
                size: 40,
                color: isPDF ? Colors.red : Colors.blue,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      url.split('/').last,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap to open ${isPDF ? 'PDF' : 'document'}',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.open_in_new),
                onPressed: () => _openFile(url, fileType),
              ),
            ],
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _content == null
                ? const Center(child: Text('Content not found'))
                : LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        padding: EdgeInsets.symmetric(
                          horizontal: Responsive.screenWidth(context) < 600 ? 16 : 48,
                          vertical: Responsive.screenWidth(context) < 600 ? 16 : 32,
                        ),
                        child: FadeTransition(
                          opacity: _fade ?? const AlwaysStoppedAnimation(1.0),
                          child: SlideTransition(
                            position: _slide ?? const AlwaysStoppedAnimation(Offset.zero),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Back Button
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: IconButton(
                                    icon: const Icon(Icons.arrow_back, color: Colors.black),
                                    onPressed: () => Navigator.of(context).pop(),
                                    tooltip: 'Back',
                                  ),
                                ),
                                // Title
                                if (_content!['title'] != null)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: Text(
                                      _content!['title'],
                                      style: TextStyle(
                                        fontSize: Responsive.screenWidth(context) < 600 ? 20 : 24,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                                      ),
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                const SizedBox(height: 8),
                                if (_content!['file'] != null)
                                  _buildFilePreview(_content!['file'], _content!['file_type']),
                                const SizedBox(height: 16),
                                // Description with truncation
                                if (_content!['description'] != null && _content!['description'].toString().trim().isNotEmpty)
                                  Text(
                                    _content!['description'],
                                    style: TextStyle(
                                      fontSize: Responsive.screenWidth(context) < 600 ? 16 : 18,
                                      color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
                                      height: 1.5,
                                    ),
                                    maxLines: 10,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                // Content with truncation
                                if ((_content!['description'] == null || _content!['description'].toString().trim().isEmpty) && _content!['content'] != null)
                                  Text(
                                    _content!['content'],
                                    style: TextStyle(
                                      fontSize: Responsive.screenWidth(context) < 600 ? 16 : 18,
                                      color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
                                      height: 1.5,
                                    ),
                                    maxLines: 15,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                const SizedBox(height: 24),
                                if (_videoController != null && _isVideoFile(_content!['file']))
                                  _buildVideoPlayer(),
                                if (_content!['created_at'] != null)
                                  Row(
                                    children: [
                                      Icon(Icons.calendar_today, size: 16, color: const Color(0xFF5271FF)),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          DateTime.parse(_content!['created_at']).toString().split(' ')[0],
                                          style: TextStyle(fontSize: 14, color: const Color(0xFF5271FF)),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'chatbot-educational',
        backgroundColor: Colors.transparent,
        elevation: 0,
        shape: const CircleBorder(),
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => SizedBox(
              height: MediaQuery.of(context).size.height * 0.85,
              child: const ChatbotSheet(),
            ),
          );
        },
        child: ClipOval(
          child: Image.asset(
            'assets/buzzAI.png',
            width: 56,
            height: 56,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}
