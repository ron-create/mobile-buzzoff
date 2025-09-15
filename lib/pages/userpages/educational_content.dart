import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../actions/educational_content_actions.dart';
import 'all_barangay_educational_content.dart';
import 'educational_content_page.dart';
import 'all_articles_page.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../utils/responsive.dart';

class EducationalContentPage extends StatefulWidget {
  const EducationalContentPage({super.key});

  @override
  State<EducationalContentPage> createState() => _EducationalContentPageState();
}

class _EducationalContentPageState extends State<EducationalContentPage> {
  final EducationalContentAction _action = EducationalContentAction();
  List<Map<String, dynamic>> _educationalContent = [];
  List<Map<String, dynamic>> _relatedArticles = [];
  List<Map<String, dynamic>> _youtubeVideos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadContent();
    _loadYoutubeVideos();
  }

  Future<void> _loadContent() async {
    try {
      setState(() => _isLoading = true);
      
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final content = await _action.fetchBarangayEducationalContent(user.id);
        final articles = await _action.fetchRelatedArticles();
        
        if (mounted) {
          setState(() {
            _educationalContent = content;
            _relatedArticles = articles;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please log in to view content')),
          );
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error loading content')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadYoutubeVideos() async {
    final videos = await _action.fetchYoutubeVideos();
    if (mounted) {
      setState(() {
        _youtubeVideos = videos;
      });
    }
  }

  Future<void> _viewContent(String contentId) async {
    await _action.recordContentView(contentId);
    
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EducationalContentDetailPage(
            contentId: contentId,
          ),
        ),
      );
    }
  }

  Future<void> _openArticleUrl(String? url) async {
    if (url == null) return;
    
    try {
      final uri = Uri.parse(url);
      final proceed = await _confirmExternalNavigation(uri);
      if (!proceed) return;

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open article')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error opening article')),
        );
      }
    }
  }

  Future<bool> _confirmExternalNavigation(Uri uri) async {
    if (!mounted) return false;
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          top: false,
          child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.open_in_new_rounded,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Open external link?',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          uri.toString(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.9),
                      foregroundColor: Colors.white,
                      elevation: 0,
                    ),
                    child: const Text('Continue'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
        );
      },
    );
    return result ?? false;
  }

  Future<void> _openExternalUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      final proceed = await _confirmExternalNavigation(uri);
      if (!proceed) return;
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: Responsive.padding(context, 12),
            vertical: Responsive.vertical(context, 8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back Button and Title
              Padding(
                padding: EdgeInsets.only(bottom: Responsive.vertical(context, 16)),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.black),
                      onPressed: () => Navigator.of(context).pop(),
                      tooltip: 'Back',
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Learn',
                      style: TextStyle(
                        fontSize: Responsive.font(context, 20),
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
              // Page description
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(Responsive.padding(context, 12)),
                margin: EdgeInsets.only(bottom: Responsive.vertical(context, 12)),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Learn about dengue prevention, symptoms, and community updates. '
                  'Browse curated educational materials, related articles, and videos from trusted sources.',
                  style: TextStyle(
                    fontSize: Responsive.font(context, 13),
                    color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black87,
                  ),
                ),
              ),
              // Barangay Educational Content
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Barangay Educational Content',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: Responsive.font(context, 16),
                      color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const BarangayEducationalContentPage(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.arrow_outward_rounded, size: 18),
                    label: const Text('View all'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                      side: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.5)),
                      textStyle: TextStyle(fontSize: Responsive.font(context, 13), fontWeight: FontWeight.w600),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: Responsive.vertical(context, 240),
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _educationalContent.isEmpty
                        ? const Center(child: Text('No educational content available'))
                        : ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: _educationalContent.take(3).length,
                            separatorBuilder: (context, index) =>
                                SizedBox(width: Responsive.padding(context, 12)),
                            itemBuilder: (context, index) {
                              final content = _educationalContent[index];
                              return GestureDetector(
                                onTap: () => _viewContent(content['id']),
                                child: Container(
                                  constraints: BoxConstraints(
                                    maxWidth: MediaQuery.of(context).size.width * 0.45,
                                    minWidth: Responsive.screenWidth(context) * 0.25,
                                    maxHeight: MediaQuery.of(context).size.height * 0.35,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.surface,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Image or placeholder
                                      Container(
                                        height: Responsive.vertical(context, 80),
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade800 : Colors.grey.shade400,
                                          borderRadius: const BorderRadius.only(
                                            topLeft: Radius.circular(16),
                                            topRight: Radius.circular(16),
                                          ),
                                          image: content['file'] != null
                                              ? DecorationImage(
                                                  image: NetworkImage(content['file']),
                                                  fit: BoxFit.cover,
                                                )
                                              : null,
                                        ),
                                        child: content['file'] == null
                                            ? Icon(
                                                Icons.article,
                                                color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.white70,
                                                size: Responsive.icon(context, 40),
                                              )
                                            : null,
                                      ),
                                      Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: Responsive.padding(context, 10),
                                          vertical: Responsive.vertical(context, 6),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: Responsive.padding(context, 8),
                                                vertical: Responsive.vertical(context, 2),
                                              ),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF7AD6B6),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                content['title'] ?? 'Educational Content',
                                                style: TextStyle(fontSize: Responsive.font(context, 12), color: Colors.white, fontWeight: FontWeight.bold),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            SizedBox(height: Responsive.vertical(context, 6)),
                                            Text(
                                              content['content'] ?? 'No content available',
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: Responsive.font(context, 13),
                                                color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
                                              ),
                                            ),
                                            SizedBox(height: Responsive.vertical(context, 6)),
                                            Row(
                                              children: [
                                                Icon(Icons.calendar_today, size: Responsive.icon(context, 12), color: const Color(0xFF5271FF)),
                                                SizedBox(width: Responsive.padding(context, 4)),
                                                Expanded(
                                                  child: Text(
                                                    content['created_at'] != null
                                                        ? DateTime.parse(content['created_at']).toString().split(' ')[0]
                                                        : 'No date',
                                                    style: TextStyle(fontSize: Responsive.font(context, 11), color: const Color(0xFF5271FF)),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
              ),
              SizedBox(height: Responsive.vertical(context, 24)),
              // Related Articles
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Related Articles',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: Responsive.font(context, 16)),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AllArticlesPage(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.arrow_outward_rounded, size: 18),
                    label: const Text('View all'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                      side: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.5)),
                      textStyle: TextStyle(fontSize: Responsive.font(context, 13), fontWeight: FontWeight.w600),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: 240,
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _relatedArticles.isEmpty
                        ? const Center(child: Text('No related articles available'))
                        : ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: _relatedArticles.take(3).length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(width: 12),
                            itemBuilder: (context, index) {
                              final article = _relatedArticles[index];
                              return GestureDetector(
                                onTap: () => _openArticleUrl(article['url']),
                                child: Container(
                                  constraints: BoxConstraints(
                                    maxWidth: MediaQuery.of(context).size.width * 0.45,
                                    minWidth: 120,
                                    maxHeight: MediaQuery.of(context).size.height * 0.35,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.surface,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        height: 80,
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade400,
                                          borderRadius: const BorderRadius.only(
                                            topLeft: Radius.circular(16),
                                            topRight: Radius.circular(16),
                                          ),
                                          image: article['urlToImage'] != null
                                              ? DecorationImage(
                                                  image: NetworkImage(
                                                      article['urlToImage']),
                                                  fit: BoxFit.cover,
                                                )
                                              : null,
                                        ),
                                        child: article['urlToImage'] == null
                                            ? const Icon(
                                                Icons.article,
                                                color: Colors.white70,
                                                size: 40,
                                              )
                                            : null,
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                              Text(
                                                article['title'] ?? 'No title',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 8),
                                            Text(
                                              'Source: ${article['source']?['name'] ?? 'Unknown'}',
                                              style: const TextStyle(
                                                fontSize: 10,
                                                color: Color(0xFF5271FF),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
              ),
              // YouTube Videos Section
              if (_youtubeVideos.isNotEmpty) ...[
                SizedBox(height: Responsive.vertical(context, 24)),
                Text(
                  'YouTube Videos',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: Responsive.font(context, 16)),
                ),
                SizedBox(
                  height: 240,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _youtubeVideos.length,
                    separatorBuilder: (context, index) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final video = _youtubeVideos[index];
                      final videoId = video['id']['videoId'];
                      final title = video['snippet']['title'];
                      final thumbnail = video['snippet']['thumbnails']['high']['url'];
                      return GestureDetector(
                        onTap: () async {
                          final url = 'https://www.youtube.com/watch?v=$videoId';
                          await _openExternalUrl(url);
                        },
                        child: Container(
                          width: 200,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(16),
                                  topRight: Radius.circular(16),
                                ),
                                child: Image.network(
                                  thumbnail,
                                  height: 120,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Text(
                                  title,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}