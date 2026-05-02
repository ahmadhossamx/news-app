import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../main.dart';
import '../models/news_article.dart';
import '../services/news_service.dart';
import 'entry_screen.dart';

class NewsCategory {
  final String id;
  final String labelAr;
  final IconData icon;
  final Color color;

  const NewsCategory({
    required this.id,
    required this.labelAr,
    required this.icon,
    required this.color,
  });
}

const List<NewsCategory> kCategories = [
  NewsCategory(
    id: 'hot',
    labelAr: 'الأخبار العاجلة',
    icon: Icons.local_fire_department_rounded,
    color: AppColors.crimson,
  ),
  NewsCategory(
    id: 'politics',
    labelAr: 'السياسة',
    icon: Icons.account_balance_rounded,
    color: Color(0xFF2A6FC4),
  ),
  NewsCategory(
    id: 'sports',
    labelAr: 'الرياضة',
    icon: Icons.sports_soccer_rounded,
    color: Color(0xFF27AE60),
  ),
  NewsCategory(
    id: 'economy',
    labelAr: 'الاقتصاد',
    icon: Icons.trending_up_rounded,
    color: Color(0xFFF39C12),
  ),
  NewsCategory(
    id: 'technology',
    labelAr: 'التكنولوجيا',
    icon: Icons.memory_rounded,
    color: Color(0xFF8E44AD),
  ),
  NewsCategory(
    id: 'culture',
    labelAr: 'الثقافة والفن',
    icon: Icons.theater_comedy_rounded,
    color: Color(0xFFE67E22),
  ),
  NewsCategory(
    id: 'world',
    labelAr: 'أخبار العالم',
    icon: Icons.public_rounded,
    color: Color(0xFF16A085),
  ),
  NewsCategory(
    id: 'social',
    labelAr: 'المجتمع',
    icon: Icons.people_rounded,
    color: Color(0xFFD35400),
  ),
  NewsCategory(
    id: 'region',
    labelAr: 'منطقتك',
    icon: Icons.location_on_rounded,
    color: Color(0xFF2980B9),
  ),
  NewsCategory(
    id: 'health',
    labelAr: 'الصحة والعلوم',
    icon: Icons.health_and_safety_rounded,
    color: Color(0xFF1ABC9C),
  ),
];

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final NewsService _newsService = NewsService();
  final TextEditingController _searchCtrl = TextEditingController();
  
  List<NewsArticle> _articles = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadArticles();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _newsService.dispose();
    super.dispose();
  }

  Future<void> _loadArticles() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    
    try {
      final articles = await _newsService.fetchTopHeadlines(pageSize: 30);
      if (mounted) {
        setState(() {
          _articles = articles;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'فشل تحميل الأخبار. تحقق من اتصالك بالإنترنت.';
          _loading = false;
        });
      }
    }
  }

  Future<void> _searchArticles(String query) async {
    if (query.isEmpty) {
      _loadArticles();
      return;
    }
    
    setState(() {
      _loading = true;
      _error = null;
    });
    
    try {
      final articles = await _newsService.searchNews(query, pageSize: 20);
      if (mounted) {
        setState(() {
          _articles = articles;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'فشل البحث. حاول مرة أخرى.';
          _loading = false;
        });
      }
    }
  }

  List<NewsArticle> get _hotArticles =>
      _articles.where((a) => a.isHot).toList();

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: AppColors.navy,
        endDrawer: _CategoriesDrawer(articles: _articles),
        body: RefreshIndicator(
          onRefresh: _loadArticles,
          color: AppColors.crimson,
          backgroundColor: AppColors.navyMid,
          child: _loading ? _buildLoading() : _buildBody(),
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ApocalypseLogo(size: 60),
          SizedBox(height: 24),
          CircularProgressIndicator(color: AppColors.crimson),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_error != null) {
      return _buildError();
    }

    return CustomScrollView(
      slivers: [
        _buildAppBar(),
        SliverToBoxAdapter(child: _BreakingTicker(articles: _hotArticles)),
        SliverToBoxAdapter(child: _buildSearchBar()),
        const SliverToBoxAdapter(child: _SectionHeader(title: 'أبرز الأخبار')),
        if (_hotArticles.isNotEmpty)
          SliverToBoxAdapter(
            child: _HotNewsRow(articles: _hotArticles),
          ),
        const SliverToBoxAdapter(
            child: _SectionHeader(title: 'آخر الأخبار')),
        if (_articles.isEmpty)
          const SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'لا توجد أخبار متاحة',
                  style: TextStyle(color: AppColors.warmGray),
                ),
              ),
            ),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (ctx, i) => _NewsListTile(article: _articles[i]),
              childCount: _articles.length,
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: AppColors.crimson, size: 48),
          const SizedBox(height: 16),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.warmGray),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadArticles,
            icon: const Icon(Icons.refresh),
            label: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: TextField(
        controller: _searchCtrl,
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.right,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'ابحث في الأخبار...',
          hintStyle: const TextStyle(color: AppColors.warmGray),
          prefixIcon: const Icon(Icons.search, color: AppColors.warmGray),
          suffixIcon: _searchCtrl.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: AppColors.warmGray),
                  onPressed: () {
                    _searchCtrl.clear();
                    _loadArticles();
                    setState(() {});
                  },
                )
              : null,
          filled: true,
          fillColor: AppColors.navyMid,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
        onSubmitted: (value) {
          _searchArticles(value);
        },
        onChanged: (value) {
          setState(() {});
        },
      ),
    );
  }

  SliverAppBar _buildAppBar() {
    final user = FirebaseAuth.instance.currentUser;
    return SliverAppBar(
      pinned: true,
      backgroundColor: AppColors.navyMid,
      automaticallyImplyLeading: false,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.navyMid, AppColors.navy],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          border: Border(
            bottom: BorderSide(color: AppColors.crimson, width: 2),
          ),
        ),
      ),
      title: Row(
        textDirection: TextDirection.rtl,
        children: [
          GestureDetector(
            onTap: () => _scaffoldKey.currentState?.openEndDrawer(),
            child: Row(
              textDirection: TextDirection.rtl,
              children: [
                const Icon(Icons.menu, color: Colors.white, size: 22),
                const SizedBox(width: 6),
                Text(
                  'التصنيفات',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [AppColors.crimsonLight, AppColors.crimsonDark],
                  ),
                ),
                child: const Icon(Icons.public, color: Colors.white, size: 14),
              ),
              const SizedBox(width: 6),
              const Text(
                'أبوكاليبس',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const Spacer(),
          PopupMenuButton<String>(
            color: AppColors.navyMid,
            icon: CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.steel,
              child: Text(
                user?.displayName?.isNotEmpty == true
                    ? user!.displayName![0].toUpperCase()
                    : 'م',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            onSelected: (v) async {
              if (v == 'logout') {
                await FirebaseAuth.instance.signOut();
                if (mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const EntryScreen()),
                    (_) => false,
                  );
                }
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'user',
                enabled: false,
                child: Text(
                  user?.displayName ?? user?.email ?? 'مستخدم',
                  textDirection: TextDirection.rtl,
                  style: const TextStyle(color: AppColors.warmGray),
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  textDirection: TextDirection.rtl,
                  children: [
                    Icon(Icons.logout, color: AppColors.crimson, size: 18),
                    SizedBox(width: 8),
                    Text('تسجيل الخروج',
                        style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CategoriesDrawer extends StatelessWidget {
  final List<NewsArticle> articles;
  const _CategoriesDrawer({required this.articles});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Drawer(
        backgroundColor: AppColors.navyMid,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: AppColors.crimson, width: 2),
                  ),
                ),
                child: Row(
                  textDirection: TextDirection.rtl,
                  children: [
                    const Icon(Icons.menu, color: AppColors.crimson),
                    const SizedBox(width: 10),
                    const Text(
                      'التصنيفات',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.warmGray),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: kCategories.length,
                  itemBuilder: (ctx, i) {
                    final cat = kCategories[i];
                    final count = cat.id == 'hot'
                        ? articles.where((a) => a.isHot).length
                        : articles.where((a) => a.category == cat.id).length;
                    return _CategoryTile(
                      category: cat,
                      count: count,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          ctx,
                          MaterialPageRoute(
                            builder: (_) => CategoryNewsScreen(
                              category: cat,
                              articles: cat.id == 'hot'
                                  ? articles.where((a) => a.isHot).toList()
                                  : articles
                                      .where((a) => a.category == cat.id)
                                      .toList(),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final NewsCategory category;
  final int count;
  final VoidCallback onTap;

  const _CategoryTile({
    required this.category,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          textDirection: TextDirection.rtl,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: category.color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: category.color.withOpacity(0.4)),
              ),
              child: Icon(category.icon, color: category.color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                category.labelAr,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (count > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: category.color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    color: category.color,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_left, color: AppColors.warmGray, size: 18),
          ],
        ),
      ),
    );
  }
}

class CategoryNewsScreen extends StatelessWidget {
  final NewsCategory category;
  final List<NewsArticle> articles;

  const CategoryNewsScreen({
    super.key,
    required this.category,
    required this.articles,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.navy,
        appBar: AppBar(
          backgroundColor: AppColors.navyMid,
          foregroundColor: Colors.white,
          automaticallyImplyLeading: false,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(2),
            child: Container(height: 2, color: category.color),
          ),
          title: Row(
            textDirection: TextDirection.rtl,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: category.color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(category.icon, color: category.color, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                category.labelAr,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_forward_ios_rounded),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: articles.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(category.icon,
                        color: AppColors.steel, size: 60),
                    const SizedBox(height: 16),
                    const Text(
                      'لا توجد أخبار في هذا التصنيف حالياً',
                      style: TextStyle(color: AppColors.warmGray),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: articles.length,
                itemBuilder: (ctx, i) => _NewsListTile(article: articles[i]),
              ),
      ),
    );
  }
}

class NewsDetailScreen extends StatelessWidget {
  final NewsArticle article;

  const NewsDetailScreen({super.key, required this.article});

  @override
  Widget build(BuildContext context) {
    final cat = kCategories.firstWhere(
      (c) => c.id == article.category,
      orElse: () => kCategories.first,
    );

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.navy,
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 260,
              pinned: true,
              backgroundColor: AppColors.navyMid,
              foregroundColor: Colors.white,
              automaticallyImplyLeading: false,
              leading: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.arrow_forward_ios_rounded,
                      color: Colors.white, size: 18),
                ),
                onPressed: () => Navigator.pop(context),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    article.imageUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: article.imageUrl,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Shimmer.fromColors(
                              baseColor: AppColors.navyMid,
                              highlightColor: AppColors.steel,
                              child: Container(color: AppColors.navyMid),
                            ),
                            errorWidget: (context, url, error) =>
                                Container(color: AppColors.navyMid),
                          )
                        : Container(color: AppColors.navyMid),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            AppColors.navy.withOpacity(0.85),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      textDirection: TextDirection.rtl,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: cat.color.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                                color: cat.color.withOpacity(0.5)),
                          ),
                          child: Text(
                            cat.labelAr,
                            style: TextStyle(
                              color: cat.color,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (article.isHot) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.crimson.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Row(
                              textDirection: TextDirection.rtl,
                              children: [
                                Icon(Icons.local_fire_department,
                                    color: AppColors.crimson, size: 14),
                                SizedBox(width: 4),
                                Text(
                                  'عاجل',
                                  style: TextStyle(
                                    color: AppColors.crimson,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const Spacer(),
                        Text(
                          _timeAgo(article.publishedAt),
                          style: const TextStyle(
                            color: AppColors.warmGray,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      article.title,
                      textDirection: TextDirection.rtl,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 2,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.crimson, Colors.transparent],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      article.summary,
                      textDirection: TextDirection.rtl,
                      style: TextStyle(
                        color: AppColors.offWhite.withOpacity(0.85),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      article.body,
                      textDirection: TextDirection.rtl,
                      style: TextStyle(
                        color: AppColors.offWhite.withOpacity(0.75),
                        fontSize: 15,
                        height: 1.8,
                      ),
                    ),
                    const SizedBox(height: 28),
                    Row(
                      textDirection: TextDirection.rtl,
                      children: [
                        const Icon(Icons.article_outlined,
                            color: AppColors.warmGray, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'المصدر: ${article.source}',
                          style: const TextStyle(
                            color: AppColors.warmGray,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} دقيقة';
    if (diff.inHours < 24) return 'منذ ${diff.inHours} ساعة';
    return 'منذ ${diff.inDays} يوم';
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: AppColors.crimson,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _BreakingTicker extends StatelessWidget {
  final List<NewsArticle> articles;
  const _BreakingTicker({required this.articles});

  @override
  Widget build(BuildContext context) {
    if (articles.isEmpty) return const SizedBox.shrink();
    return Container(
      color: AppColors.crimson,
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            color: Colors.white,
            child: const Text(
              'عاجل',
              style: TextStyle(
                color: AppColors.crimson,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Expanded(
            child: Text(
              articles.first.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textDirection: TextDirection.rtl,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HotNewsRow extends StatelessWidget {
  final List<NewsArticle> articles;
  const _HotNewsRow({required this.articles});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: articles.length,
        itemBuilder: (ctx, i) => _HotNewsCard(article: articles[i]),
      ),
    );
  }
}

class _HotNewsCard extends StatelessWidget {
  final NewsArticle article;
  const _HotNewsCard({required this.article});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => NewsDetailScreen(article: article)),
      ),
      child: Container(
        width: 260,
        margin: const EdgeInsets.only(left: 12, bottom: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: AppColors.navyMid,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            fit: StackFit.expand,
            children: [
              article.imageUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: article.imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Shimmer.fromColors(
                        baseColor: AppColors.navyMid,
                        highlightColor: AppColors.steel,
                        child: Container(color: AppColors.navyMid),
                      ),
                      errorWidget: (context, url, error) =>
                          Container(color: AppColors.steel),
                    )
                  : Container(color: AppColors.steel),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      AppColors.navy.withOpacity(0.92),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.35, 1.0],
                  ),
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.crimson,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    textDirection: TextDirection.rtl,
                    children: [
                      Icon(Icons.local_fire_department,
                          color: Colors.white, size: 12),
                      SizedBox(width: 3),
                      Text(
                        'عاجل',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: 12,
                left: 12,
                right: 12,
                child: Text(
                  article.title,
                  textDirection: TextDirection.rtl,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NewsListTile extends StatelessWidget {
  final NewsArticle article;
  const _NewsListTile({required this.article});

  @override
  Widget build(BuildContext context) {
    final cat = kCategories.firstWhere(
      (c) => c.id == article.category,
      orElse: () => kCategories.first,
    );

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => NewsDetailScreen(article: article)),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.navyMid,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.steel.withOpacity(0.3)),
        ),
        child: Row(
          textDirection: TextDirection.rtl,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      textDirection: TextDirection.rtl,
                      children: [
                        Icon(cat.icon, color: cat.color, size: 13),
                        const SizedBox(width: 4),
                        Text(
                          cat.labelAr,
                          style: TextStyle(color: cat.color, fontSize: 11),
                        ),
                        const Spacer(),
                        Text(
                          _timeAgo(article.publishedAt),
                          style: const TextStyle(
                              color: AppColors.warmGray, fontSize: 11),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      article.title,
                      textDirection: TextDirection.rtl,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      article.summary,
                      textDirection: TextDirection.rtl,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.offWhite.withOpacity(0.6),
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
              child: article.imageUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: article.imageUrl,
                      width: 100,
                      height: 110,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Shimmer.fromColors(
                        baseColor: AppColors.navyMid,
                        highlightColor: AppColors.steel,
                        child: Container(
                          width: 100,
                          height: 110,
                          color: AppColors.navyMid,
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        width: 100,
                        height: 110,
                        color: AppColors.steel,
                        child: Icon(cat.icon, color: cat.color, size: 32),
                      ),
                    )
                  : Container(
                      width: 100,
                      height: 110,
                      color: AppColors.steel,
                      child: Icon(cat.icon, color: cat.color, size: 32),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} د';
    if (diff.inHours < 24) return 'منذ ${diff.inHours} س';
    return 'منذ ${diff.inDays} ي';
  }
}