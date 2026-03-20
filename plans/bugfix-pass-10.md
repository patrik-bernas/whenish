# Bug Fix Brief: Pass 10 — Continuous Vertical Scrub Line

This is the app's signature visual feature. Read `docs/design-mockup-v4.jsx` for reference — it shows a vertical line connecting the slider to all timeline bars.

---

## What to build: One continuous vertical line from the slider dot through all city timeline bars

**What's wrong:** Currently each city's timeline bar has its own tiny independent scrub marker. Instead, there should be ONE single vertical line that runs continuously from the slider dot at the bottom, straight up through every city row's timeline bar.

**How it should look:**
```
🇺🇸  Honolulu    ▬▬▬▬▬▬▬▬|▬▬▬▬▬▬▬    04:54
🇺🇸  San Francisco ▬▬▬▬▬▬▬|▬▬▬▬▬▬▬   07:54  
🇺🇸  New York    ▬▬▬▬▬▬▬▬|▬▬▬▬▬▬▬    10:54
🇦🇹  Vienna      ▬▬▬▬▬▬▬▬|▬▬▬▬▬▬▬    15:54
🇯🇵  Tokyo       ▬▬▬▬▬▬▬▬|▬▬▬▬▬▬▬    23:54

Now                        |              ⏱ 10:54
▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬●▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬
-24h                                        +24h
```

The `|` is one single continuous vertical line from the slider dot all the way up through every timeline bar. When you drag the slider, the entire line moves left/right together.

**Implementation approach:**

The challenge is that the timeline bars and the slider are in different views at different levels of the view hierarchy. The solution is to use a ZStack overlay on the entire city list + slider area.

1. **Remove the individual scrub lines** from each TimelineBarView. The bars should just render their color segments with no marker.

2. **Calculate the x-position of the scrub line** relative to the full popover width. The line's x-position corresponds to the scrubber offset mapped to the timeline bar's coordinate space.

3. **Draw one single line as an overlay** on the container that holds both the city list and the slider:

```swift
// In PopoverView.swift, wrap the city list + slider in a ZStack:

ZStack(alignment: .leading) {
    VStack(spacing: 0) {
        // City rows
        ForEach(cities) { city in
            CityRowView(city: city, ...)
        }
        
        // Divider above slider
        Rectangle()
            .fill(Color.white.opacity(0.06))
            .frame(height: 0.5)
            .padding(.horizontal, 20)
        
        // Slider area
        TimeSliderView(...)
    }
    
    // THE CONTINUOUS VERTICAL LINE
    // Position it based on the scrubber value
    GeometryReader { geometry in
        let totalWidth = geometry.size.width
        let padding: CGFloat = 20 // horizontal padding
        let flagColumn: CGFloat = 32 // flag width + gap
        let nameColumn: CGFloat = 101 // name width + gap
        let barStartX = padding + flagColumn + nameColumn
        let timeColumn: CGFloat = 82 // from right edge
        let rightElements: CGFloat = 26 // dot + remove
        let barEndX = totalWidth - padding - timeColumn - rightElements - 6
        let barWidth = barEndX - barStartX
        
        let scrubX = barStartX + (CGFloat(viewModel.scrubNormalized) * barWidth)
        
        Rectangle()
            .fill(Color.white.opacity(0.35))
            .frame(width: 1.5)
            .offset(x: scrubX)
            .allowsHitTesting(false) // don't interfere with clicks
    }
}
```

**Important details:**

- `viewModel.scrubNormalized` should be a value from 0.0 to 1.0 representing where the scrubber is in its range. 0.0 = -24h (left edge), 0.5 = Now (center), 1.0 = +24h (right edge).

- The line must be exactly aligned with the timeline bars. This means the x-calculation must account for the same column widths used in CityRowView. The line starts at the left edge of where timeline bars begin and the scrub position is a percentage across the bar width.

- The line should span from the TOP of the first city row to the BOTTOM of the slider bar. Use the full height of the GeometryReader.

- Line style: **1.5px wide**, color `rgba(255, 255, 255, 0.35)`, no rounded caps needed.

- The line must NOT interfere with user interactions — use `.allowsHitTesting(false)` so clicks pass through to the city rows and slider beneath.

- When the slider dot moves, the line moves with it in real-time. They must be perfectly synchronized — the dot's center and the line's x-position represent the same scrubber value.

**Alternative simpler approach** if the GeometryReader is tricky:

Instead of one overlay line, keep the per-bar approach but make the lines much more visible and precisely aligned:

```swift
// In each TimelineBarView, draw the scrub marker:
Rectangle()
    .fill(Color.white.opacity(0.4))
    .frame(width: 1.5, height: 20) // taller than the bar — extends above and below
    .offset(x: scrubLineX)
```

Make the line 20px tall (much taller than the 6px bar) so it visually connects across rows. The gaps between rows are small enough that the eye perceives one continuous line even if they're technically separate elements — as long as they're all at the exact same x-position.

**Either approach works.** The overlay approach is cleaner but harder to align. The tall-per-bar approach is simpler and gives nearly the same visual effect.

---

## Also: Remove individual scrub markers

If going with the overlay approach, remove the small vertical line rendering from inside TimelineBarView entirely. The overlay handles it.

If going with the tall-per-bar approach, just increase the height to 20px and make sure all bars use identical width calculations.

---

## After fixing, verify:
1. One continuous (or visually continuous) vertical line runs from the slider through all city timeline bars
2. The line moves smoothly when dragging the slider
3. The line is clearly visible against the colored bars (white at 35% opacity, 1.5px wide)
4. The line doesn't interfere with clicking city rows, the remove button, or the menubar toggle
5. The line aligns perfectly — check by dragging to the far left and far right edges
