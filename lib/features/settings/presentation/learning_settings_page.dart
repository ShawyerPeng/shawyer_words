import 'package:flutter/material.dart';
import 'package:shawyer_words/features/settings/application/settings_controller.dart';
import 'package:shawyer_words/features/settings/domain/app_settings.dart';
import 'package:shawyer_words/features/settings/presentation/general_settings_page.dart';
import 'package:shawyer_words/features/settings/presentation/reminder_settings_page.dart';
import 'package:shawyer_words/features/settings/presentation/study_plan_settings_page.dart';
import 'package:shawyer_words/features/study_plan/application/study_plan_controller.dart';
import 'package:shawyer_words/features/study_srs/domain/fsrs_repository.dart';
import 'package:shawyer_words/features/word_detail/domain/word_knowledge_repository.dart';
import 'package:shawyer_words/features/word_detail/presentation/word_detail_page.dart';

class LearningSettingsPage extends StatelessWidget {
  const LearningSettingsPage({
    super.key,
    required this.controller,
    this.studyPlanController,
    this.wordKnowledgeRepository,
    this.fsrsRepository,
    this.wordDetailPageBuilder,
  });

  final SettingsController controller;
  final StudyPlanController? studyPlanController;
  final WordKnowledgeRepository? wordKnowledgeRepository;
  final FsrsRepository? fsrsRepository;
  final WordDetailPageBuilder? wordDetailPageBuilder;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final settings = controller.state.settings;
        return Scaffold(
          backgroundColor: const Color(0xFFF3F5FA),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
              children: [
                SettingsHeader(
                  title: '学习设置',
                  onBack: () => Navigator.of(context).pop(),
                ),
                const SizedBox(height: 20),
                SettingsGroup(
                  title: '学习偏好',
                  children: [
                    SettingsActionTile(
                      title: '单词书',
                      value: settings.selectedWordBookName.isEmpty
                          ? '未选择'
                          : settings.selectedWordBookName,
                      onTap: () => showSingleChoiceSheet<String>(
                        context,
                        title: '单词书',
                        currentValue: settings.selectedWordBookId,
                        options: const <SettingsOption<String>>[
                          SettingsOption(value: 'cet4-core', label: '四级核心词汇'),
                          SettingsOption(value: 'cet6-core', label: '六级核心词汇'),
                          SettingsOption(value: 'ielts-core', label: 'IELTS'),
                        ],
                        onSelected: (value) =>
                            controller.updateSelectedWordBook(
                              id: value,
                              name: switch (value) {
                                'cet4-core' => '四级核心词汇',
                                'cet6-core' => '六级核心词汇',
                                'ielts-core' => 'IELTS',
                                _ => value,
                              },
                            ),
                      ),
                    ),
                    SettingsActionTile(
                      title: '学习计划',
                      onTap:
                          studyPlanController == null ||
                                  wordKnowledgeRepository == null ||
                                  fsrsRepository == null ||
                                  wordDetailPageBuilder == null
                              ? null
                              : () => Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => StudyPlanSettingsPage(
                                      settingsController: controller,
                                      studyPlanController: studyPlanController!,
                                      wordKnowledgeRepository:
                                          wordKnowledgeRepository!,
                                      fsrsRepository: fsrsRepository!,
                                      wordDetailPageBuilder:
                                          wordDetailPageBuilder!,
                                    ),
                                  ),
                                ),
                    ),
                    SettingsActionTile(
                      title: '每日学习计划',
                      value: '${settings.dailyStudyTarget} 新词/天',
                      onTap: () => showSingleChoiceSheet<int>(
                        context,
                        title: '每日学习计划',
                        currentValue: settings.dailyStudyTarget,
                        options: const <SettingsOption<int>>[
                          SettingsOption(value: 10, label: '10 词/天'),
                          SettingsOption(value: 20, label: '20 词/天'),
                          SettingsOption(value: 30, label: '30 词/天'),
                          SettingsOption(value: 50, label: '50 词/天'),
                        ],
                        onSelected: controller.updateDailyStudyTarget,
                      ),
                    ),
                    SettingsActionTile(
                      title: '新词复习比例',
                      value: '1:${settings.dailyReviewRatio}',
                      onTap: () => showSingleChoiceSheet<int>(
                        context,
                        title: '新词复习比例',
                        currentValue: settings.dailyReviewRatio,
                        options: const <SettingsOption<int>>[
                          SettingsOption(value: 1, label: '1:1'),
                          SettingsOption(value: 2, label: '1:2'),
                          SettingsOption(value: 3, label: '1:3'),
                          SettingsOption(value: 4, label: '1:4'),
                        ],
                        onSelected: controller.updateDailyReviewRatio,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SettingsGroup(
                  title: '学习提醒',
                  children: [
                    SettingsActionTile(
                      title: '学习提醒',
                      value: settings.reminderEnabled ? '已开启' : '已关闭',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              ReminderSettingsPage(controller: controller),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SettingsGroup(
                  title: '发音与显示',
                  children: [
                    SettingsActionTile(
                      title: '默认发音',
                      value:
                          settings.defaultPronunciation ==
                              DefaultPronunciation.uk
                          ? '英式'
                          : '美式',
                      onTap: () => showSingleChoiceSheet<DefaultPronunciation>(
                        context,
                        title: '默认发音',
                        currentValue: settings.defaultPronunciation,
                        options: const <SettingsOption<DefaultPronunciation>>[
                          SettingsOption(
                            value: DefaultPronunciation.uk,
                            label: '英式',
                          ),
                          SettingsOption(
                            value: DefaultPronunciation.us,
                            label: '美式',
                          ),
                        ],
                        onSelected: controller.updateDefaultPronunciation,
                      ),
                    ),
                    SwitchListTile(
                      title: const Text('自动发音'),
                      value: settings.autoPlayPronunciation,
                      onChanged: controller.updateAutoPlayPronunciation,
                    ),
                    SwitchListTile(
                      title: const Text('默认显示对话翻译'),
                      value: settings.showConversationTranslationByDefault,
                      onChanged: controller.updateShowConversationTranslation,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SettingsGroup(
                  title: '危险操作',
                  children: [
                    SettingsActionTile(
                      title: '清除学习进度',
                      onTap: () => _confirmClearProgress(context),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmClearProgress(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('清除学习进度'),
          content: const Text('此操作会清空你的单词熟悉度、收藏和笔记记录，确定继续吗？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('确定'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await controller.clearLearningProgress();
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('学习进度已清除')));
    }
  }
}
