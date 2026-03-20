# Bug Fix Brief: Pass 20

---

## Fix 1: FIXED HEIGHT — both views must be the same height

**What's wrong:** The column view and row view still have different heights, causing the popover to resize when toggling.

**Fix:** The popover contentSize is set to 390×500 in AppDelegate. That must never change. In PopoverView, the layout is:

```swift
VStack(spacing: 0) {
    // TOP (fixed height)
    SearchBarRow(...)    // ~44px
    GroupPillsRow(...)   // ~36px
    
    // MIDDLE (fixed height — MUST be the same for both views)
    Group {
        if viewModel.isColumnView {
            ColumnContentView(...)
        } else {
            RowListContentView(...)
        }
    }
    .frame(height: 340)  // FIXED pixel height. Not maxHeight, not flexible. FIXED.
    .clipped()
    
    // BOTTOM (fixed height)
    SharedBottomSection(...)  // ~80px
}
.frame(width: 390, height: 500)
```

The middle content area is `.frame(height: 340)` — a hard fixed number. NOT `.frame(maxHeight: .infinity)`. A specific pixel value.

Both RowListContentView and ColumnContentView must fit within 340px:
- Row view: if 5 city rows don't fill 340px, add a `Spacer()` at the bottom inside the view to push rows to the top
- Column view: size the column bars to fill the 340px minus header and time labels

Calculate the exact value: 500 (total) - 44 (search) - 36 (pills) - 80 (bottom) = 340px for content.

Adjust these numbers if needed, but the key is: the middle frame height is ONE FIXED NUMBER shared by both views.

---

## Fix 2: Add a white drag dot to the row view's vertical scrub line

**What's wrong:** The row view has a vertical scrub line but no white dot drag handle like the column view has.

**Fix:** Add a 16px white circle centered on the vertical scrub line, positioned at the vertical midpoint of the city list area:

```swift
// On the vertical scrub line overlay in row view:
Circle()
    .fill(Color.white.opacity(0.95))
    .frame(width: 16, height: 16)
    .shadow(color: .black.opacity(0.15), radius: 4, y: 1)
    .position(x: scrubLineX, y: cityListHeight / 2)
```

This dot should:
- Be centered vertically on the scrub line
- Move left/right with the scrub line when dragging
- Look identical to the column view's drag dot (same size, color, shadow)

---

## Fix 3: One continuous vertical scrub line across all rows

**What's wrong:** The vertical scrub line in the row view may be drawn as separate small lines per bar instead of one continuous line.

**Fix:** The vertical scrub line must be ONE continuous line that extends from the top of the first city row's timeline bar to the bottom of the last city row's timeline bar. It must NOT have gaps between rows.

Draw it as a single overlay on the entire city list container:

```swift
// In RowListContentView, overlay the entire city list:
ZStack {
    VStack(spacing: 0) {
        ForEach(cities) { city in
            CityRowView(city: city, ...)
        }
        Spacer()
    }
    
    // One continuous vertical scrub line
    GeometryReader { geo in
        let barStartX: CGFloat = // calculate based on column widths
        let barEndX: CGFloat = // calculate based on column widths
        let barWidth = barEndX - barStartX
        let scrubX = barStartX + (CGFloat(viewModel.scrubNormalized) * barWidth)
        let cityCount = min(cities.count, 5)
        let rowHeight: CGFloat = 60  // approximate row height
        let totalCityHeight = CGFloat(cityCount) * rowHeight
        
        // The line
        Rectangle()
            .fill(Color.white.opacity(0.4))
            .frame(width: 1.5, height: totalCityHeight)
            .position(x: scrubX, y: totalCityHeight / 2)
            .allowsHitTesting(false)
        
        // The dot
        Circle()
            .fill(Color.white.opacity(0.95))
            .frame(width: 16, height: 16)
            .shadow(color: .black.opacity(0.15), radius: 4, y: 1)
            .position(x: scrubX, y: totalCityHeight / 2)
            .allowsHitTesting(false)
    }
}
.gesture(
    DragGesture(minimumDistance: 0)
        .onChanged { value in
            // map drag x to scrubber offset
        }
)
```

Remove any per-bar individual scrub line rendering from TimelineBarView. The single overlay handles it.

---

## Fix 4: Bring back purple/indigo for the "now" marker — remove plum

**What's wrong:** The dark plum color (#3B1F2B) for the "now" markers is invisible against the dark background.

**Fix:** Replace all "now" marker colors with a visible indigo/purple:

```swift
let nowMarkerColor = Color(red: 140/255, green: 130/255, blue: 255/255).opacity(0.7)
// Hex approximately: #8C82FF at 70% opacity
```

This is a medium-bright purple that's clearly visible against both the dark background and the green/yellow/red bars. Apply this color to:
- The "now" tick mark on each row view timeline bar
- The "now" reference line in column view  
- The current time text (⏱ 11:46) at the bottom right

Remove all references to the plum color #3B1F2B.

---

## Fix 5: Tooltip alignment

**What's wrong:** The menubar tooltip text columns are not properly aligned.

**Fix:** Use a monospaced font approach with fixed-width padding:

```swift
func buildTooltip() -> String {
    let now = Date()
    let cities = menubarCities
    let maxName = cities.map { $0.name.count }.max() ?? 10
    
    return cities.map { city -> String in
        let tz = TimeZone(identifier: city.timeZoneIdentifier)!
        let fmt = DateFormatter()
        fmt.timeZone = tz
        
        // Right-pad city name
        let name = city.name.padding(toLength: maxName, withPad: " ", startingAt: 0)
        
        // Fixed-width time
        fmt.dateFormat = settings.use24HourFormat ? "HH:mm" : "h:mm a"
        let time = fmt.string(from: now)
        let paddedTime = time.padding(toLength: 8, withPad: " ", startingAt: 0)
        
        // Date
        fmt.dateFormat = "EEE, MMM d"
        let date = fmt.string(from: now)
        
        return "\(name)  \(paddedTime)  \(date)"
    }.joined(separator: "\n")
}
```

Note: macOS tooltips render in the system font which may not be monospaced. The padding helps but perfect column alignment in tooltips is limited by the system. This is the best we can do without a custom tooltip view.

---

## After fixing, verify:
1. Toggle between views — height DOES NOT CHANGE. The popover stays exactly the same size.
2. Row view has a white dot centered on the vertical scrub line
3. Vertical scrub line in row view is ONE continuous line (no gaps between rows)
4. Dragging across row view timeline bars moves the line and dot smoothly
5. "Now" markers are visible purple/indigo, not dark plum
6. Column view still works (horizontal drag, dot, etc)
7. Both views' bottom sections are identical and don't move when toggling
