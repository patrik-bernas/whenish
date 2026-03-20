# Bug Fix Brief: Pass 9

---

## Bug 1: App is slow and laggy

**What's wrong:** The app feels sluggish — clicks take a moment to register, animations stutter, and switching groups has noticeable delay.

**Fix:** Likely causes and solutions:

1. **Too many redraws:** If the ViewModel is @Observable or @Published and every property change triggers a full view rebuild, wrap updates in batches. Use `withAnimation` only where needed, not on every state change.

2. **Timer overhead:** If there's a Timer updating the menubar text every second, reduce it to every 30 seconds or 60 seconds. The time only needs minute-level precision.

3. **Persistence on every change:** If `UserDefaults` is being written on every single state mutation (every scrubber drag frame, every hover), throttle it. Only save when meaningful changes happen (city added/removed, group switched, settings changed). Do NOT save on scrubber drag — only save scrubber position on drag END.

4. **Heavy view bodies:** Make sure each city row is a separate view with its own identity (use `.id(city.id)` in ForEach). This lets SwiftUI diff efficiently instead of rebuilding the entire list.

5. **Search debounce:** If the search triggers on every keystroke, add a 200ms debounce so it only searches after the user stops typing briefly.

```swift
// Debounce search
searchQuery
    .debounce(for: .milliseconds(200), scheduler: RunLoop.main)
    .sink { query in
        self.performSearch(query)
    }
```

6. **Remove any print/debug statements** left over from development — these slow down the app significantly.

---

## Bug 2: Group pill editing should be inline within the pill

**What's wrong:** Double-clicking a group pill currently expands into a full-width edit bar that takes up the entire row. It should expand in-place where the pill is.

**Fix:** When a pill is double-clicked, it transforms from a label into a small inline edit view, roughly in the same position. The other pills shift slightly to make room but stay visible:

### Normal state:
```
[ Work ] [ Friends ] [ Test ] [ + ]
```

### After double-clicking "Friends":
```
[ Work ] [ Friends______ 7/12 🗑 ] [ Test ] [ + ]
```

The edited pill expands slightly wider (maybe 140px) to fit:
- An editable text field showing the group name
- A character count "7/12" in small dim text
- A trash icon 🗑 to delete

Implementation:
```swift
// In GroupPillsView, for each group:
if editingGroupId == group.id {
    // Inline edit mode
    HStack(spacing: 4) {
        TextField("", text: $editingName)
            .textFieldStyle(.plain)
            .font(.system(size: 11, weight: .medium))
            .foregroundColor(.white.opacity(0.9))
            .frame(width: 80)
            .onSubmit { saveGroupName() }
        
        Text("\(editingName.count)/12")
            .font(.system(size: 9))
            .foregroundColor(.white.opacity(0.3))
        
        if groups.count > 1 {
            Button(action: { deleteGroup(group) }) {
                Image(systemName: "trash")
                    .font(.system(size: 9))
                    .foregroundColor(.white.opacity(0.3))
            }
            .buttonStyle(.plain)
        }
    }
    .padding(.horizontal, 10)
    .padding(.vertical, 5)
    .background(Color.white.opacity(0.14))
    .cornerRadius(20)
    .overlay(
        RoundedRectangle(cornerRadius: 20)
            .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
    )
} else {
    // Normal pill — single click to switch, double click to edit
    Text(group.name)
        .onTapGesture { viewModel.switchGroup(index: i) }
        .onTapGesture(count: 2) { startEditing(group) }
}
```

**Important behaviors:**
- Clicking outside the editing pill (or pressing Enter) saves and exits edit mode
- The text field enforces 12-character max
- Deleting a group does NOT close the popover — it removes the group, switches to the first remaining group, and stays in the normal pills view
- The other pills stay visible and usable during edit mode — they just shift to make room
- If only 1 group remains, the trash icon is hidden (can't delete the last group)

---

## Bug 3: Replace hover 📍 with a pin icon next to 24h toggle

**What's wrong:** The long-press/hover approach to set home timezone didn't work well and wasn't discoverable.

**Fix:** Remove the hover 📍 from city rows. Instead, add a 📍 icon button next to the 24h toggle in the top bar:

### New top bar layout:
```
[ 🔍 Add city...              ] [ 📍 ] [ 24h ]
```

- **📍 button:** Same size and style as the 24h toggle (30×30px, glass background, rounded 8px)
- **Tapping 📍** opens a small dropdown below it listing all cities currently in the active group
- Each city in the dropdown shows its flag + name
- The current home city has a checkmark ✓ next to it
- Tapping a city sets it as home and closes the dropdown

```swift
// Pin button
Button(action: { showHomeDropdown.toggle() }) {
    Text("📍")
        .font(.system(size: 12))
        .frame(width: 30, height: 30)
        .background(Color.white.opacity(0.06))
        .cornerRadius(8)
}
.buttonStyle(.plain)
.popover(isPresented: $showHomeDropdown) {
    // Or use an overlay dropdown instead of a popover:
    VStack(alignment: .leading, spacing: 0) {
        ForEach(viewModel.activeGroup.cities) { city in
            Button(action: { 
                viewModel.setHomeCity(city)
                showHomeDropdown = false
            }) {
                HStack {
                    Text(city.flag)
                    Text(city.name)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.8))
                    Spacer()
                    if city.isHome {
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }
    .frame(width: 200)
    .background(Color(white: 0.15, opacity: 0.95))
    .cornerRadius(10)
}
```

Actually, instead of a nested popover (which can be buggy), use an **overlay dropdown** that appears below the pin button within the existing panel:

```swift
.overlay(alignment: .topTrailing) {
    if showHomeDropdown {
        // dropdown positioned below the pin button
        VStack(...)
            .offset(y: 40) // below the button
    }
}
```

**Also remove** any hover 📍 logic from CityRowView that was added in pass 8.

The home city still gets the visual treatment: brighter name, "You" offset label, and the small 📍 next to its flag always visible (not on hover — always shown for the home city).

---

## Bug 4: Green still doesn't stand out enough

**What's wrong:** The green, yellow, and red on timeline bars all look too similar. Green needs to clearly pop as the "good" signal.

**Fix:** Make green significantly brighter and slightly larger, while keeping yellow and red more muted:

```swift
// GREEN — bright, clear, inviting. The "call now" signal.
let availableColor = Color(red: 0.10, green: 0.90, blue: 0.50).opacity(0.95)

// YELLOW — warm but subdued. "Maybe, be careful."
let cautionColor = Color(red: 0.85, green: 0.65, blue: 0.15).opacity(0.65)

// RED — dim and muted. "Don't bother."  
let sleepingColor = Color(red: 0.75, green: 0.30, blue: 0.28).opacity(0.50)
```

Key differences from before:
- Green opacity: 0.95 (was 0.90) — nearly full brightness
- Green hue: shifted to a purer, more vivid green (less teal)
- Yellow opacity: dropped to 0.65 (was 0.75) — more subdued
- Red opacity: dropped to 0.50 (was 0.65) — clearly the dimmest

The visual hierarchy should be unmistakable: green GLOWS, yellow is visible, red fades into the background.

Apply the same updated colors to:
- Per-city timeline bars
- The bottom slider bar
- The legend dots

---

## After fixing, verify:
1. App feels responsive — no lag when clicking, switching groups, or dragging slider
2. Double-clicking a pill expands it inline with rename field, char count, and trash
3. Other pills stay visible during editing
4. Deleting a group doesn't close the popover
5. 📍 icon is in the top bar next to 24h toggle
6. Tapping 📍 shows dropdown of cities in current group
7. Selecting a city from dropdown sets it as home
8. Home city shows 📍 next to flag, "You" label, brighter name
9. Green zones on timeline bars are immediately eye-catching
10. Yellow and red are clearly secondary to green
