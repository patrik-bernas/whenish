# Feature Brief: Pass 11 — Column View Toggle

This is a NEW FEATURE, not a bugfix. We are adding an alternative "column" layout alongside the existing "row" layout, with a toggle to switch between them.

Read `docs/design-brief.md` for the overall aesthetic (dark glass, muted colors, etc).

---

## Overview

The app currently shows cities as horizontal rows. We are adding a second layout: vertical columns. A toggle in the UI lets the user switch between the two views.

**Row view** = current layout. Cities as rows, vertical scrub line, horizontal slider at bottom.
**Column view** = NEW. Cities as columns side by side, horizontal scrub line, drag up/down to scrub time.

---

## Step 1: Fix the row view first

Before adding the column view, make sure the existing ROW view is working correctly:
- Cities displayed as horizontal rows (flag, name, offset, timeline bar, time, date, menubar dot, remove)
- A continuous vertical scrub line running from the slider through all timeline bars
- Horizontal slider at the bottom with the draggable dot
- All existing functionality intact (search, groups, pills, etc)

If the row view got broken during pass 10, restore it to the state it was in at the end of pass 9, then add the continuous vertical scrub line properly.

---

## Step 2: Add the view toggle

Add a small toggle button in the top bar, between the search bar and the 📍 / 24h buttons:

### Top bar layout:
```
[ 🔍 Add city...        ] [ ☰/▥ ] [ 📍 ] [ 24h ]
```

The toggle button:
- Shows **☰** (horizontal lines icon) when currently in row view — tap to switch to columns
- Shows **▥** (vertical columns icon) when currently in column view — tap to switch to rows
- Use SF Symbols: `list.bullet` for row view, `chart.bar.fill` for column view
- Same button style as 📍 and 24h: 30×30px, glass background, rounded 8px
- Animate the transition between views with a subtle crossfade

Store the preference in AppSettings so it persists across restarts.

---

## Step 3: Build the Column View

### Layout structure (top to bottom):

```
[ Search bar ] [ ☰/▥ ] [ 📍 ] [ 24h ]
[ Work ] [ Friends ] [ Travel ] [ + ]

  🇺🇸      🇺🇸      🇺🇸      🇦🇹      🇯🇵
  HON     SF      NYC     VIE     TOK
  -5h     -3h     You     +6h    +14h

  ┌───┐  ┌───┐  ┌───┐  ┌───┐  ┌───┐
  │RED│  │RED│  │RED│  │YEL│  │GRN│
  │RED│  │RED│  │YEL│  │GRN│  │GRN│
  │YEL│  │YEL│  │GRN│  │GRN│  │GRN│  
  │GRN│  │GRN│  │GRN│  │YEL│  │YEL│  ← green overlap = best time
  │GRN│  │GRN│  │YEL│  │RED│  │RED│
  │YEL│  │YEL│  │RED│  │RED│  │RED│
  └───┘  └───┘  └───┘  └───┘  └───┘

  ════════════════●══════════════════  ← horizontal scrub line (drag up/down)
  5:40a   7:40a  10:40a  4:40p  12:40a

  +0.75h from now              ⏱ 10:40 AM

  ● Available  ● Heads up  ● Sleeping
```

### Column header (per city):
- Flag emoji centered (18px)
- Abbreviated city name centered below: max 3-4 characters, font 11px, weight .medium
  - Use abbreviations: Honolulu → HON, San Francisco → SF, New York → NYC, Vienna → VIE, Tokyo → TYO
  - Truncate with "..." only if needed
- Offset label below: font 9px, `rgba(255,255,255,0.3)`
- Home city: slightly brighter name, "You" instead of offset

### Column bars:
- Each column is a vertical color bar representing that city's 24-hour cycle
- The bar runs from top to bottom covering the full 48-hour range (±24h)
- Width per column: divide available space equally among cities (with 6px gaps between)
- Bar corner radius: 4px on all corners
- Colors: same as row view (green = available, yellow = heads up, red = sleeping)
- The colors are FIXED — they represent the city's local time schedule and don't move

### Horizontal scrub line:
- A horizontal line that runs across ALL columns at the same y-position
- Width: full width of the column area
- Height: 1.5px
- Color: `rgba(255, 255, 255, 0.4)`
- **Draggable up and down** via DragGesture
- Dragging the line changes the scrub offset (same -24h to +24h range)
- The line has a small handle/dot where the user grabs it:
  - White circle, 16px diameter, centered on the line
  - Same shadow style as the row view's slider dot

### Time labels (below columns):
- Below each column, show the time at the scrub line's position for that city
- Font: 11px, weight .light, tabular nums
- For 12h format: show "5:40a" or "4:40p" (abbreviated AM/PM) to save space
- These update in real-time as the scrub line moves

### Bottom section:
- Offset label (left): same as row view (e.g. "+0.75h from now")
- Current time (right): same as row view (e.g. "⏱ 10:40 AM")
- Legend: same as row view

---

## Step 4: Column view interactions

### Dragging the scrub line:
- The scrub line moves vertically through the columns
- As it moves, the time labels below each column update
- The offset label updates
- Movement range: top of columns (= -24h) to bottom of columns (= +24h)
- Center of columns = Now

### "Now" marker:
- A faint horizontal line at the center of the columns (the "Now" position)
- Same indigo color as the row view's now marker: `rgba(167, 180, 255, 0.4)`
- Visible only when the scrub line is dragged away from center
- Hidden when at center (same behavior as row view)

### Tapping the current time (⏱ 10:40 AM):
- Resets the scrub line to the center (Now position)
- Same as row view

### Removing a city:
- In column view, show a small × at the top-right corner of each column header (above the flag)
- Visible on hover over the column
- Tapping removes the city

### Menubar toggle:
- In column view, tapping a column header (flag area) toggles the menubar dot for that city
- Show the small dot indicator below the offset label:
  - Indigo glow = shown in menubar
  - Dim gray = hidden from menubar

### Adding a city:
- The search bar works the same as in row view
- New cities appear as new columns

---

## Step 5: Column sizing

### With 5 cities in a 390px popover:
- Horizontal padding: 20px each side → 350px usable
- Gaps between columns: 6px × 4 = 24px
- Available for columns: 326px ÷ 5 = ~65px per column

### With fewer cities:
- Columns should NOT stretch to fill the full width
- Max column width: 65px
- Center the columns if there's extra space
- This way the view looks consistent whether you have 2 or 5 cities

### Column bar height:
- The vertical bars should be tall enough to clearly see the color zones
- Minimum height: 200px
- The popover height will increase in column view compared to row view — that's fine
- Set a fixed height of 220px for the column bar area

---

## Step 6: Transition animation

When toggling between row and column view, use a smooth crossfade:

```swift
.transition(.opacity.combined(with: .scale(scale: 0.98)))
.animation(.easeInOut(duration: 0.25), value: viewModel.isColumnView)
```

The search bar, pills, bottom section (offset, time, legend) stay the same in both views — only the city display area changes.

---

## What stays the same in both views:
- Search bar + 📍 + 24h toggle (just add the view toggle button)
- Group pills row
- Bottom section (offset label, current time, legend)
- All existing functionality (add/remove cities, groups, home city, etc)

## What changes between views:
- City display: rows ↔ columns
- Scrub direction: horizontal slider ↔ vertical draggable line
- Time labels: inline in rows ↔ below columns

---

## After implementing, verify:
1. Toggle button switches between row and column views
2. Row view still works exactly as before (with continuous vertical scrub line)
3. Column view shows cities as vertical colored bars side by side
4. Horizontal scrub line drags smoothly up and down through columns
5. Time labels below each column update when scrubbing
6. Green overlap zones are clearly visible across adjacent columns
7. Works with 1, 2, 3, 4, and 5 cities
8. Search, groups, pills all work in both views
9. View preference persists across restarts
10. Smooth crossfade animation between views
