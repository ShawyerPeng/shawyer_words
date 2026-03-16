import 'package:flutter/material.dart' hide SearchController;
import 'package:shawyer_words/features/dictionary/application/dictionary_library_controller.dart';
import 'package:shawyer_words/features/dictionary/presentation/dictionary_library_management_page.dart';
import 'package:shawyer_words/features/home/presentation/home_dashboard_page.dart';
import 'package:shawyer_words/features/me/presentation/me_page.dart';
import 'package:shawyer_words/features/search/application/search_controller.dart';
import 'package:shawyer_words/features/search/presentation/search_page.dart';
import 'package:shawyer_words/features/shared/presentation/placeholder_section_page.dart';
import 'package:shawyer_words/features/study/domain/study_repository.dart';
import 'package:shawyer_words/features/study_plan/application/study_plan_controller.dart';
import 'package:shawyer_words/features/study_plan/presentation/study_home_page.dart';

enum _ShellTab { phraseBook, home, vocabulary }

class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    required this.dictionaryLibraryController,
    required this.searchController,
    required this.studyPlanController,
    required this.studyRepository,
  });

  final DictionaryLibraryController dictionaryLibraryController;
  final SearchController searchController;
  final StudyPlanController studyPlanController;
  final StudyRepository studyRepository;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  _ShellTab _selectedTab = _ShellTab.home;

  Future<void> _openMePage() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MePage(
          dictionaryLibraryManagementPageBuilder: (_) =>
              DictionaryLibraryManagementPage(
                controller: widget.dictionaryLibraryController,
              ),
        ),
      ),
    );
  }

  Future<void> _openSearchPage() async {
    widget.searchController.updateQuery('');
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SearchPage(controller: widget.searchController),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      const PlaceholderSectionPage(
        title: '句库',
        description: '这里会放你的表达收藏、句型资料和高频场景内容。',
        icon: Icons.format_quote_rounded,
      ),
      HomeDashboardPage(onOpenMe: _openMePage, onOpenSearch: _openSearchPage),
      StudyHomePage(
        controller: widget.studyPlanController,
        studyRepository: widget.studyRepository,
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
            bottom: 22,
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
                          icon: Icons.format_quote_rounded,
                          label: '句库',
                          active: _selectedTab == _ShellTab.phraseBook,
                          onTap: () => setState(
                            () => _selectedTab = _ShellTab.phraseBook,
                          ),
                        ),
                      ),
                      Expanded(
                        child: _BottomTabButton(
                          icon: Icons.add_rounded,
                          label: '新学习',
                          active: _selectedTab == _ShellTab.home,
                          emphasized: true,
                          onTap: () =>
                              setState(() => _selectedTab = _ShellTab.home),
                        ),
                      ),
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
    this.emphasized = false,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final activeColor = emphasized
        ? const Color(0xFFE2F8F0)
        : const Color(0xFFF1F4F9);

    return Material(
      color: active ? activeColor : Colors.transparent,
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
