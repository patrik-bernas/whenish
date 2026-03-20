# Bug Fix Brief: Pass 13

---

## Bug 1: Current time display (bottom right) is wrong

**What's wrong:** The time shown at the bottom right (e.g. "⏱ 09:23") doesn't match the actual current time. The user's real local time is 3:24 PM (visible in the macOS clock in the top-right of the screen), but the app shows 09:23.

**Fix:** The current time MUST come from `Date()` formatted in the user's HOME timezone. Debug this by:

1. Print `Date()` and `TimeZone.current` to verify what the system thinks the time is
2. Print `homeTimeZone` to verify which timezone is set as home
3. The formatter must use the HOME timezone, not UTC or some other timezone:

```swift
var currentTimeString: String {
    let formatter = DateFormatter()
    formatter.timeZone = TimeZone.current // or the user's selected home timezone
    formatter.dateFormat = settings.use24HourFormat ? "HH:mm" : "h:mm a"
    return formatter.string(from: Date())
}
```

If the home timezone is New York (America/New_York) and the system clock shows 3:24 PM, the app must show "3:24 PM" (12h) or "15:24" (24h). Any other value means the timezone is wrong.

Check: is the home timezone being stored/loaded correctly? Is it using the timezone identifier (e.g. "America/New_York") or some offset that doesn't account for DST?

---

## Bug 2: Honolulu STILL has the wrong flag

**What's wrong:** Honolulu continues to show a non-US flag despite multiple fix attempts.

**Fix:** This needs a definitive fix. Search the ENTIRE codebase for where Honolulu's flag is set:

```bash
grep -r "Honolulu" src/
grep -r "Pacific/Honolulu" src/
```

Find where the flag emoji is assigned and force it to 🇺🇸. The timezone identifier for Honolulu is `Pacific/Honolulu` and the country code is `US`.

If the `timezoneToCountry` dictionary from pass 6 exists, verify the entry:
```swift
"Pacific/Honolulu": "US"
```

If the dictionary is being bypassed or not used for Honolulu, fix the code path so it IS used. Add a print statement to debug: when Honolulu is looked up, what country code does it get, and what flag emoji does that produce?

The `flagEmoji` function for country code "US" must produce 🇺🇸:
```swift
func flagEmoji(for countryCode: String) -> String {
    let base: UInt32 = 127397
    return countryCode.uppercased().unicodeScalars.map {
        String(UnicodeScalar(base + $0.value)!)
    }.joined()
}
// flagEmoji(for: "US") → "🇺🇸"
```

Test this function directly with "US" and verify it outputs 🇺🇸.

---

## Bug 3: "Now" reference line needs to stand out more in column view

**What's wrong:** The indigo "now" marker line in the column view is hard to distinguish from the white scrub line.

**Fix:** Make the now marker line a distinctly different color — use a **brighter, more saturated indigo/purple** and make it dashed or use a different style:

```swift
// Now marker — bright indigo, slightly thicker
Rectangle()
    .fill(Color(red: 130/255, green: 140/255, blue: 255/255).opacity(0.7))
    .frame(height: 2.5)
```

Color: `rgba(130, 140, 255, 0.7)` — a more vivid, bluer purple that clearly stands apart from the white scrub line.

Additionally, add small triangular arrows or notches on the left and right edges of the now line to make it even more distinct:

```swift
// Or simply use a brighter color and label it
HStack {
    Text("now")
        .font(.system(size: 7, weight: .bold))
        .foregroundColor(Color(red: 130/255, green: 140/255, blue: 255/255).opacity(0.6))
    Rectangle()
        .fill(Color(red: 130/255, green: 140/255, blue: 255/255).opacity(0.7))
        .frame(height: 2.5)
}
```

A tiny "now" label on the left edge of the line would make it unmistakable.

---

## Bug 4: Time labels below columns — make slightly bigger

**What's wrong:** The times below the column bars could be a bit bigger for readability.

**Fix:** Increase from 14px to **16px**, keep weight .light, tabular nums:

```swift
Text(timeString)
    .font(.system(size: 16, weight: .light).monospacedDigit())
    .foregroundColor(.white.opacity(0.85))
```

For 12h format, keep AM/PM at 9px (same ratio — about half the main time size).

---

## Bug 5: Add "now" markers to row view timeline bars

**What's wrong:** In the row/list view, the per-city timeline bars don't have any indication of where "now" is. When the user scrubs away from now, they can't see the reference point on each bar.

**Fix:** On each city's horizontal timeline bar in the ROW view, add a small vertical tick mark at the position corresponding to "now" (independent of the scrub line):

```swift
// In TimelineBarView, add a "now" marker:
let nowPosition = calculateNowXPosition(for: city.timeZone, barWidth: barWidth)

Rectangle()
    .fill(Color(red: 130/255, green: 140/255, blue: 255/255).opacity(0.7))
    .frame(width: 2, height: 10) // slightly taller than the bar
    .offset(x: nowPosition)
```

This indigo tick mark is:
- **Always visible** (doesn't hide when scrub is at now — it's a permanent reference)
- **Fixed position** — never moves, represents "right now" for that city
- **2px wide, 10px tall** — extends slightly above and below the 6px bar
- **Same indigo color** as the column view's now marker: `rgba(130, 140, 255, 0.7)`

The WHITE scrub line (which moves) and the INDIGO now marker (which stays fixed) create a clear visual: "I've moved 6 hours forward from now" — you can see the gap between the indigo tick and the white line.

---

## After fixing, verify:
1. Bottom-right time matches the actual real-world time in your timezone
2. Honolulu shows 🇺🇸 — verify in both row and column views
3. Now reference line in column view clearly stands apart from the scrub line
4. Time labels below columns are bigger (16px) and easy to read
5. Row view timeline bars each have an indigo "now" tick mark
6. The indigo tick in row view stays fixed while the white scrub line moves
