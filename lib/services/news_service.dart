import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/news_article.dart';

class NewsService {
  static const String _apiKey = '0bec758b04524aab951fb3a574e53442';
  static const String _baseUrl = 'https://newsapi.org/v2';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final http.Client _client = http.Client();

  Future<List<NewsArticle>> fetchTopHeadlines({
    String country = 'us',
    String? category,
    int pageSize = 20,
  }) async {
    try {
      final queryParams = {
        'country': country,
        'pageSize': pageSize.toString(),
        'apiKey': _apiKey,
        if (category != null) 'category': category,
      };

      final uri = Uri.parse('$_baseUrl/top-headlines').replace(
        queryParameters: queryParams,
      );

      final response = await _client.get(uri).timeout(
        const Duration(seconds: 15),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['status'] == 'ok') {
          final articles = (data['articles'] as List)
              .map((json) => NewsArticle.fromNewsApi(json))
              .where((article) => 
                  article.title.isNotEmpty && 
                  article.summary.isNotEmpty)
              .toList();

          await _saveArticlesToFirestore(articles);
          return articles;
        }
      }

      throw Exception('Failed to fetch news: ${response.statusCode}');
    } on SocketException {
      return _getCachedArticles();
    } catch (e) {
      if (kDebugMode) print('News fetch error: $e');
      return _getCachedArticles();
    }
  }

  Future<List<NewsArticle>> searchNews(String query, {int pageSize = 20}) async {
    try {
      final uri = Uri.parse('$_baseUrl/everything').replace(
        queryParameters: {
          'q': query,
          'language': 'en',
          'sortBy': 'publishedAt',
          'pageSize': pageSize.toString(),
          'apiKey': _apiKey,
        },
      );

      final response = await _client.get(uri).timeout(
        const Duration(seconds: 15),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['status'] == 'ok') {
          return (data['articles'] as List)
              .map((json) => NewsArticle.fromNewsApi(json))
              .where((article) => 
                  article.title.isNotEmpty && 
                  article.summary.isNotEmpty)
              .toList();
        }
      }

      throw Exception('Search failed: ${response.statusCode}');
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _saveArticlesToFirestore(List<NewsArticle> articles) async {
    try {
      final batch = _firestore.batch();
      final collection = _firestore.collection('articles');

      for (final article in articles) {
        final docRef = collection.doc(article.id);
        batch.set(docRef, article.toFirestore(), SetOptions(merge: true));
      }

      await batch.commit();
    } catch (e) {
      if (kDebugMode) print('Error saving to Firestore: $e');
    }
  }

  Future<List<NewsArticle>> _getCachedArticles() async {
    try {
      final snap = await _firestore
          .collection('articles')
          .orderBy('publishedAt', descending: true)
          .limit(30)
          .get();

      return snap.docs.map((doc) => NewsArticle.fromFirestore(doc)).toList();
    } catch (e) {
      return NewsArticle.demoArticles;
    }
  }

  Stream<List<NewsArticle>> getArticlesStream() {
    return _firestore
        .collection('articles')
        .orderBy('publishedAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs.map(NewsArticle.fromFirestore).toList());
  }

  void dispose() {
    _client.close();
  }
}
