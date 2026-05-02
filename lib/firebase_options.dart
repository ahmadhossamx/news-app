import 'package:firebase_core/firebase_core.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform => android;

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAyn-maKV7KyoMb2gqkIxYwP8AT_CGZoAc',
    appId: '1:137006191295:android:bfca818d5e52cc208d6c0a',
    messagingSenderId: '137006191295',
    projectId: 'apocalypse-news',
    storageBucket: 'apocalypse-news.firebasestorage.app',
  );
}