enum NewsCategory { crypto, forex }

enum NewsSortOrder { latest, oldest }

class NewsArticle {
  final String id;
  final String title;
  final String description; // plain text, HTML stripped
  final String? imageUrl;
  final String url;
  final DateTime publishedAt;
  final String source;
  final NewsCategory category;

  const NewsArticle({
    required this.id,
    required this.title,
    required this.description,
    this.imageUrl,
    required this.url,
    required this.publishedAt,
    required this.source,
    required this.category,
  });
}
