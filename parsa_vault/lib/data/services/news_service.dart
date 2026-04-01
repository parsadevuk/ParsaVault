import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import '../../models/news_article.dart';

// ── Feed configuration ────────────────────────────────────────────────────────

class _FeedConfig {
  final String url;
  final String source;
  final NewsCategory category;
  const _FeedConfig(this.url, this.source, this.category);
}

const _feeds = [
  // Crypto
  _FeedConfig('https://cointelegraph.com/rss', 'CoinTelegraph', NewsCategory.crypto),
  _FeedConfig('https://decrypt.co/feed', 'Decrypt', NewsCategory.crypto),
  _FeedConfig('https://cryptoslate.com/feed/', 'CryptoSlate', NewsCategory.crypto),
  // Forex
  _FeedConfig('https://www.forexlive.com/feed/news', 'ForexLive', NewsCategory.forex),
  _FeedConfig('https://www.fxstreet.com/rss', 'FXStreet', NewsCategory.forex),
];

// ── Service ───────────────────────────────────────────────────────────────────

class NewsService {
  final _client = http.Client();

  /// Fetch all feeds concurrently, merge and sort by newest first.
  Future<List<NewsArticle>> fetchAll() async {
    final results = await Future.wait(
      _feeds.map((f) => _fetchFeed(f)),
      eagerError: false,
    );
    final all = results.expand((e) => e).toList();
    all.sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
    return all;
  }

  Future<List<NewsArticle>> _fetchFeed(_FeedConfig cfg) async {
    try {
      final response = await _client
          .get(Uri.parse(cfg.url), headers: {'User-Agent': 'ParsaVault/1.0'})
          .timeout(const Duration(seconds: 12));
      if (response.statusCode != 200) return [];
      return _parseRss(response.body, cfg.source, cfg.category);
    } catch (_) {
      return [];
    }
  }

  // ── RSS parser ──────────────────────────────────────────────────────────────

  List<NewsArticle> _parseRss(
    String xml,
    String source,
    NewsCategory category,
  ) {
    try {
      final doc = XmlDocument.parse(xml);
      final items = doc.findAllElements('item');
      final articles = <NewsArticle>[];

      for (final item in items) {
        final title = _text(item, 'title');
        if (title == null || title.isEmpty) continue;

        final link = _text(item, 'link') ?? _text(item, 'guid') ?? '';
        final description = _stripHtml(_text(item, 'description') ?? '');
        final pubDate = _parseDate(_text(item, 'pubDate'));
        final imageUrl = _findImage(item, _text(item, 'description'));

        articles.add(NewsArticle(
          id: link.isNotEmpty ? link : '${source}_${title.hashCode}',
          title: _cleanText(title),
          description: description,
          imageUrl: imageUrl,
          url: link,
          publishedAt: pubDate,
          source: source,
          category: category,
        ));
      }
      return articles;
    } catch (_) {
      return [];
    }
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  String? _text(XmlElement parent, String localName) {
    for (final child in parent.children) {
      if (child is XmlElement && child.localName == localName) {
        return child.innerText.trim();
      }
    }
    return null;
  }

  /// Try multiple locations where RSS feeds put images.
  String? _findImage(XmlElement item, String? rawDescription) {
    // 1. <media:content url="..." medium="image"/>
    for (final child in item.children) {
      if (child is XmlElement && child.localName == 'content') {
        final url = child.getAttribute('url') ?? '';
        final medium = child.getAttribute('medium') ?? '';
        if (url.isNotEmpty && (medium == 'image' || _looksLikeImage(url))) {
          return url;
        }
      }
    }

    // 2. <enclosure url="..." type="image/..."/>
    for (final child in item.children) {
      if (child is XmlElement && child.localName == 'enclosure') {
        final url = child.getAttribute('url') ?? '';
        final type = child.getAttribute('type') ?? '';
        if (url.isNotEmpty && type.startsWith('image')) return url;
      }
    }

    // 3. <media:thumbnail url="..."/>
    for (final child in item.children) {
      if (child is XmlElement && child.localName == 'thumbnail') {
        final url = child.getAttribute('url') ?? '';
        if (url.isNotEmpty) return url;
      }
    }

    // 4. Extract first <img src="..."> from description HTML
    if (rawDescription != null && rawDescription.isNotEmpty) {
      // Try double-quoted src first, then single-quoted
      final matchDouble =
          RegExp(r'<img[^>]+src="([^"]+)"', caseSensitive: false)
              .firstMatch(rawDescription);
      final matchSingle =
          RegExp("<img[^>]+src='([^']+)'", caseSensitive: false)
              .firstMatch(rawDescription);
      final url =
          matchDouble?.group(1) ?? matchSingle?.group(1) ?? '';
      if (url.isNotEmpty && _looksLikeImage(url)) return url;
    }

    return null;
  }

  bool _looksLikeImage(String url) {
    final lower = url.toLowerCase();
    return lower.contains('.jpg') ||
        lower.contains('.jpeg') ||
        lower.contains('.png') ||
        lower.contains('.webp') ||
        lower.contains('.gif');
  }

  String _stripHtml(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]+>'), '')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&apos;', "'")
        .replaceAll('&#39;', "'")
        .replaceAll('&nbsp;', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String _cleanText(String text) {
    return text
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&apos;', "'")
        .replaceAll('&#39;', "'")
        .replaceAll('&nbsp;', ' ')
        .trim();
  }

  /// Parse RFC 822 pubDate (used in RSS 2.0).
  /// Example: "Mon, 02 Aug 2024 10:30:00 +0000"
  DateTime _parseDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return DateTime.now();

    // Try ISO 8601 first (Atom feeds)
    try {
      return DateTime.parse(dateStr);
    } catch (_) {}

    // RFC 822
    try {
      const months = {
        'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4,
        'May': 5, 'Jun': 6, 'Jul': 7, 'Aug': 8,
        'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12,
      };
      final parts = dateStr.replaceAll(',', '').trim().split(RegExp(r'\s+'));
      // Skip optional day-of-week token
      int i = RegExp(r'^\d+$').hasMatch(parts[0]) ? 0 : 1;
      final day = int.parse(parts[i]);
      final month = months[parts[i + 1]] ?? 1;
      final year = int.parse(parts[i + 2]);
      final tp = parts[i + 3].split(':');
      final hour = int.parse(tp[0]);
      final minute = int.parse(tp[1]);
      final second = tp.length > 2 ? int.parse(tp[2]) : 0;
      return DateTime.utc(year, month, day, hour, minute, second);
    } catch (_) {
      return DateTime.now();
    }
  }
}
