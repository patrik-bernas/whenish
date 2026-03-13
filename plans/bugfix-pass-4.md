# Bug Fix Brief: Pass 4 — Final Polish

Read `docs/design-brief.md` and `docs/design-mockup-v4.jsx` for the approved design.

If you have access to the Paper MCP server, also read the design from this Paper file for visual reference: https://app.paper.design/file/01KKHYQHFRNV7EX0PDC3BVRM9D

---

## Bug 1: STILL no glass/translucent effect — THIS MUST BE FIXED

The popover is still solid dark gray. This has been requested in every pass and is the single most important visual issue.

The problem is likely that the NSPopover's content view or the NSHostingController has an opaque background that overrides the SwiftUI material.

Try this complete approach — replace the current popover setup in AppDelegate.swift:

```swift
// 1. Create the popover
let popover = NSPopover()
popover.behavior = .transient
popover.animates = true

// 2. Create SwiftUI content — do NOT apply .background material here yet
let contentView = PopoverView()
    .environmentObject(viewModel)

// 3. Use a custom NSViewController that uses NSVisualEffectView
let viewController = NSViewController()
let visualEffect = NSVisualEffectView()
visualEffect.material = .hudWindow  // or .popover, .menu, .sidebar
visualEffect.state = .active
visualEffect.blendingMode = .behindWindow
visualEffect.wantsLayer = true
visualEffect.layer?.cornerRadius = 18
visualEffect.layer?.masksToBounds = true

// 4. Add the SwiftUI hosting view on top
let hostingView = NSHostingView(rootView: contentView)
hostingView.translatesAutoresizingMaskIntoConstraints = false

// Make hosting view background transparent
hostingView.wantsLayer = true
hostingView.layer?.backgroundColor = .clear

visualEffect.addSubview(hostingView)
NSLayoutConstraint.activate([
    hostingView.topAnchor.constraint(equalTo: visualEffect.topAnchor),
    hostingView.bottomAnchor.constraint(equalTo: visualEffect.bottomAnchor),
    hostingView.leadingAnchor.constraint(equalTo: visualEffect.leadingAnchor),
    hostingView.trailingAnchor.constraint(equalTo: visualEffect.trailingAnchor),
])

viewController.view = visualEffect
popover.contentViewController = viewController

// 5. Set popover content size
popover.contentSize = NSSize(width: 380, height: 500)
```

Then in PopoverView.swift, remove any `.background(.ultraThinMaterial)` or solid background colors. The NSVisualEffectView behind it provides the glass. The SwiftUI view should have a CLEAR background so the glass shows through.

```swift
var body: some View {
    VStack(spacing: 0) {
        // all content...
    }
    .frame(width: 380)
    // NO .background() modifier — let the NSVisualEffectView show through
}
```

**Materials to try** (in order of most translucent to least):
- `.hudWindow` — most glass-like, similar to macOS HUD panels
- `.popover` — standard popover material
- `.menu` — menu-style glass
- `.sidebar` — sidebar material

**Test:** Open the popover with a colorful desktop wallpaper behind it. You should see the wallpaper colors bleeding through faintly.

---

## Bug 2: Popover should reset to main view when reopened

**What's wrong:** If the user opens settings, closes the popover by clicking outside, and reopens it, it still shows settings instead of the main time view.

**Fix:** In the ViewModel or AppDelegate, when the popover is about to show (or when it closes), reset `isSettingsOpen = false`. The best place is the popover's delegate method:

```swift
// In AppDelegate, set the popover delegate
popover.delegate = self

// Implement NSPopoverDelegate
extension AppDelegate: NSPopoverDelegate {
    func popoverWillClose(_ notification: Notification) {
        viewModel.isSettingsOpen = false
    }
}
```

This ensures every time the popover opens, it shows the main time view.

---

## Bug 3: Popover jumps position when switching groups

**What's wrong:** When switching between Work and Friends groups, the popover shifts horizontally because the menubar text changes width and the popover re-anchors.

**Fix:** Two things:
1. Set the status item to a fixed length that accommodates the longest possible menubar text:
```swift
statusItem.length = 220 // wide enough for 3 cities
```
2. Make sure the popover is shown relative to the status item's button and does not reposition on content changes. The popover should only position itself when first opened, not when its content updates.

---

## Bug 4: Menubar shows clock icon instead of times when switching groups

**What's wrong:** When switching groups, the menubar text briefly or permanently shows a clock icon instead of the city times.

**Fix:** The menubar text update logic probably falls back to the clock icon when `menubarCities` is momentarily empty during the group switch. Fix by:
1. Computing menubar cities across ALL groups, not just the active one. A city with `showInMenubar = true` should appear in the menubar regardless of which group is active.
2. If you must filter by active group, don't clear the menubar text during the transition — keep the previous text until the new group's data is ready.

---

## Bug 5: Settings cards have inconsistent margins

**What's wrong:** In the settings view, the light gray card backgrounds don't have equal left and right margins. The top card extends slightly further to the right than the others.

**Fix:** All settings cards should use identical padding:
```swift
VStack(alignment: .leading, spacing: 8) {
    // card content
}
.padding(14)
.background(Color.white.opacity(0.06))
.cornerRadius(12)
.padding(.horizontal, 18) // same horizontal padding for ALL cards
```

Make sure every card in the settings uses the same `.padding(.horizontal, 18)` — no card-specific overrides.

---

## Bug 6: Widen the popover and rebalance timeline bar space

**What's wrong:** The space between the city name and the timeline bar is smaller than the space between the timeline bar and the time. The overall widget feels squeezed.

**Fix:** 
1. Increase popover width to **380px** (from current ~360px)
2. Use these column widths:
   - Flag: 24px container + 8px gap
   - City name/offset: 95px fixed + 6px gap
   - Timeline bar: **flex (takes ALL remaining space)** — use `.frame(maxWidth: .infinity)`
   - Gap before time: 6px
   - Time/date: 68px fixed, right-aligned
   - Gap: 6px
   - Menubar dot: 6px + 6px gap
   - Remove ×: 14px
3. The timeline bar must expand to fill the middle. There should be roughly equal small gaps (6px) on both sides of the bar.
4. Horizontal padding: 20px on each side (total usable width: 340px)

---

## Bug 7: Vertical scrub lines on timeline bars are misaligned

**What's wrong:** Looking at the screenshot, the vertical scrub lines across the different city timeline bars don't form a perfectly straight vertical line.

**Fix:** All timeline bars must have exactly the same width and x-offset. Since the bar is in a flex container, make sure:
1. Every row uses the exact same layout structure (same Spacer/frame setup)
2. The scrub line position is calculated as a percentage of the bar width: `scrubLineX = (scrubberOffset + 24) / 48 * barWidth`
3. All bars use the same `barWidth` value — do not let it vary per row

---

## General sizing summary

```
Popover: 380px wide, 18px corner radius
Horizontal padding: 20px each side (340px usable)

Search bar row:    34px tall, 10px corner radius
Gap:               8px
Pills row:         26px tall
Gap:               6px
City row:          52px tall (fixed for ALL rows)
Divider:           0.5px
Slider section:    ~60px total
Legend:             ~24px total
Bottom padding:    10px
```

Total height with 5 cities: ~430px approximately

---

## After fixing, verify:
1. **Glass effect** — can you see your wallpaper through the popover? YES/NO — this is pass/fail
2. Popover always opens to main view, never settings
3. Popover doesn't jump when switching groups
4. Menubar always shows city times, never a clock icon during transitions
5. Settings cards have identical margins
6. Timeline bars are wider and centered between name and time
7. Vertical scrub lines form a straight line across all rows
8. Overall feel is compact and sleek, not tall and spaced out
