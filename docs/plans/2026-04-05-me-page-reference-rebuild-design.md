# Me Page Reference Rebuild Design

**Goal:** Rebuild the `我的` page to closely match the provided reference image while preserving all existing first-level entry points and navigation behavior.

## Context

The current `MePage` already acts as the app's account/settings hub, but its visual language is a generic stacked-card dashboard. The user wants the page restyled to match the supplied mobile reference with a strong emphasis on structural fidelity and visual polish. Functional scope stays unchanged: existing entries remain accessible and keep their current destinations.

## Product Scope

### 1. Header

Rebuild the top section to mirror the reference:
- large top breathing room
- avatar on the left
- prominent account name text
- subtle chevron affordance on the right

The current `登录` concept remains, but the visual presentation should feel like an account profile header rather than a utility card.

### 2. Three highlight cards

Use the three horizontally arranged cards from the reference as a visual shell for three existing first-level destinations:
- `词典库管理`
- `通用设置`
- `学习设置`

Each card should preserve:
- title
- light descriptive copy
- right-bottom count/value slot visual

The cards should differ in tone similarly to the reference: warm yellow, textured warm neutral, and cool white paper-like treatment.

### 3. Benefit banner

Map the existing `会员中心` entry into the reference's benefit banner block:
- left-side identity mark + short supporting text
- right-side dark pill CTA
- white rounded panel

### 4. Remaining grouped entries

Preserve all remaining first-level entries and place them into large grouped white cards modeled after the reference's lower list sections.

Recommended mapping:
- group A: `数据统计`
- group B: `帮助与反馈`

If spacing allows, include `会员中心` only in the banner and avoid duplicating it in the lower list.

### 5. Non-goals

This rebuild does not change:
- destination pages
- settings data structure
- account/auth logic
- bottom navigation behavior

## Visual Direction

Recreate these reference traits as closely as practical in Flutter:
- warm off-white page background
- very soft card shadows or near-shadowless white sections
- oversized radii
- dark brown-black primary text
- muted taupe-gray secondary text
- dark cocoa CTA pill
- generous vertical rhythm and calm grouping

Approximate textures and decorative effects may be recreated with gradients, border overlays, and shape composition rather than external image assets.

## Architecture

Primary implementation target:
- `lib/features/me/presentation/me_page.dart`

The page can remain self-contained. Introduce small private widgets inside the same file unless the file becomes unwieldy.

No route changes are required; only the page composition and styling should change.

## Testing Scope

Update `test/features/me/presentation/me_page_test.dart` to verify:
- all existing first-level entries are still present
- dictionary library management still opens
- help and feedback still opens
- tab-page bottom inset behavior remains correct

Prefer user-visible assertions over decoration-specific implementation details unless necessary for spacing regression coverage.
