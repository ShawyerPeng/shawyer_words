# Study Task Planning Design

**Goal:** Replace the current page-local "due review + new words" assembly with a dedicated planning system that can explain, prioritize, and pace daily vocabulary work.

## Current State

The current study flow builds a session directly inside [`/Users/shawyerpeng/develop/code/shawyer_words/lib/features/study_plan/presentation/study_home_page.dart`](/Users/shawyerpeng/develop/code/shawyer_words/lib/features/study_plan/presentation/study_home_page.dart) by:

- loading all knowledge records and FSRS cards for the selected book
- selecting all due cards up to a review limit
- filling the rest of the session with unseen words in book order
- concatenating review entries and new entries into a single list

This keeps the implementation simple, but it couples planning to UI code and leaves several product gaps:

- overdue reviews are only sorted by due time, not by risk
- new-word quota does not adapt smoothly to review backlog
- the session queue cannot explain why a word is present
- mastered words have no explicit low-frequency recheck path
- future modes such as "review first" or "sprint" have no domain layer to hook into

## Design Summary

Introduce a dedicated planner service that accepts the current study context and returns a fully structured daily plan.

The planner will:

- classify candidate work into `mustReview`, `normalReview`, `newWords`, `probeWords`, and `deferredWords`
- assign a priority score to review items using due age, stability, lapses, and retrievability
- derive `reviewBudget` and `newBudget` from settings plus backlog protection rules
- build a mixed execution queue so review and new words can be interleaved
- generate a machine-readable summary that the home page and statistics surfaces can reuse

FSRS remains the memory engine. This work changes scheduling policy, not the FSRS algorithm itself.

## Domain Model

Create the following domain objects under `lib/features/study_plan/`:

### `DailyStudyPlanRequest`

Single input object for the planner.

Fields:

- `OfficialVocabularyBook book`
- `List<WordEntry> bookEntries`
- `Map<String, FsrsCard> cardsByWord`
- `Map<String, WordKnowledgeRecord> knowledgeByWord`
- `AppSettings settings`
- `DateTime now`

### `PlannedStudyItem`

Represents a single item inside the final queue.

Fields:

- `WordEntry entry`
- `StudyTaskSource source`
- `double priorityScore`
- `List<StudyTaskReason> reasonTags`

### `DailyStudyPlan`

Structured planner output.

Fields:

- `List<PlannedStudyItem> mustReview`
- `List<PlannedStudyItem> normalReview`
- `List<PlannedStudyItem> newWords`
- `List<PlannedStudyItem> probeWords`
- `List<PlannedStudyItem> deferredWords`
- `List<PlannedStudyItem> mixedQueue`
- `DailyStudyPlanSummary summary`

### `DailyStudyPlanSummary`

Compact explanation object for UI and analytics.

Fields:

- `int reviewCount`
- `int newCount`
- `int probeCount`
- `int deferredCount`
- `StudyBacklogLevel backlogLevel`
- `String strategyLabel`
- `List<String> reasonSummary`

### Supporting enums

- `StudyTaskSource { mustReview, normalReview, newWord, probeWord }`
- `StudyTaskReason { overdue, lowStability, highLapseRisk, backlogProtected, freshWord, probeRecheck }`
- `StudyBacklogLevel { none, light, medium, heavy }`
- `StudyPlanningMode { balanced, reviewFirst, sprint }`

`StudyPlanningMode` is part of the full design, but only `balanced` needs to be wired in the first implementation pass.

## Planning Rules

### 1. Candidate classification

For the selected book:

- `mustReview`: due now or overdue, with elevated risk
- `normalReview`: due now or overdue, lower risk than `mustReview`
- `newWords`: in the book, not mastered, no FSRS card yet
- `probeWords`: mastered words eligible for low-frequency spot checks
- `deferredWords`: review or new candidates excluded by budget limits

First implementation pass:

- produce `probeWords` support in the model
- keep probe scheduling disabled by default

### 2. Review priority score

Score each review candidate with a weighted heuristic:

- larger overdue age => higher score
- lower `stability` => higher score
- higher `lapses` => higher score
- lower retrievability => higher score

This is intentionally a policy layer on top of FSRS. It answers "which due items matter most today?" rather than "when is the next due date?"

### 3. Backlog-aware budgeting

Base inputs already exist in settings:

- `dailyStudyTarget`
- `dailyReviewLimitMultiplier`

Planner derives:

- `reviewBudget`
- `newBudget`

Rules:

- all due reviews are scored before budget is applied
- light backlog reduces new-word quota, but does not remove it
- heavy backlog can reduce new-word quota to a very small number
- extreme backlog may pause new words entirely

Recommended first-pass behavior:

- `none`: full new quota
- `light`: about 75% new quota
- `medium`: about 50% new quota
- `heavy`: 0 to 3 new words depending on total backlog

### 4. Mixed queue pacing

The planner returns both categorized buckets and a final `mixedQueue`.

Recommended default pacing:

- balanced mode: `3 review : 1 new`
- review-first mode: `4 review : 1 new`
- sprint mode: `2 review : 1 new`

First implementation pass only needs balanced mode.

### 5. Mastered-word recheck

Current behavior marks `easy` items as known and skips future confirmation in [`/Users/shawyerpeng/develop/code/shawyer_words/lib/features/study/application/study_session_controller.dart`](/Users/shawyerpeng/develop/code/shawyer_words/lib/features/study/application/study_session_controller.dart).

The full design adds a future probe path:

- known words become probe-eligible after a cooldown window
- probe items enter a small daily probe budget
- failing a probe sends the word back into normal FSRS flow

This gives mastered words a maintenance cycle instead of permanent disappearance.

## Integration Points

### Home page

Replace the current session assembly inside [`/Users/shawyerpeng/develop/code/shawyer_words/lib/features/study_plan/presentation/study_home_page.dart`](/Users/shawyerpeng/develop/code/shawyer_words/lib/features/study_plan/presentation/study_home_page.dart) with:

1. collect study context
2. construct `DailyStudyPlanRequest`
3. call `DailyTaskPlanner.plan`
4. feed `mixedQueue` into the study session
5. optionally surface `summary.reasonSummary`

### Study session

The study session should continue to own review submission and FSRS persistence.

The planner does not mutate card state. It only selects and orders work.

In the first pass, `StudySessionPage` can still receive a flattened `List<WordEntry>` derived from `mixedQueue`. A follow-up refactor can upgrade the session layer to consume `PlannedStudyItem` directly for richer UI.

### Settings

The complete design expects a future `StudyPlanningMode` setting, but this does not need to ship in the first pass.

### Statistics

`DailyStudyPlanSummary` should eventually become the shared source for:

- today task counts on the home page
- backlog status
- deferred work indicators
- planning strategy labels

## Phased Delivery

### Phase 1: Daily planner extraction

Ship:

- planner models
- review risk scoring
- backlog-aware budgets
- mixed queue
- home-page integration
- planner tests

Defer:

- probe execution
- planning mode selection UI
- multi-book planning

### Phase 2: Long-term maintenance

Ship:

- probe eligibility
- probe budget
- mastered-word recheck lifecycle
- summary support for probe counts and backlog language

### Phase 3: User-visible strategy modes

Ship:

- `balanced`, `reviewFirst`, `sprint`
- settings integration
- statistics feedback by strategy

## Testing Strategy

Use TDD for all planner logic.

Primary test target:

- `test/features/study_plan/application/daily_task_planner_test.dart`

Required first-pass coverage:

- due reviews outrank new words
- heavy backlog reduces new-word budget
- known words and existing-card words do not re-enter the new-word pool
- mixed queue follows the expected review/new pacing
- deferred words are recorded when capacity is exceeded
- empty inputs produce an empty plan safely

Integration regression:

- update home-page tests to confirm the start-study flow uses planner output
- keep existing study-session persistence tests green

## Risks and Mitigations

### Risk: Planner becomes hard to explain

Mitigation:

- keep `DailyStudyPlanSummary.reasonSummary`
- keep the scoring heuristic simple and deterministic

### Risk: New words disappear for too long under backlog

Mitigation:

- preserve a small new-word floor except under extreme backlog

### Risk: Full mixed queue changes user pacing too abruptly

Mitigation:

- ship balanced mode first
- keep queue pacing fixed and predictable

### Risk: Future probe logic overcomplicates phase 1

Mitigation:

- model `probeWords` now
- keep probe scheduling disabled until phase 2

## Recommended Implementation Direction

Proceed with the full architecture, but only implement phase 1 immediately.

That yields the most important product win now:

- smarter daily workload selection
- safer backlog handling
- reusable planning logic
- a clean foundation for mastered-word rechecks and strategy modes later
