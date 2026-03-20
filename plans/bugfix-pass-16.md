# Bug Fix Brief: Pass 16

---

## Bug 1: Menubar time is 8 seconds behind the real system clock

**What's wrong:** The app's time updates lag behind the Mac's actual clock by several seconds. When the system clock rolls to the next minute, the app takes ~8 seconds to catch up.

**Fix:** Instead of a simple repeating timer (which drifts), sync to the system clock's minute boundary:

```swift
func startMinuteSyncTimer() {
    // First, update immediately
    updateMenubarText()
    updateCurrentTimeDisplay()
    
    // Calculate seconds until the next minute starts
    let now = Date()
    let calendar = Calendar.current
    let seconds = calendar.component(.second, from: now)
    let nanoseconds = calendar.component(.nanosecond, from: now)
    let delayToNextMinute = Double(60 - seconds) - Double(nanoseconds) / 1_000_000_000
    
    // Fire once at the exact next minute boundary
    DispatchQueue.main.asyncAfter(deadline: .now() + delayToNextMinute) { [weak self] in
        self?.updateMenubarText()
        self?.updateCurrentTimeDisplay()
        
        // Then repeat every 60 seconds exactly on the minute
        self?.minuteTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            self?.updateMenubarText()
            self?.updateCurrentTimeDisplay()
        }
        // Use common run loop mode so it fires even during UI interaction
        if let timer = self?.minuteTimer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }
}
```

This ensures the app updates at exactly :00 seconds of every minute, perfectly in sync with the system clock. Call `startMinuteSyncTimer()` on app launch.

Also add `.common` run loop mode to the timer so it doesn't pause when the user is dragging the slider or interacting with the UI.

---

## Bug 2: Add dates alongside Today/Tomorrow/Yesterday labels

**What's wrong:** The date labels just say "Today", "Tomorrow", or "Yesterday" but don't show the actual date.

**Fix:** Change the date labels to include the abbreviated day and date:

**Format:** `Today, Mar 20` or `Tomorrow, Mar 21` or `Yesterday, Mar 19`

If space is tight (especially in column view), use:
- Row view: `Today, Mar 20` (full format — there's room)
- Column view: `Today` on first line, `Mar 20` on second line (stacked)

```swift
func dateLabel(for date: Date, relativeTo now: Date) -> (relative: String, date: String) {
    let calendar = Calendar.current
    let formatter = DateFormatter()
    formatter.dateFormat = "MMM d"  // e.g. "Mar 20"
    let dateStr = formatter.string(from: date)
    
    if calendar.isDateInToday(date) {
        return ("Today", dateStr)
    } else if calendar.isDateInTomorrow(date) {
        return ("Tomorrow", dateStr)
    } else if calendar.isDateInYesterday(date) {
        return ("Yesterday", dateStr)
    } else {
        formatter.dateFormat = "EEE, MMM d"  // e.g. "Sat, Mar 22"
        return (formatter.string(from: date), "")
    }
}
```

**Row view rendering:**
```swift
// Below each time
Text("\(label.relative), \(label.date)")  // "Today, Mar 20"
    .font(.system(size: 9))
    .foregroundColor(isToday ? .white.opacity(0.2) : Color(red: 167/255, green: 180/255, blue: 255/255).opacity(0.55))
```

**Column view rendering:**
```swift
// Below each time, stacked
VStack(spacing: 1) {
    Text(label.relative)  // "Today"
        .font(.system(size: 8))
    Text(label.date)      // "Mar 20"
        .font(.system(size: 8))
}
```

The "Today" labels stay subtle, "Tomorrow"/"Yesterday" stay brighter indigo — same color logic as before, just with the date added.

---

## Bug 3: Rounded corners have small pointy artifacts

**What's wrong:** All four corners of the popover panel have small pointy/sharp artifacts visible — the corner radius isn't clean.

**Fix:** This is likely caused by either:
1. The NSVisualEffectView's corner radius not matching the panel's clipping
2. A subview extending beyond the rounded corners
3. The panel's content view not being properly clipped

Fix by ensuring proper masking at every level:

```swift
// On the NSVisualEffectView:
visualEffectView.wantsLayer = true
visualEffectView.layer?.cornerRadius = 18
visualEffectView.layer?.masksToBounds = true  // CRITICAL — clips content to rounded corners
visualEffectView.layer?.cornerCurve = .continuous  // Smooth Apple-style corners

// On the panel itself:
panel.backgroundColor = .clear
panel.isOpaque = false

// If using a content view wrapper:
panel.contentView?.wantsLayer = true
panel.contentView?.layer?.cornerRadius = 18
panel.contentView?.layer?.masksToBounds = true
panel.contentView?.layer?.cornerCurve = .continuous
```

The `.cornerCurve = .continuous` gives the smooth "squircle" corners that Apple uses (same as iOS icons), rather than simple circular arcs.

Also check: is there a shadow or border view that extends beyond the rounded corners? If the panel has `hasShadow = true`, the system shadow should respect the corner radius automatically. But if there's a custom shadow or border added in SwiftUI, it might extend past the clipping mask.

Search for any views in PopoverView that might cause overflow:
```bash
grep -r "shadow" src/TimezoneApp/Views/
grep -r "border" src/TimezoneApp/Views/
grep -r "overlay" src/TimezoneApp/Views/
```

---

## Bug 4: Column view times should be slightly bigger

**What's wrong:** The time font below the column bars (currently 16px) feels small compared to the row view's time font (19px).

**Fix:** Increase column view time font from 16px to **18px**:

```swift
Text(timeString)
    .font(.system(size: 18, weight: .light).monospacedDigit())
    .foregroundColor(.white.opacity(0.85))
```

For 12h format, keep AM/PM at 10px (roughly half the main time size).

This brings the column times closer to the row view's 19px while still fitting within the narrower column width.

---

## After fixing, verify:
1. Watch the menubar clock and the Mac system clock side by side — they should flip to the next minute at the exact same moment
2. Row view shows "Today, Mar 20" or "Tomorrow, Mar 21" below times
3. Column view shows date info below times (stacked if needed)
4. All four corners of the popover are perfectly smooth with no artifacts
5. Column view times are visibly bigger (18px) and easier to read
