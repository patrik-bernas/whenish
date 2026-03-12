# Implementation Plan: Timezone Converter — macOS App

## Requirements Reference
- Requirements: `requirements/requirements-timezone-converter.md`
- Design spec: `docs/design-brief.md`
- Approved prototype: `docs/design-mockup-v4.jsx`

## Agent Strategy
**Single agent** — This is one app with sequential dependencies. Each layer builds on the previous one (models → services → ViewModel → UI). No parallelism needed.

---

## Tasks

### Task 1: Create Xcode project skeleton
- **Agent:** single
- **Files:** `src/TimezoneApp.xcodeproj`, `src/TimezoneApp/TimezoneAppApp.swift`, `src/TimezoneApp/Info.plist`
- **Action:** Create
- **Details:** Create a new macOS app project using SwiftUI lifecycle. Deployment target macOS 13.0. Set `LSUIElement = YES` in Info.plist so the app doesn't show in the Dock. This is a menubar-only app with no main window.
- **Depends on:** None

### Task 2: Set up the menubar status item and popover shell
- **Agent:** single
- **Files:** `src/TimezoneApp/AppDelegate.swift`, `src/TimezoneApp/TimezoneAppApp.swift`
- **Action:** Create / Modify
- **Details:** Create an `AppDelegate` that sets up an `NSStatusItem` in the system menubar. Clicking the status item toggles an `NSPopover` containing a SwiftUI view. Popover config: `.animates = true`, `.behavior = .transient` (closes on outside click). Status item displays text (placeholder clock emoji for now). Wire the AppDelegate into the SwiftUI app lifecycle.
- **Depends on:** Task 1

### Task 3: Define data models
- **Agent:** single
- **Files:** `src/TimezoneApp/Models/City.swift`, `src/TimezoneApp/Models/TimezoneGroup.swift`, `src/TimezoneApp/Models/AppSettings.swift`
- **Action:** Create
- **Details:**
  - `City`: id (UUID), name (String), countryCode (String), flag (String emoji), timeZoneIdentifier (String — e.g. "Asia/Seoul"), isHome (Bool), showInMenubar (Bool)
  - `TimezoneGroup`: id (UUID), name (String — max 12 characters), cities ([City] — max 6)
  - `AppSettings`: use24HourFormat (Bool), homeTimeZoneIdentifier (String?), activeGroupId (UUID?)
  - All conform to `Codable` for persistence.
- **Depends on:** Task 1

### Task 4: Build persistence service
- **Agent:** single
- **Files:** `src/TimezoneApp/Services/PersistenceService.swift`
- **Action:** Create
- **Details:** Saves and loads `[TimezoneGroup]` and `AppSettings` to/from `UserDefaults` using JSON encoding. Methods: `saveGroups`, `loadGroups`, `saveSettings`, `loadSettings`. Include default data for first launch: one group named "Work" with the user's system timezone auto-detected and marked as home.
- **Depends on:** Task 3

### Task 5: Build timezone calculation service
- **Agent:** single
- **Files:** `src/TimezoneApp/Services/TimezoneService.swift`
- **Action:** Create
- **Details:** Provides all time-related calculations:
  - `currentTime(in timeZone: TimeZone, offsetHours: Double) -> Date`
  - `formattedTime(date: Date, use24Hour: Bool) -> String` (e.g. "20:34" or "8:34 PM")
  - `offsetLabel(from home: TimeZone, to target: TimeZone) -> String` (e.g. "+1h", "-7h", "Same")
  - `dayLabel(for date: Date, relativeTo reference: Date) -> String` ("Today", "Tomorrow", "Yesterday")
  - `availabilityState(for hour: Int) -> AvailabilityState` — `.available` (9–17), `.headsUp` (7–9 & 17–21), `.sleeping` (21–7)
  - Uses Apple's `TimeZone` API exclusively — never hardcode offsets. Handles DST automatically.
- **Depends on:** Task 3

### Task 6: Build city search service
- **Agent:** single
- **Files:** `src/TimezoneApp/Services/CitySearchService.swift`
- **Action:** Create
- **Details:** Provides city search/autocomplete using `TimeZone.knownTimeZoneIdentifiers` as base dataset. Maps each identifier to a displayable city name, country, and flag emoji. `search(query: String) -> [CitySearchResult]` fuzzy-matches city names. Include a curated mapping of common cities (e.g. "Asia/Seoul" → "Seoul", "South Korea", "🇰🇷").
- **Depends on:** Task 3

### Task 7: Build the main ViewModel
- **Agent:** single
- **Files:** `src/TimezoneApp/ViewModels/TimezoneViewModel.swift`
- **Action:** Create
- **Details:** `@Observable` class (or `ObservableObject` for macOS 13 compat), single source of truth:
  - Properties: `groups`, `settings`, `activeGroupIndex`, `scrubberOffset` (-24 to +24, default 0), `searchQuery`, `searchResults`, `isSettingsOpen`
  - Computed: `activeGroup`, `menubarCities`, `offsetLabel`, `currentLocalTimeString`
  - Methods: `addCity`, `removeCity`, `toggleMenubar`, `switchGroup`, `setHomeTimezone`, `renameGroup`, `resetScrubber`
  - On init: load from PersistenceService. On any mutation: save back.
  - Updates NSStatusItem text when menubar cities or scrubber offset change.
- **Depends on:** Tasks 4, 5, 6

### Task 8: Build the PopoverView (main container)
- **Agent:** single
- **Files:** `src/TimezoneApp/Views/PopoverView.swift`
- **Action:** Create
- **Details:** Root SwiftUI view inside the popover. `.background(.ultraThinMaterial)` for glass effect. 370px wide, rounded 22px. Stacks vertically: SearchBarView → GroupPillsView → city list (ForEach) → TimeSliderView → LegendView. Takes `TimezoneViewModel` as environment object.
- **Depends on:** Task 7

### Task 9: Build the SearchBarView
- **Agent:** single
- **Files:** `src/TimezoneApp/Views/SearchBarView.swift`
- **Action:** Create
- **Details:** Search text field (magnifying glass icon, "Add city..." placeholder, rounded 12px, glass-tinted background) + settings gear button (32×32px, rounded 10px). No close × button. Typing updates `viewModel.searchQuery` and shows results in a dropdown overlay. Tapping a result calls `viewModel.addCity()` and clears search. Shows message if active group is full.
- **Depends on:** Task 8

### Task 10: Build the GroupPillsView
- **Agent:** single
- **Files:** `src/TimezoneApp/Views/GroupPillsView.swift`
- **Action:** Create
- **Details:** Centered row of up to 3 pill buttons. Active: `rgba(255,255,255,0.14)` background, 0.15 border, bold white text. Inactive: `rgba(255,255,255,0.04)`, dim text. Fully rounded. Tapping switches `viewModel.activeGroupIndex`. 6px gap, 14px top margin.
- **Depends on:** Task 8

### Task 11: Build the TimelineBarView
- **Agent:** single
- **Files:** `src/TimezoneApp/Views/TimelineBarView.swift`
- **Action:** Create
- **Details:** Draws a 3px horizontal color bar for a city's 24-hour availability. Takes city's TimeZone + scrubber offset. Width ~120px (flex), fully rounded ends. Colors: available `rgba(134,214,177,0.75)`, headsUp `rgba(229,195,120,0.65)`, sleeping `rgba(205,133,133,0.55)`. Segments positioned by actual timezone offset so same x = same moment across all cities. Overlays 1px white vertical scrub line at scrubber position.
- **Depends on:** Task 5

### Task 12: Build the CityRowView
- **Agent:** single
- **Files:** `src/TimezoneApp/Views/CityRowView.swift`
- **Action:** Create
- **Details:** Horizontal layout: Flag (20px, 26px container) → Name+offset (min 72px) → TimelineBarView (flex) → Time+date (min 58px, right) → Menubar dot (7px) → Remove × (11px).
  - Home city: 📍 overlay on flag, "You" offset, brighter name, subtle glow
  - Time: 21px, weight .light, tabular nums
  - Date: always visible, fixed height — "Today" subtle, "Tomorrow"/"Yesterday" brighter indigo
  - Menubar dot: indigo glow when active, dim gray when inactive, tappable
  - Remove ×: very subtle, brightens on hover
  - Row hover: background lightens slightly
  - 0.5px divider below (except last row), inset 24px
  - Padding: 12px vertical, 24px horizontal
- **Depends on:** Tasks 8, 11

### Task 13: Build the TimeSliderView
- **Agent:** single
- **Files:** `src/TimezoneApp/Views/TimeSliderView.swift`
- **Action:** Create
- **Details:** Bottom slider area:
  - 0.5px divider at top
  - Top row: offset label left ("+10h from now" / "Now"), clickable current time right (clock icon + time in indigo) — click resets scrubber
  - Slider: color bar (5px, ~290px wide, same segment logic as TimelineBarView) + draggable 18px white dot via DragGesture, updates `viewModel.scrubberOffset`
  - Permanent now marker: 1.5px indigo line at center, visible only when dot is away from center
  - Bottom row: "-24h" left, "+24h" right
- **Depends on:** Task 8

### Task 14: Build the LegendView
- **Agent:** single
- **Files:** `src/TimezoneApp/Views/LegendView.swift`
- **Action:** Create
- **Details:** Centered row: green dot + "Available", yellow dot + "Heads up", red dot + "Sleeping". 5px dots, 10px text at `rgba(255,255,255,0.25)`. 18px gap. Padding: 16px bottom. Last element in popover.
- **Depends on:** Task 8

### Task 15: Build the SettingsView
- **Agent:** single
- **Files:** `src/TimezoneApp/Views/SettingsView.swift`
- **Action:** Create
- **Details:** Replaces main content when gear is tapped:
  - 12h/24h toggle
  - Home timezone picker (search and select)
  - Group rename fields (12-char max with visual feedback)
  - Back button to return to main view
  - Same glass aesthetic
- **Depends on:** Task 8

### Task 16: Wire up the menubar compact text
- **Agent:** single
- **Files:** `src/TimezoneApp/AppDelegate.swift`, `src/TimezoneApp/ViewModels/TimezoneViewModel.swift`
- **Action:** Modify
- **Details:** NSStatusItem title displays menubar cities: `SEL 20:34 · BAL 19:34`. Monospaced font. Updates every minute via Timer and immediately on scrubber move. Only shows cities where `showInMenubar == true`. Clock icon fallback if none selected. Limit 3–4 cities in display.
- **Depends on:** Task 7

### Task 17: First-launch experience
- **Agent:** single
- **Files:** `src/TimezoneApp/Services/PersistenceService.swift`, `src/TimezoneApp/ViewModels/TimezoneViewModel.swift`
- **Action:** Modify
- **Details:** On first launch (no saved data): create one group named "Work" with user's detected system timezone as home city (`TimeZone.current`), marked as home with `showInMenubar = true`. Map system timezone to city name via CitySearchService.
- **Depends on:** Tasks 4, 6, 7

### Task 18: App icon and final polish
- **Agent:** single
- **Files:** `src/TimezoneApp/Assets.xcassets/AppIcon.appiconset/`, `src/TimezoneApp/Info.plist`
- **Action:** Create / Modify
- **Details:** Simple placeholder app icon (clock or globe on dark gradient). Ensure Info.plist has correct bundle ID, version, `LSUIElement = YES`. Verify: launches as menubar-only, popover opens/closes, all interactions work, data persists across restarts.
- **Depends on:** All previous tasks

---

## Testing Checklist
- [ ] App launches as menubar-only (no dock icon, no main window)
- [ ] Clicking menubar item opens the popover
- [ ] Clicking outside the popover closes it
- [ ] Search finds cities and adds them to the active group
- [ ] Cannot add more than 6 cities to a group
- [ ] Cannot add duplicate city to the same group
- [ ] Group pills switch the displayed city list
- [ ] Group names can be renamed (max 12 chars enforced)
- [ ] Removing a city (×) works
- [ ] Per-city timeline bars show correct color segments per timezone
- [ ] Timeline bars are x-aligned (same x = same moment across all cities)
- [ ] Vertical scrub line aligns with slider position on all bars
- [ ] Dragging slider updates all times and date labels
- [ ] "Now" marker appears when scrubbed away from center
- [ ] Clicking current time resets slider to center
- [ ] Date labels always visible, no layout shift
- [ ] Menubar toggle dot works with indigo glow
- [ ] Menubar text updates correctly with monospaced font
- [ ] Home city shows 📍, "You", brighter name, glow
- [ ] 12h/24h toggle works in settings
- [ ] Home timezone can be changed in settings
- [ ] All data persists across app restart
- [ ] First launch creates default group with system timezone
- [ ] DST handled correctly

---

## Risks & Rollback
- **SwiftUI materials look different on older macOS** → Test on 13 and 14; fallback to solid dark if needed
- **NSPopover + SwiftUI integration** → Well-documented pattern; reference Apple sample code
- **City search dataset limited** → Start with `TimeZone.knownTimeZoneIdentifiers`; expand with curated JSON if needed
- **Timeline bar misalignment** → All bars must use same x-axis = UTC mapping; test with extreme offsets
- **Menubar text too long** → Enforce 3–4 city max with short abbreviations
- **Rollback:** Each task is a natural git commit point. Revert to last working commit if needed.
