# Bug Fix Brief: Pass 5 — Polish & Layout Fixes

Read `docs/design-brief.md` for reference.

---

## Bug 1: Menubar cities stack vertically instead of showing in a single row

**What's wrong:** When multiple cities are shown in the menubar, they stack on top of each other vertically instead of appearing in a single horizontal line like `HON 4:12 PM · SFO 7:12 PM · NYC 10:12 PM`.

**Fix:** The status item's button title must be a single-line string. Do NOT use newlines or attributed strings with line breaks. The menubar text should be built as one flat string:

```swift
let text = menubarCities.map { "\($0.abbr) \(formattedTime)" }.joined(separator: " · ")
statusItem.button?.title = text
```

Make sure there is no `\n` or line break character anywhere in the string. Also set the button's font explicitly:

```swift
statusItem.button?.font = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
```

Set the status item length to accommodate the text:
```swift
statusItem.length = NSStatusItem.variableLength
```

The text MUST appear as a single horizontal line in the macOS menubar. If it's too long, limit to showing 2-3 cities max in the menubar.

---

## Bug 2: Menubar takes up too much horizontal space

**What's wrong:** There is too much space between the menubar text and the other menubar icons (between the time text and things like the microphone icon, Wispr Flow, etc). The status item appears to have a fixed width that's too wide.

**Fix:** Use `NSStatusItem.variableLength` so the status item is only as wide as its text content. Remove any fixed width that was set in previous passes:

```swift
statusItem.length = NSStatusItem.variableLength
```

Also, use short time format in the menubar. For 12h format, use `4:12P` or `4:12 PM` but keep it compact. For 24h format, use `16:12`. Consider abbreviating AM/PM to just `a`/`p` or omitting it entirely in the menubar to save space.

---

## Bug 3: 12-hour format doesn't fit — times show as "4:12..."

**What's wrong:** When using 12-hour format, the time column is too narrow and times get truncated with "..." (e.g. "4:12..." instead of "4:12 PM").

**Fix:** The time column needs to be wider to accommodate 12h format. Two options:

**Option A (preferred):** Increase the time column fixed width from 68px to 82px. This fits "10:12 PM" comfortably. The popover width should be 390px to compensate.

**Option B:** Use a compact 12h format without the space: "4:12PM" or even "4:12pm" in a smaller font for the AM/PM part. This could fit in the existing column width.

Go with Option A. Update:
- Popover width: 390px
- Time column: 82px fixed, right-aligned
- Make sure `.lineLimit(1)` is set on the time text and it does NOT truncate

---

## Bug 4: "Group is full (5/5)" takes up too much space

**What's wrong:** The "Group is full" message sits as its own row below the search bar, eating up vertical space even when the user isn't trying to add a city.

**Fix:** Only show the message WHEN the user is actively trying to add a city. Specifically:
1. The message should NOT be visible by default
2. Show it only when: the user has typed something in the search bar AND the active group has 5 cities
3. Display it as a small inline label INSIDE the search results dropdown, at the top, before any results: "This group is full (5/5)" in `rgba(255,255,255,0.35)`, font size 11px
4. If the group is NOT full, don't show anything — just show search results normally
5. When the search bar is empty, the message disappears completely

This way it takes zero space during normal usage.

---

## Bug 5: Bottom spacing — legend too close to bottom edge, uneven gaps

**What's wrong:** The legend (Available · Heads up · Sleeping) is closer to the bottom of the popover than the gap between the -24h/+24h labels and the slider bar. The spacing is uneven.

**Fix:** Make all the vertical gaps in the slider area consistent:

```
[Last city row]
──────────────────── (0.5px divider)
4px gap
Now                           ⏱ 10:12 PM    ← offset/time row
4px gap  
[======= color bar with slider dot =======]  ← slider
4px gap
-24h                                  +24h   ← range labels
8px gap
● Available  ● Heads up  ● Sleeping         ← legend
8px gap (bottom padding — SAME as gap above legend)
```

The key rule: the space BELOW the legend to the popover bottom edge must equal the space ABOVE the legend to the range labels. Both should be 8px.

Also make sure the -24h and +24h labels are horizontally aligned with the edges of the slider bar (not with the edges of the popover).

---

## Bug 6: Glass effect — still not translucent

If the glass effect is still not working after pass 4's NSVisualEffectView approach, try this alternative:

```swift
// Instead of NSVisualEffectView, try setting the popover's appearance directly
popover.appearance = NSAppearance(named: .darkAqua)

// And in the SwiftUI view, use:
.background(.regularMaterial)
// wrapped in the popover's content
```

Or try the simplest possible approach:
```swift
// In PopoverView.swift
var body: some View {
    VStack(spacing: 0) {
        // all your content
    }
    .frame(width: 390)
    .background {
        Rectangle()
            .fill(.regularMaterial)
            .ignoresSafeArea()
    }
}
```

Try each material option: `.ultraThinMaterial`, `.thinMaterial`, `.regularMaterial`, `.thickMaterial`, `.ultraThickMaterial` — see which one gives the best frosted glass look.

If NONE of these work and the background is always opaque, it may be because the NSPopover itself clips the material. In that case, accept a semi-transparent dark background as a fallback:

```swift
.background(Color(white: 0.1, opacity: 0.85))
```

This at least looks better than solid dark gray, even if it's not true glass.

---

## Summary of width/sizing changes

```
Popover width:     390px (increased from 380)
Horizontal padding: 20px each side (350px usable)
Time column:       82px fixed (increased from 68px)
Everything else:   unchanged from pass 3
```

---

## After fixing, verify:
1. Menubar shows all cities in ONE horizontal line
2. Menubar doesn't take excessive horizontal space
3. 12h times display fully (e.g. "4:12 PM") without truncation
4. "Group is full" only appears when searching with a full group
5. Bottom spacing is symmetrical around the legend
6. Glass effect — any improvement at all?
