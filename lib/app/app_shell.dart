import 'package:flutter/material.dart' hide SearchController;
import 'package:shawyer_words/features/dictionary/application/dictionary_controller.dart';
import 'package:shawyer_words/features/dictionary/application/dictionary_library_controller.dart';
import 'package:shawyer_words/features/dictionary/presentation/dictionary_library_management_page.dart';
import 'package:shawyer_words/features/home/presentation/home_dashboard_page.dart';
import 'package:shawyer_words/features/me/presentation/me_page.dart';
import 'package:shawyer_words/features/search/application/search_controller.dart';
import 'package:shawyer_words/features/search/presentation/search_page.dart';
import 'package:shawyer_words/features/settings/application/settings_controller.dart';
import 'package:shawyer_words/features/shared/presentation/placeholder_section_page.dart';
import 'package:shawyer_words/features/study/domain/study_repository.dart';
import 'package:shawyer_words/features/study_plan/application/study_plan_controller.dart';
import 'package:shawyer_words/features/study_plan/presentation/study_home_page.dart';
import 'package:shawyer_words/features/word_detail/presentation/word_detail_page.dart';

enum _ShellTab { vocabulary, knowledgeBase, learning, me }

class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    required this.dictionaryController,
    required this.dictionaryLibraryController,
    required this.pickDictionaryFile,
    required this.searchController,
    required this.settingsController,
    required this.studyPlanController,
    required this.studyRepository,
    required this.wordDetailPageBuilder,
  });

  final DictionaryController dictionaryController;
  final DictionaryLibraryController dictionaryLibraryController;
  final Future<String?> Function() pickDictionaryFile;
  final SearchController searchController;
  final SettingsController settingsController;
  final StudyPlanController studyPlanController;
  final StudyRepository studyRepository;
  final WordDetailPageBuilder wordDetailPageBuilder;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  _ShellTab _selectedTab = _ShellTab.knowledgeBase;

  void _openMePage() {
    setState(() {
      _selectedTab = _ShellTab.me;
    });
  }

  Future<void> _openSearchPage() async {
    widget.searchController.updateQuery('');
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SearchPage(
          controller: widget.searchController,
          wordDetailPageBuilder: widget.wordDetailPageBuilder,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      StudyHomePage(
        controller: widget.studyPlanController,
        studyRepository: widget.studyRepository,
        wordDetailPageBuilder: widget.wordDetailPageBuilder,
      ),
      HomeDashboardPage(onOpenMe: _openMePage, onOpenSearch: _openSearchPage),
      const PlaceholderSectionPage(
        title: '学习',
        description: '这里会放你的课程、训练营、学习记录和学习路径内容。',
        icon: Icons.auto_stories_rounded,
      ),
      MePage(
        settingsController: widget.settingsController,
        showCloseButton: false,
        dictionaryLibraryManagementPageBuilder: (_) =>
            DictionaryLibraryManagementPage(
              controller: widget.dictionaryLibraryController,
              dictionaryController: widget.dictionaryController,
              pickDictionaryFile: widget.pickDictionaryFile,
            ),
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF3F5FA),
      body: Stack(
        children: [
          Positioned.fill(
            child: IndexedStack(index: _selectedTab.index, children: pages),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 12,
            child: SafeArea(
              top: false,
              child: Center(
                child: Container(
                  width: 330,
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x140A1633),
                        blurRadius: 32,
                        offset: Offset(0, 18),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _BottomTabButton(
                          icon: Icons.menu_book_outlined,
                          label: '背单词',
                          active: _selectedTab == _ShellTab.vocabulary,
                          onTap: () => setState(
                            () => _selectedTab = _ShellTab.vocabulary,
                          ),
                        ),
                      ),
                      Expanded(
                        child: _BottomTabButton(
                          icon: Icons.collections_bookmark_outlined,
                          label: '知识库',
                          active: _selectedTab == _ShellTab.knowledgeBase,
                          onTap: () => setState(
                            () => _selectedTab = _ShellTab.knowledgeBase,
                          ),
                        ),
                      ),
                      Expanded(
                        child: _BottomTabButton(
                          icon: Icons.auto_stories_outlined,
                          label: '学习',
                          active: _selectedTab == _ShellTab.learning,
                          onTap: () =>
                              setState(() => _selectedTab = _ShellTab.learning),
                        ),
                      ),
                      Expanded(
                        child: _BottomTabButton(
                          icon: Icons.person_outline_rounded,
                          label: '我的',
                          active: _selectedTab == _ShellTab.me,
                          onTap: () =>
                              setState(() => _selectedTab = _ShellTab.me),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomTabButton extends StatelessWidget {
  const _BottomTabButton({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? const Color(0xFFF1F4F9) : Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 24, color: const Color(0xFF1E2230)),
              const SizedBox(height: 5),
              Text(
                label,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.visible,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: const Color(0xFF2C3242),
                  fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
