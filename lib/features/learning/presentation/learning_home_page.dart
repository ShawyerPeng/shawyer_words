import 'package:flutter/material.dart';
import 'package:shawyer_words/features/learning/data/in_memory_learning_repository.dart';
import 'package:shawyer_words/features/learning/domain/learning_article.dart';
import 'package:shawyer_words/features/learning/presentation/learning_article_page.dart';

class LearningHomePage extends StatelessWidget {
  LearningHomePage({super.key, InMemoryLearningRepository? repository})
    : repository = repository ?? InMemoryLearningRepository.seeded();

  final InMemoryLearningRepository repository;

  @override
  Widget build(BuildContext context) {
    final popularArticles = repository.loadPopularArticles();
    final recentArticles = repository.loadRecentArticles();
    final categories = repository.loadCategories();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 140),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(36),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x140A1633),
                blurRadius: 32,
                offset: Offset(0, 18),
              ),
            ],
          ),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Popular',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 178,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemBuilder: (context, index) {
                            final article = popularArticles[index];
                            return _PopularArticleCard(
                              article: article,
                              onTap: () => _openArticle(context, article),
                            );
                          },
                          separatorBuilder: (_, _) => const SizedBox(width: 14),
                          itemCount: popularArticles.length,
                        ),
                      ),
                      const SizedBox(height: 30),
                      Text(
                        'Recent',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                sliver: SliverList.separated(
                  itemBuilder: (context, index) {
                    final article = recentArticles[index];
                    return _RecentArticleTile(
                      article: article,
                      onTap: () => _openArticle(context, article),
                    );
                  },
                  separatorBuilder: (_, _) => const SizedBox(height: 18),
                  itemCount: recentArticles.length,
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(22, 28, 22, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Explore by Category',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 16),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: categories.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 14,
                              crossAxisSpacing: 14,
                              childAspectRatio: 1.75,
                            ),
                        itemBuilder: (context, index) {
                          return _CategoryCard(
                            label: categories[index],
                            palette: _categoryPalette(index),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openArticle(BuildContext context, LearningArticle article) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LearningArticlePage(article: article),
      ),
    );
  }

  List<Color> _categoryPalette(int index) {
    const palettes = <List<Color>>[
      <Color>[Color(0xFFE7F8CC), Color(0xFFC7F0AA)],
      <Color>[Color(0xFFD9F1FF), Color(0xFFB8E0FF)],
      <Color>[Color(0xFFFFE6D2), Color(0xFFFFC48F)],
      <Color>[Color(0xFFEADFFF), Color(0xFFD2C1FF)],
      <Color>[Color(0xFFFFE2EC), Color(0xFFFBB6CF)],
    ];
    return palettes[index % palettes.length];
  }
}

class _PopularArticleCard extends StatelessWidget {
  const _PopularArticleCard({required this.article, required this.onTap});

  final LearningArticle article;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: ValueKey<String>('popular-${article.id}'),
      onTap: onTap,
      child: Container(
        width: 250,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: article.heroGradient,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -8,
              top: -8,
              child: Opacity(
                opacity: 0.22,
                child: Icon(article.heroIcon, size: 86, color: Colors.white),
              ),
            ),
            Align(
              alignment: Alignment.bottomLeft,
              child: Text(
                article.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  height: 1.05,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentArticleTile extends StatelessWidget {
  const _RecentArticleTile({required this.article, required this.onTap});

  final LearningArticle article;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: ValueKey<String>('recent-${article.id}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 94,
              height: 94,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: LinearGradient(colors: article.heroGradient),
              ),
              child: Center(
                child: Icon(article.heroIcon, color: Colors.white, size: 38),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      article.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        height: 1.18,
                        color: Color(0xFF181B21),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_rounded,
                          size: 15,
                          color: Color(0xFFB4B8C2),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          article.publishedAtLabel,
                          style: const TextStyle(
                            color: Color(0xFFB0B4BE),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.grid_view_rounded,
                          size: 16,
                          color: Color(0xFFC2C6CF),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          article.category,
                          style: const TextStyle(
                            color: Color(0xFFB0B4BE),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.label, required this.palette});

  final String label;
  final List<Color> palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(colors: palette),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -14,
            bottom: -14,
            child: Icon(
              Icons.auto_stories_rounded,
              size: 74,
              color: Colors.black.withValues(alpha: 0.14),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF1D2A33),
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
