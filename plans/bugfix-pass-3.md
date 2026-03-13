# Bug Fix Brief: Pass 3 — Design Fidelity

This pass is ONLY about making the app visually match the approved design. Read `docs/design-mockup-v4.jsx` — this React component IS the design spec. Match it as closely as possible in SwiftUI.

Also read `docs/design-brief.md` for exact color values, font sizes, and spacing.

---

## CRITICAL: Glass transparency effect

This is the #1 priority. The popover currently has a solid dark gray background. It MUST be translucent frosted glass.

The issue is almost certainly in how the NSPopover is set up in AppDelegate.swift. Here is the exact approach that works for macOS glass popovers:

```swift
// In AppDelegate, when creating the popover:
let popover = NSPopover()
popover.behavior = .transient
popover.animates = true

// Create the SwiftUI view
let contentView = PopoverView()
    .environmentObject(viewModel)

// Create a hosting controller
let hostingController = NSHostingController(rootView: contentView)

// CRITICAL: Make the hosting controller's view transparent
hostingController.view.wantsLayer = true
hostingController.view.layer?.backgroundColor = .clear

popover.contentViewController = hostingController
```

Then in PopoverView.swift, the outermost container should be:

```swift
ZStack {
    // Your content here
}
.frame(width: 350)
.background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18))
```

Do NOT wrap the material in another opaque background. Do NOT set any solid background color on the popover or its content view. The material must be the only background.

If `.ultraThinMaterial` still looks solid, try `.thinMaterial` or `.regularMaterial`. The test: can you see your desktop wallpaper or other windows faintly through the popover?

---

## Layout overhaul — the popover is too tall and too spaced out

The current layout has way too much vertical padding between elements. Here are the EXACT measurements to use. These are tight — match them precisely:

### Overall popover
- **Width: 350px** (not 370 — slightly narrower for a more compact feel)
- **Corner radius: 18px**
- **Top padding: 14px**
- **Bottom padding: 12px**
- **Horizontal padding: 18px**

### Search bar
- **Height: 34px**
- **Corner radius: 10px**
- **Internal padding: 8px horizontal**
- **Gap to gear button: 8px**
- **Gear button: 30×30px**

### Gap from search bar to group pills: 10px (NOT 14px or more)

### Group pills
- **Height: 26px**
- **Pill horizontal padding: 12px**
- **Gap between pills: 5px**
- **Font size: 11px**

### Gap from pills to first city row: 8px

### City rows — this is the most important part
- **Row height: FIXED 56px for all rows regardless of content**
- **Vertical padding per row: 8px top, 8px bottom**
- **City name: single line, truncate with ... if too long, never wrap to two lines**
- **City name column: 90px fixed width**
- **Flag: 18px font size in a 24px container**
- **Timeline bar: takes ALL remaining space (flex/maxWidth: .infinity), height 3px**
- **Time: 20px font size, weight .light, right-aligned in a 65px fixed column**
- **Date label: 9px, always visible, 12px fixed height**
- **Menubar dot: 6px diameter**
- **Remove ×: 10px font**
- **Divider: 0.5px (use a thin Rectangle of height 0.5), color rgba(255,255,255,0.06), inset 18px from edges**

### Gap from last city row to slider area: 4px

### Slider area
- **Offset label + current time row: 10px font**
- **Gap to slider bar: 6px**
- **Slider bar height: 5px**
- **Slider dot: 16px diameter**
- **Gap to range labels: 4px**
- **Range labels: 9px font**

### Gap from slider to legend: 4px

### Legend
- **Dot size: 5px**
- **Font size: 9px**
- **Bottom padding: 10px**

---

## Popover positioning — must not jump around

**What's wrong:** When cities are added/removed from the menubar display, the popover shifts position because the menubar text width changes and the popover anchors to the status item.

**Fix:** The popover should always appear anchored to the status item's button. The status item should have a FIXED width so that adding/removing menubar cities doesn't change its position. Set a fixed width on the status item:

```swift
statusItem.length = NSStatusItem.variableLength
// OR set a fixed length if the jumping is too much:
// statusItem.length = 200
```

If using variable length, the popover anchor point may shift. Consider using a fixed-width status item that's wide enough for 3 cities, and right-align the text within it. This way adding/removing cities changes the text but not the item's frame.

---

## City name must NEVER wrap to two lines

**What's wrong:** "San Francisco" sometimes wraps to two lines, making that row taller than others.

**Fix:** Every city name must be on a single line. Apply:
```swift
Text(city.name)
    .lineLimit(1)
    .truncationMode(.tail)
    .frame(width: 90, alignment: .leading)
```

ALL city rows must have the exact same height (56px fixed). No exceptions.

---

## Home city flag — remove the circle/badge

**What's wrong:** The home city (New York) still shows the flag inside a circular badge or container.

**Fix:** The home city flag should be rendered IDENTICALLY to every other flag — just a plain emoji. The only differences for the home city are:
1. A tiny 📍 (6px) overlaid at the bottom-right corner of the flag
2. The city name text is slightly brighter: `rgba(200, 210, 255, 0.95)` and weight `.semibold`
3. The offset text shows "You" instead of the hour offset
4. A very subtle background glow on the row: `rgba(167, 180, 255, 0.04)` — barely visible

Remove ANY Circle(), clipShape, overlay containers, or badge shapes on the flag.

---

## Divider lines are too thick

**What's wrong:** The horizontal dividers between city rows are too visible and heavy.

**Fix:** Dividers must be:
```swift
Rectangle()
    .fill(Color.white.opacity(0.06))
    .frame(height: 0.5)
    .padding(.horizontal, 18)
```

0.5pt height, not 1pt. Very subtle.

---

## Timeline bar should be wider

**What's wrong:** The timeline bar (colored bar between city name and time) is too short. It should use all available space.

**Fix:** The timeline bar is the flex element in the row. It should expand to fill ALL space between the name column and the time column. With the fixed column widths defined above:
- Flag: 24px + 8px gap = 32px
- Name: 90px + 8px gap = 98px  
- Time: 65px
- Dot: 6px + 8px gap = 14px
- Remove: 10px + 4px gap = 14px
- Total fixed: ~240px
- In a 350px popover with 18px padding each side (314px usable): ~74px for the timeline bar

That's still not huge, so make the popover 360px wide instead of 350px to give the bars more room. Adjust padding to 20px horizontal.

---

## After fixing, verify by comparing side-by-side with the mockup:
1. Open `docs/design-mockup-v4.jsx` in a browser (or look at the React artifact)
2. Place it next to the running app
3. Check: overall height, spacing between elements, glass effect, font sizes, divider thickness, column alignment, flag rendering
4. The app should feel compact, sleek, and translucent — not tall, spaced out, and opaque
