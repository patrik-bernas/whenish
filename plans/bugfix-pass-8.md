# Bug Fix Brief: Pass 8 — Remove Settings, Redesign Interactions

This is a significant UX improvement pass. Read `docs/design-brief.md` for color/spacing reference.

---

## Change 1: Remove the Settings view entirely

**What:** Delete the SettingsView.swift file and all navigation to it. Remove `isSettingsOpen` from the ViewModel. The gear icon is being replaced (see Change 2). There should be no settings page at all — everything is managed inline.

---

## Change 2: Replace gear icon with a 12h/24h toggle

**What's wrong:** The gear icon opens a settings page. We're removing settings, so the gear needs a new purpose.

**Fix:** Replace the gear icon (⚙) with a tappable text label that toggles the time format:

- When in 24h mode, show the text **"24h"**
- When in 12h mode, show the text **"12h"**
- Tapping it switches between the two formats instantly
- Style: same size/position as the old gear button (30×30px area), text is 11px, weight .medium, color `rgba(255,255,255,0.4)`. On hover, brighten to `rgba(255,255,255,0.6)`.
- The label should look like a subtle button, not a big element — it sits quietly next to the search bar

```swift
Button(action: { viewModel.toggle24HourFormat() }) {
    Text(viewModel.settings.use24HourFormat ? "24h" : "12h")
        .font(.system(size: 11, weight: .medium))
        .foregroundColor(.white.opacity(0.4))
        .frame(width: 30, height: 30)
        .background(Color.white.opacity(0.06))
        .cornerRadius(8)
}
.buttonStyle(.plain)
```

---

## Change 3: Redesign group pills — add + button, double-click to manage

**What's wrong:** Currently groups can only be managed from settings (which we're removing).

**Fix:** Redesign the pills row:

### Layout:
```
[ Work ] [ Friends ] [ Test ] [ + ]
```

### Single click on a pill → switches to that group (existing behavior)

### Double-click on a pill → enters edit mode for that group:
When a pill is double-clicked, it expands into an inline edit view that replaces the pills row:

```
[ ← ] [ Friends_________ ] [ 7/12 ] [ 🗑 ]
```

- **← (back arrow):** exits edit mode, returns to normal pills view
- **Text field:** editable group name, 12 character max
- **Character count:** shows current/max like "7/12"
- **🗑 (trash):** deletes the group (only if more than 1 group exists). Show a confirmation before deleting. When deleted, switch to the first remaining group.

Style the edit mode with the same glass aesthetic — translucent background, subtle border, same horizontal space as the pills row.

### + button to add a new group:
- Only visible if fewer than 5 groups exist
- Style: same size as a pill, but shows just "+" in `rgba(255,255,255,0.3)`
- Tapping it creates a new group with default name "Group N" (where N is the next number)
- After creating, automatically switch to the new group so the user can start adding cities

### Max 5 groups total. When 5 exist, the + button disappears.

---

## Change 4: Home city — 📍 button on hover

**What's wrong:** Currently the only way to set a home city was through settings (which we're removing).

**Fix:** When the user hovers over a city row, a small 📍 icon appears to the left of the flag (or between the flag and the city name). This icon is:

- **Hidden by default** (not visible when not hovering)
- **Visible on hover** over the city row, with a fade-in
- **Tappable** — clicking it sets that city as the home city
- If this city is ALREADY the home city, the 📍 is always visible (not just on hover) and is brighter

When clicked:
1. Set this city as home (`isHome = true`)
2. Remove home status from any other city across all groups
3. The city name becomes slightly brighter, offset changes to "You"
4. Show a subtle flash or highlight to confirm

Style:
```swift
// On the city row, add before the flag:
if isHovering || city.isHome {
    Text("📍")
        .font(.system(size: 8))
        .opacity(city.isHome ? 1.0 : 0.5)
        .onTapGesture { viewModel.setHomeCity(city) }
        .transition(.opacity)
}
```

Keep the row height fixed at the same size — the 📍 should not cause any layout shift.

---

## Change 5: Duplicate city in menubar

**What's wrong:** If New York is in both the Work and Friends groups with the menubar toggle active, it shows twice in the menubar: "NYC 3:39 PM · NYC 3:39 PM"

**Fix:** When computing menubar cities, deduplicate by timezone identifier. Collect all cities from ALL groups where `showInMenubar == true`, then filter out duplicates (keep the first occurrence). Use the timezone identifier as the unique key:

```swift
var menubarCities: [City] {
    var seen = Set<String>()
    var result = [City]()
    for group in groups {
        for city in group.cities where city.showInMenubar {
            if !seen.contains(city.timeZoneIdentifier) {
                seen.insert(city.timeZoneIdentifier)
                result.append(city)
            }
        }
    }
    return Array(result.prefix(4)) // max 4 in menubar
}
```

---

## Change 6: Legend spacing — move closer to the slider bar

**What's wrong:** Still too much gap between the slider area and the legend.

**Fix:** Exact spacing for the entire bottom section:

```
[Last city row]
6px gap
Now                        ⏱ 10:09 AM     ← offset/time row
4px gap
[======= slider bar =======]               ← 7px tall
3px gap
-24h                               +24h    ← range labels
5px gap
● Available  ● Heads up  ● Sleeping        ← legend
5px gap                                     ← bottom padding
```

Total from slider bar to bottom of popover: about 30px. It should feel snug.

---

## Change 7: Make colors stand out more — especially green

**What's wrong:** The timeline bar colors are still a bit flat. Green doesn't pop enough compared to red and yellow.

**Fix:** Boost green more than the others to make it the "hero" color. Slightly desaturate red and yellow so green stands out by contrast:

```swift
// Bright, inviting green — the "good to call" signal
available: Color(red: 0.18, green: 0.84, blue: 0.55).opacity(0.90)  // vivid mint green

// Warm but not competing amber
caution: Color(red: 0.95, green: 0.72, blue: 0.20).opacity(0.75)    // warm gold

// Soft muted coral — clearly "stop" but not alarming
sleeping: Color(red: 0.90, green: 0.40, blue: 0.38).opacity(0.65)   // dusty rose-red
```

Green is at 0.90 opacity (highest), yellow at 0.75, red at 0.65. This creates a clear visual hierarchy: green pops, yellow is noticeable, red recedes. The user's eye is drawn to the green zones first — which is exactly what you want (those are the best times to reach someone).

Apply the same colors to:
- Per-city timeline bars
- The slider bar at the bottom
- The legend dots

---

## After fixing, verify:
1. No settings page — gear is replaced with "24h" / "12h" toggle
2. Tapping the toggle switches time format instantly
3. + button appears after last pill, creates new group
4. Double-clicking a pill enters edit mode with rename, char count, and delete
5. Hovering a city row reveals 📍 icon
6. Clicking 📍 sets that city as home
7. NYC only appears once in menubar even if in multiple groups
8. Legend is snug below the slider
9. Green clearly stands out more than yellow and red on timeline bars
