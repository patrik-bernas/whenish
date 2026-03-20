# Bug Fix Brief: Pass 14

---

## Bug 1: Remove the "now" text label from the column view

**What's wrong:** There's a small "now" text label on the left edge of the now reference line in column view. It looks cluttered.

**Fix:** Remove the `Text("now")` element. Keep just the indigo horizontal line itself — no text label. The line alone is sufficient as a reference.

---

## Bug 2: Make column bars 20-25% slimmer

**What's wrong:** The column bars still look a bit thick and aggressive.

**Fix:** Reduce bar width by about 25%. If they're currently ~30px, bring them down to ~22-24px. Keep the same gaps between bars. The bars should feel like slim elegant pillars:

```swift
let barWidth: CGFloat = 22
```

Keep the corner radius proportional — reduce to 3px if needed for the slimmer bars.

---

## Bug 3: Current time display is STILL wrong — showing 09:45 instead of 15:45

**What's wrong:** The user is in the US East Coast and their actual time is 3:45 PM (15:45), but the app shows 09:45. This has been broken for multiple passes. The time is off by exactly 6 hours, which suggests the app is using UTC or a wrong timezone.

**Fix:** This is a critical debugging task. The current time display must show the REAL time on the user's computer.

Step 1: Replace the current time computation with the simplest possible implementation:

```swift
var currentTimeString: String {
    let formatter = DateFormatter()
    formatter.timeZone = TimeZone.current  // USE THE SYSTEM TIMEZONE, NOT homeTimeZone
    if settings.use24HourFormat {
        formatter.dateFormat = "HH:mm"
    } else {
        formatter.dateFormat = "h:mm a"
    }
    return formatter.string(from: Date())
}
```

**IMPORTANT:** Use `TimeZone.current` — the actual system timezone from the Mac. Do NOT use:
- A stored homeTimeZone identifier that might be stale or wrong
- UTC
- Any timezone derived from the city list

The bottom-right time is "what time is it RIGHT NOW on this computer." Nothing more.

Step 2: Verify by adding a temporary debug print:
```swift
print("System timezone: \(TimeZone.current)")
print("Date: \(Date())")
print("Formatted: \(currentTimeString)")
```

If `TimeZone.current` doesn't return the user's actual timezone, then there's a system-level issue. But most likely, the code is using a stored timezone identifier instead of `TimeZone.current`.

Step 3: Also fix the time in the MENUBAR. The menubar times should use each city's actual timezone, and the format should match the 12h/24h setting. Check that the menubar formatter is also using the correct timezones.

---

## After fixing, verify:
1. No "now" text label in column view (just the indigo line)
2. Column bars are visibly slimmer
3. Bottom-right time matches the macOS system clock EXACTLY
4. Test: if your Mac says 3:45 PM, the app says 3:45 PM (in 12h) or 15:45 (in 24h)
