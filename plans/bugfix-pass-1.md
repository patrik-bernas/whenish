# Bug Fix Brief: Timezone App — Post-Build QA Pass

Read `docs/design-brief.md` for the exact design spec. Read `docs/design-mockup-v4.jsx` as visual reference for what the app should look like.

The app builds and runs, but has several UI and logic bugs found during testing. Fix all of the following issues.

---

## Bug 1: No glass/translucent effect on popover
**What's wrong:** The popover has a solid dark gray background. It should be frosted glass — translucent, where you can see what's behind it.
**Fix:** The popover background must use SwiftUI's `.ultraThinMaterial` or `.regularMaterial`. Make sure the NSPopover's content view has a transparent background so the material effect shows through. You may need to set the popover's `NSVisualEffectView` or ensure the hosting view's background is clear. The glass effect is the core aesthetic of this app.

## Bug 2: Flags broken — wrong or missing
**What's wrong:** Some cities show wrong flags or no flags at all. New York shows a blue circle instead of a flag. Vienna should show 🇦🇹 (Austria). Honolulu should show 🇺🇸 (USA).
**Fix:** Review the `CitySearchService.swift` flag emoji mapping. Every city must have the correct country flag emoji. The flag should be rendered as plain emoji text at 20px in a 26px container. Make sure the flag mapping covers all common cities. Vienna = 🇦🇹, Honolulu = 🇺🇸, San Francisco = 🇺🇸, New York = 🇺🇸, etc.

## Bug 3: Home city flag overflows the popover boundary
**What's wrong:** The home city (New York) has a flag/📍 indicator that sits partially outside the popover border on the left side.
**Fix:** The home city's flag and 📍 indicator must stay fully inside the popover. The 📍 should be a small overlay on the bottom-right of the flag emoji, not a separate element that shifts layout. The subtle glow behind the home city should use a background modifier, not a separate positioned element that causes overflow. Add proper padding/clipping.

## Bug 4: Times not right-aligned
**What's wrong:** The time values (21:17, 18:17, 02:17, 15:17) are not vertically aligned. They appear at different horizontal positions on each row.
**Fix:** The time column must have a fixed width (min 70px) and be right-aligned. Use `.frame(minWidth: 70, alignment: .trailing)` or similar. Use `.monospacedDigit()` font modifier to ensure all digits have equal width. Every time value across all city rows must line up in a perfect vertical column.

## Bug 5: Timeline bars not consistent
**What's wrong:** The colored timeline bars between city names and times have inconsistent widths and positions across rows.
**Fix:** The timeline bar should be in a flex container that takes all available space between the name/offset column and the time column. Use a `Spacer()` or `.frame(maxWidth: .infinity)` approach so bars have consistent width regardless of city name length. The city name column should also have a fixed minimum width.

## Bug 6: Cities not sorted chronologically
**What's wrong:** Cities appear in the order they were added. They should be sorted by UTC offset from earliest to latest.
**Fix:** In the ViewModel or wherever the active group's cities are provided, sort them by their timezone's current UTC offset. Earliest offset (most behind, e.g. Honolulu -10) first, latest offset (most ahead, e.g. Vienna +1 relative to NYC) last. Re-sort whenever a city is added or removed. This means the display order for the test case should be: Honolulu, San Francisco, New York, Vienna.

## Bug 7: Current time display moves with slider
**What's wrong:** The time shown in the bottom-right of the slider area (e.g. "⏱ 21:17") changes when the slider is dragged. This should ALWAYS show the real current local time.
**Fix:** The current time display must be computed from `Date()` and the user's local timezone, completely independent of the scrubber offset. It is a fixed reference point showing "this is what time it actually is right now." Only the offset label on the left (e.g. "+3h from now") should change with the slider. The time on the right stays fixed.

## Bug 8: Timeline bar colors shift when scrubbing
**What's wrong:** When dragging the slider, the color segments on the per-city timeline bars move around. The colors should be FIXED — they represent each city's local time schedule (when they're sleeping, available, etc.), which doesn't change.
**Fix:** The timeline bar color segments must be statically positioned based on each city's timezone. They represent the 24-hour availability pattern for that city and should NEVER move. Only the vertical scrub line (the thin white line) should move when the slider is dragged. Think of it this way: the bar is a fixed map of the city's day, and the scrub line is a cursor moving across that map.

## Bug 9: Settings view layout broken
**What's wrong:** The Settings view has layout issues — "Time Format" text renders vertically (characters stacked), spacing is off, the overall layout looks unpolished.
**Fix:** Rebuild the SettingsView layout:
- Use a proper `VStack` with consistent padding (24px horizontal)
- "Time Format" row: label on the left, 12h/24h segmented picker on the right, single horizontal line
- "Home Timezone" section: label + search/picker field below it
- "Groups" section: list of group names with editable text fields, character count (e.g. "4/12")
- "< Back" button top-left, "Settings" title top-center
- Apply the same glass-tinted styling as the rest of the app (translucent card backgrounds)
- Test that everything fits within the 370px popover width without overflow or wrapping

## Bug 10: No "group full" message
**What's wrong:** When a group has reached its maximum number of cities (6), the user can still try to search and add. There's no feedback that the group is full.
**Fix:** When the active group has 6 cities and the user tries to add another, show a subtle inline message below the search bar like "Group is full (6/6)" in the secondary text color. Alternatively, disable the search results/add action and show the message. Do NOT silently fail.

---

## General Polish (while you're in there)

- Make sure all divider lines are 0.5px and inset 24px from edges
- Make sure the legend (Available · Heads up · Sleeping) has proper spacing at the bottom
- Make sure the menubar text uses a monospaced font and formats as `NYC 21:17` with middot separators
- Ensure the popover is exactly 370px wide with 22px corner radius
- Test with 1 city, 4 cities, and 6 cities to make sure layout scales properly

---

## How to verify
After fixing, build and run (`⌘R` in Xcode). Check:
1. Can you see your desktop through the popover? (glass effect)
2. Are all flags showing correct emoji?
3. Are all times in a perfect vertical column on the right?
4. Are cities sorted by timezone offset?
5. Does the bottom-right time stay fixed when scrubbing?
6. Do the timeline bar colors stay fixed when scrubbing?
7. Does Settings look clean with no text overflow?
8. Does "group full" message appear at 6 cities?
