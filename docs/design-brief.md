# Design Brief: Timezone App — macOS Menubar Popover (v4 Final)

Use this document as the complete reference to build the app's UI.
The approved interactive prototype is in `docs/design-mockup-v4.jsx`.

---

## Overview

A macOS menubar popover app for converting timezones. The design is **dark glassmorphism** — frosted glass panels with warm translucency, soft indigo accents, and muted color-coded timeline bars. It drops down from the macOS menubar.

---

## Global Design Tokens

### Glass Effect
- **Popover background:** `rgba(255, 255, 255, 0.08)`
- **Backdrop filter:** `blur(60px) saturate(1.6)`
- **Border:** `0.5px solid rgba(255, 255, 255, 0.12)`
- **Shadow:** `0 24px 80px rgba(0,0,0,0.35), 0 8px 32px rgba(0,0,0,0.2), inset 0 0.5px 0 rgba(255,255,255,0.15), inset 0 -0.5px 0 rgba(255,255,255,0.05)`
- **SwiftUI equivalent:** `.ultraThinMaterial` or `.regularMaterial`

### Background (for website / marketing — the app popover floats over whatever is on screen)
- **Gradient:** `linear-gradient(160deg, #1a1520 0%, #2d2235 25%, #1e2a3a 50%, #1a2332 75%, #151820 100%)`
- **Ambient blobs:** Purple `rgba(139, 92, 246, 0.08)`, Blue `rgba(59, 130, 246, 0.06)`, Warm `rgba(217, 175, 135, 0.05)` — all with large blur
- **Saved as:** `docs/midnight-aurora-background.css`

### Text Colors (all rgba white with varying opacity)
- **Primary text:** `rgba(255, 255, 255, 0.88)`
- **Secondary text:** `rgba(255, 255, 255, 0.3)`
- **Subtle/disabled:** `rgba(255, 255, 255, 0.15–0.18)`
- **Home city text:** `rgba(200, 210, 255, 0.95)` (slightly brighter with indigo tint)
- **Time display:** `rgba(255, 255, 255, 0.85)`, font-weight 300

### Accent Color
- **Indigo:** `rgba(167, 180, 255)` — used at varying opacities:
  - Active menubar dot: `rgba(167, 180, 255, 0.7)` with `0 0 8px rgba(167, 180, 255, 0.35)` glow
  - Now marker on slider: `rgba(167, 180, 255, 0.5)`
  - Date label (Tomorrow/Yesterday): `rgba(167, 180, 255, 0.55)`
  - Current time display: `rgba(167, 180, 255, 0.6)`

### Timeline Bar Colors (3 states)
- **Available (green):** `rgba(134, 214, 177, 0.75)` — roughly 9am–5pm local
- **Heads up (yellow):** `rgba(229, 195, 120, 0.65)` — roughly 7–9am and 5–9pm local
- **Sleeping (red):** `rgba(205, 133, 133, 0.55)` — roughly 9pm–7am local

### Interactive Element Colors
- **Search bar background:** `rgba(255, 255, 255, 0.06)` with `0.5px solid rgba(255, 255, 255, 0.08)` border
- **Settings gear button:** Same as search bar, 32×32px, rounded 10px
- **Active pill:** `rgba(255, 255, 255, 0.14)` with `0.5px solid rgba(255, 255, 255, 0.15)` + backdrop blur
- **Inactive pill:** `rgba(255, 255, 255, 0.04)` with `0.5px solid rgba(255, 255, 255, 0.08)`
- **Pill hover (inactive):** `rgba(255, 255, 255, 0.08)`
- **Row hover:** `rgba(255, 255, 255, 0.03)`
- **Divider lines:** `rgba(255, 255, 255, 0.06)`, 0.5px height
- **Slider dot:** `rgba(255, 255, 255, 0.95)`, 18px diameter, shadow `0 1px 8px rgba(0,0,0,0.15)`

### Typography
- **Font family:** SF Pro Display / SF Pro Text (system font) — `-apple-system, BlinkMacSystemFont, "SF Pro Display", "Helvetica Neue", system-ui, sans-serif`
- **Menubar text:** SF Mono, 12px, weight 400, `rgba(255,255,255,0.8)`
- **City name:** 13.5px, weight 500, primary text color
- **Home city name:** 13.5px, weight 600, home city text color
- **Offset label:** 10.5px, weight 400, secondary text color
- **Time display:** 21px, weight 300 (light), `rgba(255,255,255,0.85)`, tabular-nums, letter-spacing -0.02em
- **Date label (Today):** 9.5px, weight 400, `rgba(255,255,255,0.2)`
- **Date label (Tomorrow/Yesterday):** 9.5px, weight 500, `rgba(167, 180, 255, 0.55)`
- **Search placeholder:** 13px, weight 400, secondary text color
- **Pill label (active):** 12px, weight 600, `rgba(255,255,255,0.9)`
- **Pill label (inactive):** 12px, weight 400, `rgba(255,255,255,0.35)`
- **Slider offset text:** 11px, weight 400, secondary text color
- **Current time display:** 12.5px, weight 400, indigo accent
- **Legend text:** 10px, weight 400, `rgba(255,255,255,0.25)`
- **Range labels (-24h/+24h):** 9.5px, weight 400, `rgba(255,255,255,0.18)`

### Spacing & Sizing
- **Popover width:** 370px
- **Popover corner radius:** 22px
- **Outer padding:** 24px horizontal, 20px top, 14px bottom (above city list)
- **City row padding:** 12px vertical, 24px horizontal
- **Timeline bar width:** ~120px (flex, centered between name and time)
- **Timeline bar height:** 3px, fully rounded ends
- **Vertical scrub line on timeline:** 1px wide, 9px tall, `rgba(255, 255, 255, 0.45)`
- **Pill height:** ~30px (6px vertical padding + 12px font + 6px), corner radius 20px (fully rounded)
- **Pill horizontal padding:** 16px
- **Pill gap:** 6px
- **Search bar height:** ~36px (9px vertical padding), corner radius 12px
- **Flag emoji size:** 20px font-size, 26px container width
- **Menubar toggle dot:** 7px diameter
- **Remove ×:** 11px font-size, `rgba(255,255,255,0.12)` default, 0.4 on hover
- **Divider margin:** 0 24px (inset from edges)
- **Slider area padding:** 10px top, 24px horizontal, 14px bottom (before legend)
- **Legend padding:** 0 24px horizontal, 16px bottom

---

## Layout: Popover Panel

Stack vertically, top to bottom:

### Section 1: Search Bar + Settings Gear
```
[ 🔍  Add city...                              ] [ ⚙ ]
```
- No close × button — popover closes on outside click
- Search bar takes full available width
- Gear button: 32×32px, separated by 10px gap

### Section 2: Group Pills
```
      [ Work ]  [ Family ]  [ Travel ]
```
- Centered horizontally, 6px gap
- 14px margin-top from search bar

### Section 3: City List

Each city row:
```
🇰🇷  Seoul     ▬▬▬▬▬▬▬▬▬▬▬▬|▬▬▬▬▬▬▬    20:34  ● ✕
     +1h        (timeline bar)              Today
```

Home city row:
```
🇮🇩📍 Bali     ▬▬▬▬▬▬▬▬▬▬▬▬|▬▬▬▬▬▬▬    19:34  ● ✕
     You        (timeline bar)              Today
```

- Flag (26px) → Name+offset (72px min) → Timeline bar (flex) → Time+date (58px min) → Dot (7px) → × (11px)
- Home city has: 📍 overlaid on flag, "You" instead of offset, brighter name, subtle radial glow behind flag area
- Date always visible: "Today" subtle, "Tomorrow"/"Yesterday" brighter indigo — fixed 13px height to prevent layout shift
- 0.5px dividers between rows, inset 24px from edges

### Section 4: Slider Area
```
+10h from now                            ⏱ 19:34
[=====RED—YELLOW—GREEN———|——●——GREEN—YELLOW—RED=====]
-24h                                          +24h
```
- Top row: offset label (left), clickable current time with clock icon (right)
- The `|` is the permanent "now" marker (indigo, appears when dot moves away from center)
- The `●` is the draggable white dot
- Color bar is the slider track (no separate track)
- 0.5px divider above this section

### Section 5: Legend
```
            ● Available  ● Heads up  ● Sleeping
```
- Centered, 18px gap between items
- 5px colored dots + 10px text
- Sits inside the popover, below everything

---

## Layout: Menubar Compact View

```
◉  SEL 20:34  ·  BAL 19:34
```
- Glass background: `rgba(255, 255, 255, 0.06)` + 30px backdrop blur
- Border: `0.5px solid rgba(255,255,255,0.1)`
- Corner radius: 10px
- Padding: 7px 18px
- Font: SF Mono, 12px, weight 400, `rgba(255,255,255,0.8)`
- Cities separated by ` · ` (middot with spaces)
- Only cities with active menubar toggle dot are shown

---

## States to Build in Paper / Mockup

### Frame 1: Default State
- Popover open, "Work" group active, 4 cities
- Slider at center (Now), vertical line at center
- Seoul (+1h), Bali (Same/You/home), Amsterdam (-7h), San Francisco (-16h)
- Seoul and Bali have active menubar dots, Amsterdam and SF inactive
- All date labels show "Today"

### Frame 2: Slider Scrubbed (+10h)
- Slider dragged right, now marker visible at center
- Seoul and Bali show "Tomorrow", Amsterdam and SF show "Today"
- All times shifted +10h
- Offset label shows "+10h from now"

### Frame 3: Different Group Selected
- "Family" pill active
- London, Tokyo, Sydney showing
- Different menubar dot states

### Frame 4: Menubar View
- Dark macOS menubar strip with compact time display

---

## City Data for Mockups

**Work group:**
| City | Flag | Offset | Time | UTC | Home | Menubar |
|------|------|--------|------|-----|------|---------|
| Seoul | 🇰🇷 | +1h | 20:34 | +9 | No | Yes |
| Bali | 🇮🇩 | You | 19:34 | +8 | Yes | Yes |
| Amsterdam | 🇳🇱 | -7h | 12:34 | +1 | No | No |
| San Francisco | 🇺🇸 | -16h | 03:34 | -8 | No | No |

**Family group:**
| City | Flag | Offset | Time | UTC | Home | Menubar |
|------|------|--------|------|-----|------|---------|
| London | 🇬🇧 | -8h | 11:34 | +0 | No | Yes |
| Tokyo | 🇯🇵 | +1h | 20:34 | +9 | No | No |
| Sydney | 🇦🇺 | +3h | 22:34 | +11 | No | Yes |

---

## Key Design Principles

1. **Everything is translucent** — no solid colors. Every surface uses rgba with opacity.
2. **Hierarchy through opacity** — primary content at 0.85–0.9 opacity, secondary at 0.3, disabled at 0.15.
3. **Indigo is the only accent** — don't introduce other accent colors.
4. **Minimal chrome** — no borders heavier than 0.5px, no solid backgrounds, no heavy shadows on inner elements.
5. **The glass IS the design** — the backdrop blur and translucency do the heavy lifting.
6. **Timeline bars blend in** — they use muted, transparent colors that feel part of the glass, not sitting on top of it.
7. **Consistent date labels** — always show Today/Tomorrow/Yesterday to prevent layout shift.
