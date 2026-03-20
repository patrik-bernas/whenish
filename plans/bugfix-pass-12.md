# Bug Fix Brief: Pass 12 — Column View Polish

---

## Bug 1: Current time display is wrong

**What's wrong:** The time in the bottom right (e.g. "⏱ 09:06") doesn't show the correct current time. It should always show the real current time in the user's home timezone (e.g. New York).

**Fix:** The current time display must be computed from `Date.now` formatted in the home timezone. It should update every minute via a timer but must NEVER be affected by the scrubber position. This applies to BOTH the row view and column view:

```swift
var currentTimeString: String {
    let formatter = DateFormatter()
    formatter.timeZone = homeTimeZone
    formatter.dateFormat = settings.use24HourFormat ? "HH:mm" : "h:mm a"
    return formatter.string(from: Date())
}
```

Also fix the offset label on the left — it should show the scrubber's offset from NOW, not from some other reference point.

---

## Bug 2: Column bars are too thick — make them half the width

**What's wrong:** The column bars are too wide/chunky. They need to be slimmer for a more elegant look.

**Fix:** Reduce the column bar width by half. With 5 cities in 350px usable space:

- Current: ~65px per column
- New: ~30-32px per column bar width
- Keep the 6px gaps between columns
- Center each bar within its column's header area (the flag and name can be wider than the bar)

```
     🇺🇸          🇺🇸          🇺🇸          🇦🇹          🇯🇵
    HON         SF          NYC         VIE         TYO
    Same        +3h         You         +11h        +19h

    ┌──┐       ┌──┐       ┌──┐       ┌──┐       ┌──┐
    │  │       │  │       │  │       │  │       │  │
    │  │       │  │       │  │       │  │       │  │
    │  │       │  │       │  │       │  │       │  │
    └──┘       └──┘       └──┘       └──┘       └──┘
```

The bars are slim pillars with generous space between them. The column headers (flag, name, offset) remain at the wider spacing — only the colored bars themselves get thinner.

Bar corner radius: 4px (keep as is, or reduce to 3px if it looks better on the slimmer bars).

---

## Bug 3: Scrub line (horizontal drag line) needs to be thicker and more visible

**What's wrong:** The horizontal line you drag up and down to scrub through time is too thin and hard to see.

**Fix:** Make the scrub line:
- **Height: 2.5px** (up from 1.5px)
- **Color: `rgba(255, 255, 255, 0.6)`** (up from 0.4 — brighter)
- The line should extend across the full width of the column area
- The drag handle dot stays 16px white circle with shadow

The line should be clearly visible cutting across all the colored bars. It's the primary interaction element so it needs to stand out.

---

## Bug 4: "Now" reference line needs to be thicker and use indigo color

**What's wrong:** The thin line indicating the current time ("Now" position) is barely visible.

**Fix:** Make the "now" reference line:
- **Height: 2px**
- **Color: `rgba(167, 180, 255, 0.5)`** — same indigo/purple color as the current time display in the bottom right
- Only visible when the scrub line has been dragged away from the "now" position
- Hidden when the scrub line is at center (same behavior as before)

This indigo color should be consistent everywhere "now" is referenced:
- The now marker line in column view → indigo
- The now marker line in row view → indigo  
- The current time text (⏱ 09:06) → indigo
- These should all be the same `rgba(167, 180, 255)` at varying opacities

---

## Bug 5: Add a "current time" marker on each column bar

**What's wrong:** There's no indicator on each individual column bar showing where "now" is for that specific city.

**Fix:** On each column bar, add a small horizontal tick mark showing the current time position for that city:

- A short horizontal line or dash on the bar at the y-position corresponding to "now"
- **Width: the full width of that column bar** (so it spans the bar like a stripe)
- **Height: 2px**
- **Color: `rgba(167, 180, 255, 0.6)`** — same indigo as the now reference line
- Always visible (unlike the full-width now reference line which hides when scrub is at center)
- This marker is FIXED — it doesn't move when you scrub. It shows "this is where right now is on this city's timeline"

This helps the user see: "okay, Tokyo is currently in the green zone, Vienna is currently at the edge of yellow" etc.

Also apply this to the ROW view: on each city's horizontal timeline bar, add a small vertical tick mark at the "now" position in indigo. This is separate from the white scrub line — the indigo mark stays fixed at "now" while the white scrub line moves.

```swift
// In each column bar:
// Calculate the y-position of "now" on this bar
let nowY = calculateNowPosition(for: city.timeZone, barHeight: barHeight)

Rectangle()
    .fill(Color(red: 167/255, green: 180/255, blue: 255/255).opacity(0.6))
    .frame(width: barWidth, height: 2)
    .offset(y: nowY)
```

---

## Summary of line styles in column view:

| Line | Width/Height | Color | Behavior |
|------|-------------|-------|----------|
| Scrub line (drag) | 2.5px tall, full width | white 60% | Moves with drag |
| Now reference line | 2px tall, full width | indigo 50% | Fixed at center, hidden when scrub is there |
| Per-bar now marker | 2px tall, bar width | indigo 60% | Fixed at each city's "now" position, always visible |

---

## Bug 6: Honolulu (and other US cities) showing wrong flag

**What's wrong:** Honolulu shows a non-US flag. This is a recurring issue — the flag mapping is still broken for some cities.

**Fix:** This was addressed in pass 6 with a comprehensive timezone-to-country mapping. If that mapping isn't being used, re-implement it. Specifically verify these cities have correct flags:
- Honolulu → 🇺🇸
- San Francisco → 🇺🇸
- New York → 🇺🇸
- Chicago → 🇺🇸
- Los Angeles → 🇺🇸
- Athens → 🇬🇷
- Vienna → 🇦🇹
- Dublin → 🇮🇪

The `flagEmoji(for countryCode:)` function using Unicode regional indicators should be the ONLY way flags are generated. Double-check that every timezone identifier maps to the correct ISO country code.

---

## Bug 7: Show date labels (Yesterday/Today/Tomorrow) below times in column view

**What's wrong:** The column view shows times below the bars but doesn't show the date context (Yesterday/Today/Tomorrow) like the row view does.

**Fix:** Below each time label under the column bars, add the same date label we use in row view:

```
  00:21     03:21     06:21     11:21     19:21
  Today     Today     Today     Today    Tomorrow
```

- "Today" in `rgba(255,255,255,0.2)`, 8px font
- "Tomorrow" / "Yesterday" in `rgba(167, 180, 255, 0.55)`, 8px font, weight .medium
- Always visible (prevents layout shift, same logic as row view)

---

## Bug 8: Time labels below bars need bigger font

**What's wrong:** The time labels underneath the column bars are too small compared to the row view's time display.

**Fix:** Increase the time font size below the columns:
- Time: **14px**, weight .light, tabular nums (up from 11px)
- For 12h format: "5:40" in 14px + "AM" in 9px (same small AM/PM treatment as row view)
- Date label below: 8px

---

## Bug 9: Show full city names instead of abbreviations

**What's wrong:** Column headers show abbreviated names (HON, SF, NYC). Use full names where possible.

**Fix:** Show the full city name in the column header. Allow up to two lines if needed:

```swift
Text(city.name)
    .font(.system(size: 10, weight: .medium))
    .foregroundColor(.white.opacity(0.85))
    .lineLimit(2)
    .multilineTextAlignment(.center)
    .frame(width: 65) // wider than the bar to allow full names
```

For the column header area, use a wider frame (65px) even though the bar itself is 30px. This gives room for names like "San Francisco" to wrap to two lines:

```
       🇺🇸
      San
   Francisco
      -3h
     ┌──┐
     │  │
```

Short names like "Tokyo" stay on one line. The header area is always the same height regardless (use a fixed height of ~45px for the name section to prevent shifting).

If a name is extremely long and still doesn't fit in two lines at 10px on 65px width, truncate with "...".

---

## After fixing, verify:
1. Bottom-right time shows the correct current time in home timezone
2. Column bars are noticeably slimmer (about half previous width)
3. Scrub line is clearly visible as you drag it up/down
4. Now reference line is indigo and easy to spot
5. Each column bar has a small indigo marker showing where "now" is
6. In row view, each timeline bar also has an indigo "now" tick mark
7. All indigo elements use the same color family
8. Honolulu shows 🇺🇸, Athens shows 🇬🇷, Vienna shows 🇦🇹
9. Date labels (Today/Tomorrow/Yesterday) appear below times in column view
10. Time labels below columns are 14px (clearly readable)
11. Full city names shown (e.g. "San Francisco" wraps to two lines)
12. Column headers have consistent height regardless of name length
