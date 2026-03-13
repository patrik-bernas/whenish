# Bug Fix Brief: Pass 2

Read `docs/design-brief.md` and `docs/design-mockup-v4.jsx` for visual reference.

---

## Bug 1: Max cities is wrong — capped at 4, should be 5
**What's wrong:** The app only allows 4 cities per group. It should allow 5. When the user tries to add a 6th, it should show a message.
**Fix:** Change the max cities per group from 4 to 5 everywhere in the codebase (TimezoneGroup model, ViewModel validation, any hardcoded limits). When a group already has 5 cities and the user searches and taps a result, show an inline message below the search bar: "Group is full (5/5)" in `rgba(255,255,255,0.35)`. The search should still work (so the user can see results) but tapping a result should not add it and should show the message.

## Bug 2: No group full feedback
**What's wrong:** When the max is reached and the user taps a search result, nothing happens. No feedback at all.
**Fix:** Related to Bug 1. Show "Group is full (5/5)" as an inline message below the search bar. The message should appear when the user taps a result while the group is full, and disappear when they clear the search or switch groups.

## Bug 3: Still no glass/translucent effect
**What's wrong:** The popover background is solid dark gray. This is the most important visual issue — the app should look like frosted glass where you can partially see through it.
**Fix:** This is likely an NSPopover configuration issue, not a SwiftUI issue. Try the following approach:
1. On the NSPopover itself, do NOT set a background color
2. In the AppDelegate where the popover is created, access the popover's contentViewController's view and set its layer to be transparent
3. The SwiftUI PopoverView should use `.background(.ultraThinMaterial)` on the outermost container
4. You may need to subclass NSPopover or use NSVisualEffectView as the base view of the popover's content
5. Try: set the NSPopover's `contentViewController.view.wantsLayer = true` and make the layer background clear, then let the SwiftUI material show through
6. If `.ultraThinMaterial` doesn't look right, try `.thinMaterial` or `.regularMaterial`
7. The key test: when the popover is open, can you partially see the desktop or windows behind it? If yes, it's working.

## Bug 4: New York flag shows a circle/badge instead of emoji
**What's wrong:** New York (the home city) renders the flag inside a blue circle or badge shape instead of as a plain emoji.
**Fix:** The home city flag should render as a plain emoji exactly like every other city — just 🇺🇸 text at 20px. The 📍 indicator should be a tiny overlay in the corner, NOT a container that wraps the flag. Remove any `Circle()`, `ZStack` with background shapes, or clipShape modifiers on the home city flag. The home city treatment should be: same emoji flag as everyone else + small 📍 at bottom-right + subtle glow BEHIND the row (not on the flag).

## Bug 5: Vienna shows EU flag instead of Austrian flag 🇦🇹
**What's wrong:** Vienna displays 🇪🇺 (EU flag) instead of 🇦🇹 (Austria flag).
**Fix:** In `CitySearchService.swift`, find the mapping for Vienna / "Europe/Vienna" and change the flag from 🇪🇺 to 🇦🇹. Also audit the entire flag mapping — any city in Europe should show its COUNTRY flag, not the EU flag. For example: Paris = 🇫🇷, Berlin = 🇩🇪, Rome = 🇮🇹, Vienna = 🇦🇹, Dublin = 🇮🇪, etc. The EU flag 🇪🇺 should never be used.

## Bug 6: Search bar needs a clear (×) button
**What's wrong:** When typing in the search bar, there's no way to quickly clear the text.
**Fix:** Add a small × button inside the search bar on the right side. It should only appear when there is text in the search field. Tapping it clears the search query and dismisses the search results dropdown. Style: `rgba(255,255,255,0.3)`, 12px, with a subtle hover brightening to 0.5.

## Bug 7: City name truncation — "San Francisco" becomes "San Franci..."
**What's wrong:** The city name column is inconsistent — sometimes it shows the full name, sometimes it truncates. Between two test runs, "San Francisco" appeared full in one and truncated in another.
**Fix:** The city name column should have a fixed width of 90px. Use `.lineLimit(1)` to prevent wrapping. If a name is too long, it should truncate with "..." consistently. BUT — the preferred fix is to make the name column wide enough for "San Francisco" (the longest common city name). Set min width to 100px. Test with: "San Francisco", "Kuala Lumpur", "Mexico City" to make sure they fit.

## Bug 8: Timeline bars still not properly aligned across rows
**What's wrong:** The colored bars between city names and times don't start and end at the same horizontal positions across all rows.
**Fix:** Use a strict layout grid. Each row should use the same fixed widths:
- Flag column: 36px (26px + 10px gap)
- Name/offset column: 100px fixed
- Timeline bar: flex (takes remaining space) — use `.frame(maxWidth: .infinity)`
- Time/date column: 75px fixed, right-aligned
- Menubar dot: 17px (7px dot + 10px gap)
- Remove ×: 20px
This ensures every row has identical column positions regardless of content.

## Bug 9: Settings — no group management functionality
**What's wrong:** The Settings view shows "Groups: Work 4/12" but there is no way to:
- Create a new group
- Rename a group
- Delete a group
- Add or manage groups beyond the default "Work"
**Fix:** Expand the Groups section in SettingsView:
- Show all existing groups (up to 3) as editable rows
- Each row: editable text field for the group name + character count (e.g. "4/12") + delete button (if more than 1 group exists)
- "Add Group" button below the list (only visible if fewer than 3 groups exist)
- When adding a new group, create it with a default name like "Group 2" or "Group 3"
- Enforce 12-character max on group names with visual feedback
- Deleting a group removes it and all its cities; if the active group is deleted, switch to the first remaining group
- Character count format: "Work 4/12" where 4 is current characters and 12 is the max

## Bug 10: Vertical scrub line too thick / not aligned with slider
**What's wrong:** In screenshot 2, the vertical scrub lines on the timeline bars appear as thick red lines, not the subtle 1px white line from the design.
**Fix:** The vertical scrub line on each timeline bar should be: 1px wide, `rgba(255, 255, 255, 0.45)`, 9px tall, with 1px border radius. It should be positioned exactly at the same x-percentage as the slider dot. Make sure there is no stroke or border being applied that makes it appear thicker. The color must be white/translucent, not red.

---

## After fixing all bugs, verify:
1. Can you see the desktop through the popover? (glass effect)
2. All flags are correct country emojis? (especially Vienna 🇦🇹, New York 🇺🇸 without circle)
3. Can add up to 5 cities, get "full" message on 6th attempt?
4. Search bar has × clear button?
5. City names don't truncate unexpectedly?
6. Timeline bars perfectly aligned across all rows?
7. Scrub lines are thin white, not thick red?
8. Settings allows creating, renaming, and deleting groups?
9. Group names enforce 12-char limit?
