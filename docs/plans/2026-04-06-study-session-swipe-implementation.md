# Study Session Swipe Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 为学习会话页增加 Tinder 式左右滑卡，左滑判定忘记，右滑判定认识，未过阈值回弹。

**Architecture:** 在 `StudySessionPage` 内为主卡增加局部拖拽和飞出动画状态，动画完成后复用现有 `_handleDecision()` 执行判定。通过 widget test 锁定左右滑与回弹行为，不修改 `StudySessionController` 的评分逻辑。

**Tech Stack:** Flutter, widget test, AnimatedBuilder/GestureDetector, existing StudySessionController

---

### Task 1: 补充滑动交互测试

**Files:**
- Modify: `test/features/study/presentation/study_session_page_test.dart`

**Step 1: 写失败测试**

- 新增右滑主卡触发 `StudyDecisionType.known`
- 新增左滑主卡触发 `StudyDecisionType.forgot`
- 新增短距离拖拽不触发任何判定

**Step 2: 运行定向测试确认失败**

Run: `flutter test --no-pub test/features/study/presentation/study_session_page_test.dart`

Expected: 新增滑动相关断言失败，因为当前主卡没有拖拽判定能力。

### Task 2: 实现主卡左右滑动

**Files:**
- Modify: `lib/features/study/presentation/study_session_page.dart`

**Step 1: 为主卡增加拖拽状态**

- 添加位移、旋转、飞出方向等局部状态
- 增加左右滑阈值判断

**Step 2: 实现拖拽与飞出动画**

- 拖拽时更新卡片偏移和旋转
- 松手后根据位移决定回弹或飞出
- 飞出结束后调用 `_handleDecision()`

**Step 3: 增加方向提示**

- 左滑显示“忘记”
- 右滑显示“认识”

**Step 4: 保持现有按钮逻辑**

- `_isSubmitting` 时禁用滑动
- `模糊` 与 `标记熟悉` 保持现有点击路径

### Task 3: 验证并清理

**Files:**
- Modify: `lib/features/study/presentation/study_session_page.dart`
- Modify: `test/features/study/presentation/study_session_page_test.dart`

**Step 1: 运行定向测试**

Run: `flutter test --no-pub test/features/study/presentation/study_session_page_test.dart`

Expected: PASS

**Step 2: 运行相关 analyze**

Run: `flutter analyze lib/features/study/presentation/study_session_page.dart test/features/study/presentation/study_session_page_test.dart`

Expected: No issues found
