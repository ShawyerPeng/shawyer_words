import 'package:flutter_test/flutter_test.dart';
import 'package:shawyer_words/features/learning/data/in_memory_learning_repository.dart';

void main() {
  test('seeded repository exposes popular articles and categories', () {
    final repository = InMemoryLearningRepository.seeded();

    final allArticles = repository.loadAllArticles();
    final popularArticles = repository.loadPopularArticles();
    final categories = repository.loadCategories();

    expect(allArticles, isNotEmpty);
    expect(popularArticles, isNotEmpty);
    expect(popularArticles.every((article) => article.isPopular), isTrue);
    expect(categories, containsAll(<String>['Nature', 'Travel', 'Sports']));
  });
}
