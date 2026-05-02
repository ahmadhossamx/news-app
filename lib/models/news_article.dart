import 'package:cloud_firestore/cloud_firestore.dart';

class NewsArticle {
  final String id;
  final String title;
  final String summary;
  final String body;
  final String imageUrl;
  final String category;
  final String source;
  final DateTime publishedAt;
  final bool isHot;
  final String? author;
  final String? url;

  const NewsArticle({
    required this.id,
    required this.title,
    required this.summary,
    required this.body,
    required this.imageUrl,
    required this.category,
    required this.source,
    required this.publishedAt,
    this.isHot = false,
    this.author,
    this.url,
  });

  factory NewsArticle.fromNewsApi(Map<String, dynamic> json) {
    final publishedAt = DateTime.tryParse(json['publishedAt'] ?? '') ?? DateTime.now();
    final now = DateTime.now();
    final isRecent = now.difference(publishedAt).inHours < 6;

    String category = 'world';
    final sourceName = (json['source']?['name'] ?? '').toString().toLowerCase();

    if (sourceName.contains('sport') || sourceName.contains('espn')) {
      category = 'sports';
    } else if (sourceName.contains('tech') || sourceName.contains('wired')) {
      category = 'technology';
    } else if (sourceName.contains('business') || sourceName.contains('finance')) {
      category = 'economy';
    } else if (sourceName.contains('entertainment') || sourceName.contains('culture')) {
      category = 'culture';
    } else if (sourceName.contains('politic') || sourceName.contains('government')) {
      category = 'politics';
    } else if (sourceName.contains('health') || sourceName.contains('medical')) {
      category = 'health';
    }

    return NewsArticle(
      id: json['url']?.hashCode.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: json['title'] ?? 'بدون عنوان',
      summary: json['description'] ?? '',
      body: json['content'] ?? json['description'] ?? '',
      imageUrl: json['urlToImage'] ?? '',
      category: category,
      source: json['source']?['name'] ?? 'مصدر غير معروف',
      publishedAt: publishedAt,
      isHot: isRecent,
      author: json['author'],
      url: json['url'],
    );
  }

  factory NewsArticle.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return NewsArticle(
      id: doc.id,
      title: d['title'] ?? '',
      summary: d['summary'] ?? '',
      body: d['body'] ?? '',
      imageUrl: d['imageUrl'] ?? '',
      category: d['category'] ?? 'general',
      source: d['source'] ?? 'أبوكاليبس',
      publishedAt: (d['publishedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isHot: d['isHot'] ?? false,
      author: d['author'],
      url: d['url'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'summary': summary,
      'body': body,
      'imageUrl': imageUrl,
      'category': category,
      'source': source,
      'publishedAt': Timestamp.fromDate(publishedAt),
      'isHot': isHot,
      'author': author,
      'url': url,
    };
  }

  static List<NewsArticle> get demoArticles => [
    NewsArticle(
      id: '1',
      title: 'قمة عالمية لبحث أزمة المناخ في نيويورك',
      summary: 'يجتمع قادة من أكثر من 190 دولة لمناقشة خطط جريئة لمواجهة التغيرات المناخية المتسارعة.',
      body: 'انطلقت في مدينة نيويورك قمة عالمية كبرى بحضور قادة الدول والمنظمات الدولية لمناقشة أزمة المناخ المتصاعدة.',
      imageUrl: 'https://images.unsplash.com/photo-1504711434969-e33886168f5c?w=800',
      category: 'world',
      source: 'أبوكاليبس',
      publishedAt: DateTime.now().subtract(const Duration(hours: 2)),
      isHot: true,
    ),
    NewsArticle(
      id: '2',
      title: 'المنتخب الوطني يتأهل لنهائيات كأس العالم',
      summary: 'نجح المنتخب في التأهل بعد فوز مثير في آخر مباريات التصفيات بهدفين مقابل هدف.',
      body: 'كتب المنتخب الوطني اسمه في قائمة المتأهلين لكأس العالم بعد مباراة مثيرة.',
      imageUrl: 'https://images.unsplash.com/photo-1553778263-73a83bab9b0c?w=800',
      category: 'sports',
      source: 'رياضة أبوكاليبس',
      publishedAt: DateTime.now().subtract(const Duration(hours: 5)),
      isHot: true,
    ),
    NewsArticle(
      id: '3',
      title: 'اختراق تكنولوجي جديد في مجال الذكاء الاصطناعي',
      summary: 'شركة عالمية تعلن عن نموذج ذكاء اصطناعي قادر على محاكاة التفكير البشري.',
      body: 'كشفت إحدى كبرى شركات التكنولوجيا عن نموذج جديد للذكاء الاصطناعي.',
      imageUrl: 'https://images.unsplash.com/photo-1677442135703-1787eea5ce01?w=800',
      category: 'technology',
      source: 'تقنية أبوكاليبس',
      publishedAt: DateTime.now().subtract(const Duration(hours: 8)),
      isHot: false,
    ),
  ];
}
