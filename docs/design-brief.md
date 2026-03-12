# Design Brief: Timezone App — macOS Menubar Popover

Use this document as a complete reference to build the app's UI mockup in Paper.design.
Read the entire brief before starting. Build each section as a separate frame in Paper.

---

## Overview

This is a macOS menubar popover app for converting timezones. The design is **light, playful, and modern** — think soft colors, rounded corners, and a clean layout. It drops down from the macOS menubar.

---

## Global Design Tokens

### Colors
- **Background:** `#EAF4FB` (soft sky blue)
- **Card/Popover background:** `#FFFFFF` with 80% opacity (frosted glass feel)
- **Text primary:** `#1A1A2E` (near-black)
- **Text secondary:** `#6B7280` (gray, for offsets and labels)
- **Time text:** `#1A1A2E`, bold, large
- **Search bar background:** `#F0F4F8`
- **Search bar border:** `#D1D5DB`
- **Pill active background:** `#3B82F6` (blue)
- **Pill active text:** `#FFFFFF`
- **Pill inactive background:** `#E5E7EB` (light gray)
- **Pill inactive text:** `#6B7280`
- **Divider lines:** `#E5E7EB` at 50% opacity
- **Slider dot:** `#FFFFFF` with subtle shadow
- **Vertical scrub line:** `#94A3B8` at 60% opacity, 1px wide

### Timeline Bar Colors (3 states)
- **Green (Working):** `#22C55E` — roughly 9am–5pm local
- **Yellow (Early/Late):** `#FACC15` — roughly 7–9am and 5–9pm local
- **Red (Sleeping):** `#EF4444` — roughly 9pm–7am local

### Typography
- **Font family:** SF Pro (system font) or Inter as fallback
- **City name:** 15px, semibold
- **Time display:** 28px, bold, monospace-style
- **Offset label:** 12px, regular, secondary color
- **Search placeholder:** 14px, regular, secondary color
- **Pill labels:** 13px, medium

### Spacing & Sizing
- **Popover width:** 360px
- **Popover corner radius:** 16px
- **Row height:** ~72px (to accommodate city info + timeline bar)
- **Timeline bar height:** 6px, rounded ends (3px radius)
- **Pill height:** 28px, corner radius 14px (fully rounded)
- **Search bar height:** 36px, corner radius 10px
- **Padding (outer):** 16px
- **Padding between elements:** 12px
- **Flag emoji size:** 24px

---

## Layout: Popover Panel (Main Frame)

Build this as a single frame, 360px wide. Stack vertically, top to bottom:

### Section 1: Search Bar Row
```
[ 🔍  Add city...                          ⚙️  ✕ ]
```
- Full width minus padding (328px)
- Left: magnifying glass icon (gray)
- Center: placeholder text "Add city..." in secondary color
- Right: gear icon for settings + close button (✕)
- Background: `#F0F4F8`, border: 1px `#D1D5DB`, rounded 10px
- The gear and close button sit outside the search input, right-aligned in the row

### Section 2: Group Pills Row
```
[ 🔵 Work ]  [ ○ Family ]  [ ○ Travel ]
```
- 3 pill buttons, horizontally centered, 8px gap between them
- Active pill: blue background (`#3B82F6`), white text
- Inactive pills: light gray background (`#E5E7EB`), gray text
- Fully rounded (pill shape)
- 12px horizontal padding inside each pill

### Section 3: City List (up to 6 rows)

Each city row contains two visual sub-rows stacked:

**Sub-row A: City Info**
```
🇰🇷  Seoul                              20:34   ● ✕
     +1h
```
- Left: Flag emoji (24px) + city name (semibold) + offset below in smaller gray text
- Right: Time in large bold text + menubar toggle dot + remove ✕
- The menubar toggle is a small filled circle:
  - Active (shown in menubar): `#3B82F6` (blue)
  - Inactive (not in menubar): `#D1D5DB` (gray)
  - Tapping toggles it

**Sub-row B: Per-City Timeline Bar**
```
[RED——YELLOW—GREEN————————GREEN—YELLOW——RED]
```
- Sits directly below the city info, left-aligned with the city name (indented past the flag)
- Width: ~280px (full row width minus flag indent and right padding)
- Height: 6px, fully rounded ends
- Colors represent that city's local 24-hour cycle:
  - The bar is a horizontal gradient/segmented bar showing:
    - Red (sleeping) → Yellow (early morning) → Green (working) → Yellow (evening) → Red (sleeping)
  - The segments shift based on each city's timezone offset
  - Example: If it's 12:00 UTC, Seoul (+9h) would show green in a different position than San Francisco (-8h)

**Divider**
- 1px line, `#E5E7EB` at 50% opacity, full width between each city row

### Section 4: Slider Area
```
+2h 10m from now                         ⏱ Now
[====RED—YELLOW—GREEN————●———GREEN—YELLOW—RED====]
 -24h                                        +24h
```
- **Top row:** Left shows the offset label ("Now" or "+2h 10m from now"), right shows a "Now" reset button with a small clock icon
- **The slider bar:** This is the MERGED element — the color bar IS the slider track
  - Full width (328px), height 8px, rounded
  - Same red-yellow-green-yellow-red pattern but represents aggregate/reference city times
  - A white circle (slider dot) sits ON the color bar
  - Dot size: 20px diameter, white fill, subtle drop shadow (`0 1px 3px rgba(0,0,0,0.2)`)
  - Dot is draggable left-right
- **Bottom row:** "-24h" label left, "+24h" label right, small gray text

### Section 5: Vertical Scrub Line (interactive element — describe visually)
- A thin vertical line (1px, `#94A3B8` at 60% opacity) extends from the slider dot straight up through every per-city timeline bar
- This line visually connects the same moment in time across all cities
- In the mockup, show this as a dashed or semi-transparent vertical line cutting through all rows

---

## Layout: Menubar Compact View (Separate Frame)

Build this as a second frame showing the macOS menubar appearance:

```
🕐 LA 01:59 | NY 04:59 | FR 10:59
```
- Small frame, dark background (`#2D2D2D`) to represent the macOS menubar
- Left: small clock icon or app icon
- Text: city abbreviations + times separated by ` | `
- Font: 12px, SF Mono or monospace, `#FFFFFF`
- This is what the user sees WITHOUT opening the popover

---

## States to Mockup

Create these as separate frames or variants in Paper:

### Frame 1: Default State
- Popover open, "Work" group active, 4 cities showing
- Slider at center (Now position)
- Vertical line at center
- Example cities: Seoul (+1h), Bali (Same time), Amsterdam (-7h), San Francisco (-16h)
- 2 cities have menubar toggle active (blue dot), 2 inactive (gray dot)

### Frame 2: Slider Scrubbed
- Same as Frame 1 but slider dragged right (+3h)
- All times shifted accordingly
- Vertical line moved right
- Offset label shows "+3h from now"

### Frame 3: Search Active
- Search bar focused with "san f" typed
- Dropdown below search showing: "San Francisco, United States" as a suggestion
- City list slightly dimmed or pushed down

### Frame 4: Different Group Selected
- "Family" pill active instead of "Work"
- Different set of cities showing (e.g., London, Tokyo, Sydney)
- Shows that switching groups changes the entire city list

### Frame 5: Menubar View
- Just the macOS menubar strip showing the compact time display

---

## City Data for Mockups

Use these for the "Work" group:
| City | Country | Flag | Offset from Bali (WITA) | Sample Time |
|------|---------|------|------------------------|-------------|
| Seoul | South Korea | 🇰🇷 | +1h | 20:34 |
| Bali | Indonesia | 🇮🇩 | Same time | 19:34 |
| Amsterdam | Netherlands | 🇳🇱 | -7h | 12:34 |
| San Francisco | USA | 🇺🇸 | -16h | 03:34 |

Use these for the "Family" group:
| City | Country | Flag | Offset from Bali (WITA) | Sample Time |
|------|---------|------|------------------------|-------------|
| London | UK | 🇬🇧 | -8h | 11:34 |
| Tokyo | Japan | 🇯🇵 | +1h | 20:34 |
| Sydney | Australia | 🇦🇺 | +3h | 22:34 |

---

## Visual Reference

This app is inspired by Pretty Timezones (https://prettytimezones.com) but with key differences:
1. **Per-city timeline bars** instead of one aggregate bar at the bottom
2. **Vertical scrub line** connecting slider to all city timelines
3. **3-state color coding** (green/yellow/red) instead of 4 states
4. **Group pills** for switching between city sets
5. **Per-city menubar toggle** icon on each row
6. **Faint dividers** between city rows
7. **Light, playful aesthetic** — not dark themed

---

## Notes for Implementation

- The timeline bars should be ACCURATE — each city's bar should reflect its actual timezone offset. Seoul's "green zone" (working hours) appears at a different horizontal position than San Francisco's.
- The vertical scrub line must be perfectly aligned from the slider dot through every timeline bar.
- Flags should be emoji, not images.
- Keep the design clean — resist the urge to add too many elements. White space is good.
