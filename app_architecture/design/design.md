# SmartSpace UI Design System

## Overview

SmartSpace is a community-oriented platform for reporting and monitoring environmental, infrastructure, and public safety issues.

The interface should communicate:

* **Trust** — users should feel that reports and information are handled reliably.
* **Clarity** — users should immediately understand what they can do and what is happening.
* **Calm** — avoid excessive visual noise, aggressive colors, or unnecessary animation.
* **Action-oriented** — reporting an issue should be quick, obvious, and require minimal interaction.
* **Community awareness** — the visual language should feel approachable and civic-minded rather than bureaucratic.
* **Accessibility** — information must remain understandable regardless of theme, device, or color perception.

The visual identity is based on **Teal + Green**, combining a sense of technology, trust, environmental awareness, and community responsibility.

The design must support both **Light Mode** and **Dark Mode** from the beginning.

Do not design Light Mode first and treat Dark Mode as an afterthought. Both themes must use intentional color roles and maintain appropriate contrast.

---

# Color System

## Brand Colors

### Primary

* **Primary:** `#00796B`
* **Primary Light:** `#26A69A`
* **Primary Dark:** `#004D40`

Primary represents the main SmartSpace brand color.

Use Primary for:

* Primary call-to-action buttons
* Active navigation items
* Selected states
* Important interactive elements
* Focus indicators
* Main progress indicators
* Important links when appropriate

Do not use Primary as a decorative color simply because it is the brand color.

### Secondary

* **Secondary:** `#558B2F`

Secondary represents environmental awareness, community, and positive ecological actions.

Use Secondary selectively for:

* Environmental-related highlights
* Supporting visual accents
* Secondary actions when appropriate
* Environmental categories
* Supporting illustrations or icons

Do not use Secondary as a replacement for semantic success states.

---

# Semantic Colors

Semantic colors communicate meaning rather than branding.

## Success

* **Light:** `#2E7D32`
* **Dark:** `#66BB6A`

Use for:

* Successfully submitted reports
* Completed operations
* Resolved reports
* Successful API operations
* Positive confirmation states

## Warning

* **Light:** `#F9A825`
* **Dark:** `#FFCA28`

Use for:

* Pending actions
* Warnings
* Attention-required states
* Temporary problems
* Reports requiring additional attention

## Error

* **Light:** `#C62828`
* **Dark:** `#EF5350`

Use for:

* Validation errors
* Failed operations
* Destructive actions
* Critical problems
* Rejected reports

## Info

* **Light:** `#1565C0`
* **Dark:** `#42A5F5`

Use for:

* Informational messages
* Explanatory UI
* System information
* Neutral status information

### Semantic Color Rule

Do not use semantic colors merely for decoration.

Do not use red or orange simply because a report concerns security, infrastructure, or an incident.

For example:

* Normal security report → Primary/Neutral
* Environmental report → Secondary/Primary
* Report pending review → Warning
* Report successfully submitted → Success
* Report rejected → Error
* Critical danger notification → Error

Semantic colors must communicate actual UI meaning.

---

# Light Theme

## Surfaces

* **Background:** `#F5F8F7`
* **Surface:** `#FFFFFF`
* **Surface Variant:** `#EEF4F2`
* **Input Background:** `#FFFFFF`

The application background should remain visually calm and slightly tinted rather than using pure white everywhere.

White may be used for cards, dialogs, navigation surfaces, and other elevated surfaces.

## Text

* **Text Primary:** `#17201E`
* **Text Secondary:** `#52615D`
* **Text Muted:** `#7A8783`
* **Text On Primary:** `#FFFFFF`

Avoid pure black (`#000000`) for normal text.

## Borders

* **Border:** `#D8E2DF`
* **Border Strong:** `#B8C9C4`
* **Divider:** `#E5ECEA`

Borders should remain subtle and should not visually dominate the content.

---

# Dark Theme

Dark Mode must not be implemented by simply inverting Light Mode colors.

Use dark surfaces with sufficient separation between background and elevated surfaces.

## Surfaces

* **Background:** `#0F1715`
* **Surface:** `#17211E`
* **Surface Variant:** `#1D2A26`
* **Input Background:** `#1A2522`

Avoid pure black (`#000000`) as the application background.

## Text

* **Text Primary:** `#E7EFEC`
* **Text Secondary:** `#B4C2BE`
* **Text Muted:** `#899A95`
* **Text On Primary:** `#FFFFFF`

## Borders

* **Border:** `#30403B`
* **Border Strong:** `#42554F`
* **Divider:** `#273631`

## Dark Mode Brand Colors

Primary colors should generally use brighter variants in Dark Mode to maintain visibility and contrast.

* **Primary:** `#26A69A`
* **Primary Strong:** `#4DB6AC`
* **Primary Dark Surface:** `#004D40`

Do not use `#00796B` indiscriminately on dark surfaces if contrast becomes insufficient.

---

# Theme Rules

* Every component must be visually valid in both Light and Dark Mode.
* Do not hardcode background colors directly inside widgets when a theme color is available.
* Do not hardcode text colors when a theme-aware text color is available.
* Prefer Flutter `ThemeData`, `ColorScheme`, and theme extensions where appropriate.
* Components must consume colors from the application's theme rather than defining their own arbitrary colors.
* Do not create a separate visual identity for Dark Mode. Dark Mode should remain recognizably SmartSpace.
* Dark Mode should reduce luminance and visual intensity rather than simply replacing every color with a darker version.
* Maintain readable contrast for primary text, secondary text, icons, borders, and interactive elements.
* Do not use color alone to communicate important information.

---

# Typography

Typography should prioritize readability and clarity over decorative styling.

## Font

Use the project's configured font consistently.

If no custom font has been explicitly defined, prefer a clean modern sans-serif font.

Avoid using multiple unrelated font families.

## Type Scale

Use a consistent scale based on the following values:

* **Display:** 40–48px
* **Headline:** 28–32px
* **Title:** 22–24px
* **Subtitle:** 18px
* **Body Large:** 16px
* **Body:** 14–15px
* **Body Small:** 13px
* **Caption:** 12px

The exact size may adapt responsively.

## Typography Rules

* Headings should have strong hierarchy.
* Body text should prioritize readability.
* Do not use excessive font weights.
* Prefer Regular, Medium, and Bold weights.
* Avoid using uppercase text for large blocks of content.
* Do not use typography purely as decoration.
* Important actions should be identifiable without requiring the user to read long descriptions.

---

# Spacing

Use a **4px base spacing unit**.

Preferred spacing values:

```text
4
8
12
16
20
24
32
40
48
64
80
96
```

Prefer these values instead of arbitrary values.

## Component Spacing

* Small internal spacing: `8px`
* Standard internal spacing: `12–16px`
* Large internal spacing: `20–24px`
* Section spacing: `32–48px`
* Major section spacing: `48–64px`

Spacing should create clear hierarchy and breathing room.

Do not compress unrelated content simply to fit more information on screen.

---

# Responsive Design

SmartSpace supports mobile and web interfaces.

## General Rules

* Mobile is the primary interaction context.
* Web layouts may display more information simultaneously but must preserve the same information hierarchy.
* Do not simply stretch mobile layouts to desktop.
* Desktop and mobile may use different compositions when appropriate.
* Keep the same visual language, colors, typography, and interaction semantics across platforms.

## Mobile

Prioritize:

* One-handed interaction
* Large touch targets
* Clear primary actions
* Minimal navigation complexity
* Easy access to report creation
* Readable text
* Minimal unnecessary information density

## Web

Prioritize:

* Efficient use of horizontal space
* Clear information hierarchy
* Tables/lists where appropriate
* Multi-column layouts where useful
* Persistent navigation when appropriate

Do not introduce desktop-only complexity simply because more screen space is available.

---

# Responsive Architecture

Responsive UI files are responsible only for selecting the appropriate platform/layout UI.

Preferred structure:

```text
Responsive Screen
    ↓
Mobile / Web UI
    ↓
Controller
    ↓
Service
    ↓
Repository
```

Responsive wrappers should remain simple and readable.

Do not pass UI state, controllers, `TextEditingController`, callbacks, or other runtime dependencies from the responsive wrapper into Mobile/Web UI constructors unless explicitly required by the task or architecture.

Mobile/Web UI should own the UI-specific dependencies and state it requires.

---

# Buttons

Buttons should clearly communicate action priority.

## Primary Button

* Filled Primary color
* White text
* Medium font weight
* Used for the main action of a section
* Example: `Gửi phản ánh`

## Secondary Button

* Transparent or surface background
* Primary-colored border/text
* Used for secondary actions

## Ghost Button

* No visible border
* No filled background
* Used for low-emphasis actions

## Destructive Button

* Error color
* Used only for destructive or irreversible actions

## Button Rules

* Do not place multiple visually dominant Primary buttons in the same small section.
* Use clear action labels.
* Avoid vague labels such as `OK`, `Submit`, or `Click here` when a more descriptive action is possible.
* Buttons must have sufficient touch area on mobile.
* Loading states should clearly communicate that an operation is in progress.
* Disabled buttons should remain distinguishable from enabled buttons without relying only on color.

---

# Forms and Inputs

Forms are an important part of the reporting workflow.

Inputs should prioritize clarity and ease of completion.

## Input Style

* Clear label
* Optional supporting description
* Visible input boundary
* Consistent padding
* Clear focus state
* Clear error state

Avoid relying exclusively on placeholder text as the field label.

## Validation

Validation errors should:

* Clearly identify the invalid field.
* Explain what is wrong.
* Provide actionable guidance when possible.
* Use both visual and textual indicators.

Do not use only a red border to communicate validation errors.

---

# Cards

Cards may be used to group related information.

Default card characteristics:

* Surface background
* Subtle border
* `12px` radius
* Minimal or no shadow at rest

Use cards for:

* Report summaries
* Report status
* Notifications
* Important information
* Grouped actions

Avoid placing every piece of information inside a card.

Cards should help establish hierarchy, not create unnecessary visual fragmentation.

---

# Status Indicators

Reports may have multiple states.

Recommended presentation:

* `Đã gửi` → Success
* `Đang xử lý` → Warning
* `Đã xử lý` → Success
* `Từ chối` → Error
* `Cần bổ sung thông tin` → Warning
* `Thông tin` → Info

Status indicators should include text.

Do not communicate status using color alone.

---

# Chips and Badges

Use chips for:

* Categories
* Filters
* Statuses
* Small pieces of metadata

Use rounded or moderately rounded shapes.

Do not use excessive pill-shaped elements throughout the interface.

Status chips must use semantic colors consistently.

---

# Navigation

Navigation should remain simple and predictable.

## Mobile

Prefer:

* Bottom navigation for primary destinations when appropriate.
* Drawer navigation for secondary destinations.
* Clear active state.
* Short labels.

## Web

Prefer:

* Persistent top or side navigation when appropriate.
* Clear active state.
* Consistent placement across screens.

Navigation should not compete visually with the main reporting action.

---

# Report Creation UI

The report creation workflow is one of the most important parts of the application.

The interface should prioritize:

1. Selecting the report type.
2. Capturing or uploading evidence.
3. Entering relevant information.
4. Selecting/confirming location.
5. Reviewing information.
6. Submitting the report.
7. Clearly communicating submission status.

The user should always understand:

* What step they are currently on.
* What information is required.
* What information is optional.
* Whether the report has been submitted successfully.

Avoid unnecessary animations, decorative elements, or complex interactions during the reporting process.

---

# Maps and Location

Maps should support the reporting workflow rather than dominate the interface.

Use the Primary color for:

* Selected locations
* Important location controls
* Active location states

Do not use large areas of Primary or Secondary color over the map unless required for data visualization.

Location information should remain readable in both themes.

---

# Icons

Use a consistent icon family throughout the application.

Rules:

* Icons should support understanding rather than act as decoration.
* Do not mix multiple unrelated icon styles.
* Important actions should preferably include both icon and text when ambiguity is possible.
* Icons should inherit semantic/theme colors where appropriate.
* Do not use color alone to communicate an icon's meaning.

---

# Elevation and Shadows

The interface should use restrained elevation.

## Light Mode

Prefer:

* Subtle borders
* Very soft shadows for elevated surfaces
* Minimal shadow on normal cards

## Dark Mode

Prefer:

* Surface color differences
* Borders
* Subtle elevation

Do not rely heavily on shadows in Dark Mode.

Avoid large, dramatic shadows.

Shadows should communicate hierarchy rather than decoration.

---

# Border Radius

Use a consistent radius system:

* `4px` — small badges, compact elements
* `8px` — buttons, inputs, small panels
* `12px` — cards, dialogs, larger surfaces
* `16px` — prominent containers or feature sections
* `9999px` — avatars, circular controls, pills when appropriate

Do not introduce arbitrary radius values without a clear reason.

---

# Motion and Animation

Animations should be subtle, purposeful, and short.

Use animation for:

* Navigation transitions
* State changes
* Loading feedback
* Expanding/collapsing content
* Success/error feedback

Avoid:

* Continuous decorative animations
* Excessive bouncing
* Large-scale transitions
* Animations that delay important actions
* Multiple simultaneous animations competing for attention

Recommended duration:

* Micro interaction: `100–150ms`
* Standard transition: `150–250ms`
* Larger transition: `250–350ms`

Animation should never be required to understand critical information.

---

# Loading States

Avoid blank screens during loading.

Prefer:

* Progress indicators
* Skeleton loading where appropriate
* Clear loading messages for long-running operations

Loading states should preserve the approximate layout of the final content when practical.

Do not animate skeletons excessively.

---

# Empty States

Empty states should explain:

1. What is empty.
2. Why it may be empty, when useful.
3. What the user can do next.

Example:

```text
Chưa có phản ánh

Bạn chưa gửi phản ánh nào.
Hãy tạo phản ánh đầu tiên khi phát hiện vấn đề.

[ Tạo phản ánh ]
```

Avoid decorative empty states that do not help the user understand what to do.

---

# Error States

Errors should be clear, calm, and actionable.

Use:

* Error color
* Clear message
* Appropriate icon
* Retry/action when possible

Avoid technical error messages such as raw exceptions, stack traces, or HTTP errors in the user-facing UI.

Example:

```text
Không thể gửi phản ánh

Đã xảy ra lỗi khi kết nối đến máy chủ.
Vui lòng kiểm tra kết nối và thử lại.

[ Thử lại ]
```

---

# Accessibility

Accessibility is a core requirement.

## Contrast

Maintain sufficient contrast between:

* Text and background
* Icons and background
* Interactive elements and their surroundings
* Status indicators and their backgrounds

Test both Light and Dark Mode.

## Color Independence

Never rely exclusively on color to communicate:

* Status
* Errors
* Success
* Warnings
* Categories
* Important actions

Combine color with text, icons, shapes, or other visual indicators.

## Touch Targets

Interactive mobile controls should have sufficiently large touch targets.

Avoid tiny buttons, icons, or links that are difficult to tap.

## Focus

Keyboard-accessible interfaces must have a clearly visible focus state.

---

# Dark Mode Guidelines

Dark Mode should feel like a natural extension of the SmartSpace visual identity.

Do:

* Use dark gray/green-tinted surfaces.
* Use brighter Primary colors for interactive elements.
* Preserve semantic meaning of colors.
* Maintain clear surface hierarchy.
* Reduce unnecessary visual contrast between large surfaces.

Do not:

* Use pure black as the entire background.
* Use pure white for large surfaces.
* Simply invert the Light Mode palette.
* Reduce contrast until text becomes difficult to read.
* Make every component heavily outlined.
* Increase saturation excessively just because the background is dark.

---

# Do's

* Use Teal as the primary visual identity.
* Use Green selectively to reinforce environmental/community concepts.
* Use semantic colors consistently.
* Maintain clear visual hierarchy.
* Keep reporting actions easy to find.
* Use neutral surfaces for most of the interface.
* Design Light and Dark Mode together.
* Follow the 4px spacing system.
* Reuse existing theme tokens instead of introducing arbitrary colors.
* Prefer simple and predictable interactions.
* Keep visual noise low.
* Use responsive layouts appropriate to the device.
* Use meaningful labels and status text.
* Preserve accessibility across both themes.

---

# Don'ts

* Don't use large areas of saturated Primary or Secondary color without a functional reason.
* Don't use red for normal reports simply because the report concerns security.
* Don't use warning colors as decorative accents.
* Don't rely only on color to communicate information.
* Don't hardcode arbitrary colors inside widgets.
* Don't create a separate unrelated visual style for Dark Mode.
* Don't use excessive gradients.
* Don't use excessive shadows.
* Don't use excessive animations.
* Don't add decorative elements that compete with the reporting workflow.
* Don't create unnecessarily complex navigation.
* Don't use tiny touch targets.
* Don't use placeholder text as the only field label.
* Don't expose raw technical errors to users.
* Don't stretch mobile layouts directly to desktop without considering information hierarchy.
* Don't introduce arbitrary spacing or radius values when an existing design token is appropriate.

---

# Design Priority

When design decisions conflict, prioritize in this order:

1. **Accessibility**
2. **Usability**
3. **Clarity**
4. **Trust and reliability**
5. **Consistency**
6. **Visual aesthetics**

A visually attractive solution should never be chosen if it makes the reporting workflow less clear or less accessible.

---

# Design Philosophy

SmartSpace should feel:

**Trustworthy, calm, clear, accessible, modern, and community-oriented.**

It should not feel:

**Overly corporate, bureaucratic, social-media-like, game-like, overly decorative, or visually aggressive.**

The interface exists to help users **notice, understand, report, and follow up on real-world issues**.

Design should always support that purpose.

---

# Theme Source of Truth

All UI implementations MUST follow `AI_SKILLS/design/design.md`.

`app_theme.dart` is the source of truth for application colors and theme tokens.

UI code must consume theme-defined colors instead of hardcoded colors.

Hardcoded colors such as `Colors.xxx`, `Color(0x...)`, `Color.fromARGB(...)`, or `Color.fromRGBO(...)` should not be used when an equivalent theme token exists.

Any newly required color must first be evaluated as a semantic design token. If a new token is necessary, it MUST be defined for both Light and Dark themes before being used by UI code.

Light and Dark versions of a color token do not need to have identical RGB values. They must instead preserve the intended semantic meaning and provide appropriate contrast for their respective surfaces.

---

# Theme Consistency

Mobile, Web, and other platform-specific UI implementations may have different layouts and compositions, but they MUST share the same application Design System and semantic color tokens.

Platform-specific UI must not introduce an independent color palette unless explicitly required by the design specification.

---

# Hardcoded Colors Rule

Before completing any UI implementation or UI refactor, inspect the modified UI files for hardcoded colors.

Search for patterns including:

* `Colors.*`
* `Color(...)`
* `Color.fromARGB(...)`
* `Color.fromRGBO(...)`
* hexadecimal color literals

Hardcoded colors are allowed only when there is a documented technical/design reason and no appropriate theme token exists.

If a recurring color is required, add it to the theme instead of duplicating it across widgets.

---

# Light/Dark Completeness

Every custom theme token MUST have both Light and Dark variants.

A new color must never be added to only one theme.

When adding a new color, evaluate:

1. Semantic purpose.
2. Light theme value.
3. Dark theme value.
4. Text/icon contrast.
5. Surface/background contrast.
6. Interactive states.
7. Disabled state if applicable.

Do not simply reuse the Light color in Dark Mode without verifying contrast and visual suitability.
