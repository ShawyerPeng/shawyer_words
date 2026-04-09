# Study Session Redesign Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 重构学习会话页 UI 与反馈体验，同时保持现有学习推进与统计逻辑不变。

**Architecture:** 在 `StudySessionPage` 内重组视图层，新增顶部进度区、主卡片区、操作区和完成态卡片；尽量复用现有 `StudySessionController` 状态，避免改动算法逻辑。测试以 widget 回归为主，覆盖关键文案、进度和完成态。

**Tech Stack:** Flutter, Material 3, Widget tests

---

### Task 1: 锁定会话页 UI 结构测试

**Files:**
- Modify: `test/features/study/presentation/study_session_page_test.dart`

**Step 1: Write the failing test**

- 新增或调整断言，覆盖：
  - 顶部进度文本/进度条
  - 来源标签
  - 新的完成态摘要文案

**Step 2: Run test to verify it fails**

Run: `flutter test --no-pub test/features/study/presentation/study_session_page_test.dart`

**Step 3: Write minimal implementation**

- 暂不实现，先确认测试因 UI 未更新而失败

**Step 4: Run test to verify it passes**

- 在完成 Task 2 后统一回跑

### Task 2: 重构学习会话页视图

**Files:**
- Modify: `lib/features/study/presentation/study_session_page.dart`

**Step 1: Implement top/session/card/actions/completed layout**

- 新增会话头部
- 新增进度条与统计提示
- 调整单词主卡样式
- 重做底部按钮布局和完成态卡片

**Step 2: Keep behavior stable**

- 继续使用现有 `controller.markForgot / markFuzzy / markKnown / markMastered`
- 保持 “查看完整释义” 和详情页跳转

**Step 3: Run test to verify it passes**

Run: `flutter test --no-pub test/features/study/presentation/study_session_page_test.dart test/features/study/presentation/study_screen_test.dart`

### Task 3: 定向验证

**Files:**
- Modify: `lib/features/study/presentation/study_session_page.dart`
- Test: `test/features/study/presentation/study_session_page_test.dart`
- Test: `test/features/study/presentation/study_screen_test.dart`

**Step 1: Run analyzer**

Run: `flutter analyze lib/features/study/presentation/study_session_page.dart test/features/study/presentation/study_session_page_test.dart test/features/study/presentation/study_screen_test.dart`

**Step 2: Run widget tests**

Run: `flutter test --no-pub test/features/study/presentation/study_session_page_test.dart test/features/study/presentation/study_screen_test.dart`

**Step 3: Inspect final diff**

Run: `git diff -- lib/features/study/presentation/study_session_page.dart test/features/study/presentation/study_session_page_test.dart test/features/study/presentation/study_screen_test.dart`
