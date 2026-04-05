# Learning Tab Article UI Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Rebuild the `学习` tab into a reference-inspired article discovery page and add a dedicated article-reading page opened from article taps.

**Architecture:** Add a small self-contained `learning` feature backed by seeded local article data, route the shell's `学习` tab to the new learning home page, and push a dedicated article detail page for article reading.

**Tech Stack:** Flutter, Material 3, widget tests, in-memory seeded data

---

### Task 1: Define local article models and seeded repository

**Files:**
- Create: `lib/features/learning/domain/learning_article.dart`
- Create: `lib/features/learning/data/in_memory_learning_repository.dart`
- Test: `test/features/learning/data/in_memory_learning_repository_test.dart`

**Step 1: Write the failing test**

Create a repository test that verifies seeded articles load, include popular items, and expose category labels.

**Step 2: Run test to verify it fails**

Run: `flutter test test/features/learning/data/in_memory_learning_repository_test.dart`
Expected: FAIL because the learning feature does not exist yet.

**Step 3: Write minimal implementation**

Create:
- immutable article model
- simple category data or derived category labels
- repository methods for loading all articles, popular articles, recent articles, and categories

Seed a small but realistic article set with hero images and body content.

**Step 4: Run test to verify it passes**

Run: `flutter test test/features/learning/data/in_memory_learning_repository_test.dart`
Expected: PASS

**Step 5: Commit**

```bash
git add lib/features/learning test/features/learning
git commit -m "feat(learning): 添加文章数据模型"
```

### Task 2: Build the learning home page UI

**Files:**
- Create: `lib/features/learning/presentation/learning_home_page.dart`
- Modify: `lib/app/app_shell.dart`
- Test: `test/features/learning/presentation/learning_home_page_test.dart`
- Test: `test/features/home/presentation/app_shell_test.dart`

**Step 1: Write the failing test**

Add a widget test asserting that:
- tapping the `学习` tab no longer shows placeholder copy
- `Popular`, `Recent`, and `Explore by Category` are visible
- at least one seeded article title is visible

**Step 2: Run test to verify it fails**

Run: `flutter test test/features/learning/presentation/learning_home_page_test.dart test/features/home/presentation/app_shell_test.dart`
Expected: FAIL because the shell still routes to `PlaceholderSectionPage`.

**Step 3: Write minimal implementation**

Build the page with:
- pale page background
- large white rounded main container
- featured horizontal card scroller
- recent article list rows
- category cards section

Update the shell so the `学习` tab routes to `LearningHomePage`.

**Step 4: Run test to verify it passes**

Run: `flutter test test/features/learning/presentation/learning_home_page_test.dart test/features/home/presentation/app_shell_test.dart`
Expected: PASS

**Step 5: Commit**

```bash
git add lib/app lib/features/learning test/features/learning test/features/home
git commit -m "feat(learning): 重建学习首页"
```

### Task 3: Add article detail page and navigation flow

**Files:**
- Create: `lib/features/learning/presentation/learning_article_page.dart`
- Modify: `lib/features/learning/presentation/learning_home_page.dart`
- Test: `test/features/learning/presentation/learning_article_page_test.dart`

**Step 1: Write the failing test**

Add a widget test asserting that tapping a seeded article opens a detail page showing:
- hero title
- date label
- level switcher labels
- article body text

**Step 2: Run test to verify it fails**

Run: `flutter test test/features/learning/presentation/learning_article_page_test.dart`
Expected: FAIL because no article detail page exists yet.

**Step 3: Write minimal implementation**

Implement:
- detail route push from featured cards and recent rows
- hero image header with overlay controls
- local difficulty selection state
- stylized but non-functional audio bar
- readable body section with rounded content container

**Step 4: Run test to verify it passes**

Run: `flutter test test/features/learning/presentation/learning_article_page_test.dart`
Expected: PASS

**Step 5: Commit**

```bash
git add lib/features/learning test/features/learning
git commit -m "feat(learning): 添加文章详情页"
```

### Task 4: Run regression checks for shell and learning flow

**Files:**
- Modify: `test/features/home/presentation/app_shell_test.dart`
- Modify: `test/features/learning/presentation/learning_home_page_test.dart`
- Modify: `test/features/learning/presentation/learning_article_page_test.dart`

**Step 1: Run targeted tests**

Run:
```bash
flutter test \
  test/features/learning/data/in_memory_learning_repository_test.dart \
  test/features/learning/presentation/learning_home_page_test.dart \
  test/features/learning/presentation/learning_article_page_test.dart \
  test/features/home/presentation/app_shell_test.dart
```
Expected: PASS

**Step 2: Polish any unstable selectors or layout assertions**

Make the tests assert user-visible behavior rather than fragile implementation details.

**Step 3: Re-run the targeted suite**

Run the same command again and confirm PASS.

**Step 4: Commit**

```bash
git add test/features/learning test/features/home
git commit -m "test(learning): 补齐学习页回归覆盖"
```
