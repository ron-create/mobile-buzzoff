import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../actions/educational_content_actions.dart';
import '../../utils/responsive.dart';

class AllArticlesPage extends StatefulWidget {
  const AllArticlesPage({super.key});

  @override
  State<AllArticlesPage> createState() => _AllArticlesPageState();
}

class _AllArticlesPageState extends State<AllArticlesPage> {
  final _action = EducationalContentAction();
  bool _isLoading = true;
  List<Map<String, dynamic>> _articles = [];

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

  @override
  void initState() {
    super.initState();
    _loadArticles();
  }

  Future<void> _loadArticles() async {
    try {
      final articles = await _action.fetchRelatedArticles();
      setState(() {
        _articles = articles;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❗ Error loading articles: $e');
      setState(() {
        _isLoading = false;
      });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  // Back Button
                  Padding(
                    padding: EdgeInsets.all(Responsive.padding(context, 16)),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.black),
                        onPressed: () => Navigator.of(context).pop(),
                        tooltip: 'Back',
                      ),
                    ),
                  ),
                  // Description
                  Padding(
                    padding: EdgeInsets.all(Responsive.padding(context, 16)),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Browse curated articles from trusted sources. Tap an item to open it in your browser.',
                        style: TextStyle(
                          fontSize: Responsive.font(context, 13),
                          color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: _articles.isEmpty
                        ? const Center(child: Text('No articles available'))
                        : ListView.builder(
                            padding: EdgeInsets.symmetric(horizontal: Responsive.padding(context, 16)),
                            itemCount: _articles.length,
                            itemBuilder: (context, index) {
                              final article = _articles[index];
                              return Card(
                                margin: EdgeInsets.only(bottom: Responsive.vertical(context, 16)),
                                color: Theme.of(context).colorScheme.surface,
                                child: ListTile(
                                  contentPadding: EdgeInsets.all(Responsive.padding(context, 16)),
                                  leading: Container(
                                    width: Responsive.icon(context, 60),
                                    height: Responsive.icon(context, 60),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade800 : Colors.grey.shade400,
                                      borderRadius: BorderRadius.circular(8),
                                      image: article['urlToImage'] != null
                                          ? DecorationImage(
                                              image: NetworkImage(article['urlToImage']),
                                              fit: BoxFit.cover,
                                            )
                                          : null,
                                    ),
                                    child: article['urlToImage'] == null
                                        ? Icon(
                                            Icons.article,
                                            color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.white70,
                                            size: Responsive.icon(context, 30),
                                          )
                                        : null,
                                  ),
                                  title: Text(
                                    article['title'] ?? 'No title',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: Responsive.font(context, 16),
                                      color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(height: Responsive.vertical(context, 8)),
                                      Text(
                                        article['description'] ?? 'No description available',
                                        style: TextStyle(
                                          fontSize: Responsive.font(context, 12),
                                          color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.grey,
                                        ),
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      SizedBox(height: Responsive.vertical(context, 8)),
                                      Text(
                                        'Source: ${article['source']?['name'] ?? 'Unknown'}',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: Color(0xFF5271FF),
                                        ),
                                      ),
                                    ],
                                  ),
                                  onTap: () => _openArticleUrl(article['url']),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
      ),
    );
  }
}
