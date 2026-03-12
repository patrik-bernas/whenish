# Timezone Converter for macOS

## Summary
A free, open-source macOS menubar timezone converter with a dark glassmorphism aesthetic. Users track times across multiple cities organized into switchable groups, visualize each city's availability with color-coded timeline bars, and scrub through time with an interactive slider featuring a vertical line that connects all timelines. Distributed via GitHub (no App Store).

## User Story
As someone who works or communicates across multiple timezones, I want a lightweight menubar app that shows me the current time in my important cities — and lets me quickly see when people are available — so that I can schedule calls and messages at respectful hours.

---

## Project Scope

This project has **three deliverables**:

### 1. The macOS App (core product)
A native macOS menubar application built with Swift/SwiftUI.

### 2. The Website
A simple one-page marketing/landing site with a hero section, feature highlights, and a download button linking to the GitHub releases page.

### 3. The GitHub Repo
An open-source repository with a polished README and GitHub Releases for distribution (.dmg or .zip). No App Store distribution.

---

## App Features & Acceptance Criteria

### Menubar Icon & Compact View
- [ ] App lives in the macOS menubar
- [ ] Menubar displays abbreviated city times for user-selected cities (e.g. `SEL 20:34 · BAL 19:34`)
- [ ] Cities shown in menubar are controlled by a per-city toggle dot inside the popover
- [ ] Clicking the menubar icon opens a popover panel
- [ ] Clicking outside the popover closes it (no close × button)

### Popover Panel — Layout (top to bottom)
- [ ] **Search bar** — full width with magnifying glass icon and placeholder "Add city..."
- [ ] **Settings gear** — sits to the right of the search bar (no close × button)
- [ ] **Group pills** — up to 3 groups displayed as pill buttons below the search bar
- [ ] **City list** — shows cities in the active group (max 6 per group)
- [ ] **Slider area** — offset label, current time display, merged slider/color bar, -24h/+24h labels
- [ ] **Legend** — "Available · Heads up · Sleeping" at the very bottom inside the popover

### City Row — Each row displays:
- [ ] Country flag emoji (with 📍 indicator if this is the user's home city)
- [ ] City name (slightly brighter if home city)
- [ ] Time offset from local time (e.g. `+7h`, `-9h`) or "You" if home city
- [ ] Small **per-city color timeline bar** showing availability across 24 hours
- [ ] Vertical scrub line on the timeline bar, aligned with the slider position
- [ ] Current time (updated live), large, font-weight 300 (light)
- [ ] **Date label** always visible below the time: "Today" (subtle), "Tomorrow" or "Yesterday" (brighter indigo) — always rendered to prevent layout shift
- [ ] **Menubar toggle dot** — small circle; illuminated indigo when active, dim gray when inactive; click to toggle
- [ ] **Remove button** (×) — subtle, brightens on hover
- [ ] Faint horizontal divider line (0.5px) between city rows

### Per-City Timeline Bar — Color Coding (3 states)
- [ ] **Green / "Available":** Working hours, roughly 9am–5pm local — `rgba(134, 214, 177, 0.75)`
- [ ] **Yellow / "Heads up":** Early morning or evening, roughly 7–9am and 5–9pm local — `rgba(229, 195, 120, 0.65)`
- [ ] **Red / "Sleeping":** Night hours, roughly 9pm–7am local — `rgba(205, 133, 133, 0.55)`
- [ ] Each city's bar is aligned horizontally so the same x-position = the same moment in time
- [ ] Bars are 3px tall with fully rounded ends

### Time Slider
- [ ] The slider dot sits directly **on** the bottom color bar (merged — no separate slider track)
- [ ] Scrub range: -24 hours to +24 hours from now
- [ ] A **continuous vertical line** extends from the slider position through every per-city timeline bar above
- [ ] When the slider moves, all displayed times and date labels update accordingly
- [ ] Offset label on the left (e.g. `+10h from now` or `Now`)
- [ ] **Current local time** displayed on the right with a clock icon (e.g. `⏱ 19:34`) — clicking it resets the slider to Now
- [ ] A **permanent "Now" marker** on the slider bar — a small indigo vertical line at the center position that becomes visible when the dot is dragged away, providing a visual reference for how far from "now" you've scrubbed. Hidden when the dot is at center.
- [ ] Dot: 18px white circle with subtle shadow

### Timezone Groups
- [ ] Up to **3 groups** maximum
- [ ] Groups appear as pill-shaped buttons below the search bar
- [ ] Tapping a pill switches the city list to that group
- [ ] Each group holds up to **6 cities**
- [ ] Users can name/rename groups
- [ ] **12-character maximum** for group names to prevent pill overflow
- [ ] Users can add and remove cities from groups

### Settings
- [ ] Accessible via a gear icon (⚙) to the right of the search bar
- [ ] **Time format toggle**: 12-hour or 24-hour display
- [ ] **Home timezone setting**: user selects their city/timezone, which gets the 📍 indicator, brighter name, and "You" offset label
- [ ] Group name management (rename, max 12 characters)
- [ ] Keep settings minimal for v1

### Search & Add City
- [ ] Search field with autocomplete for city/timezone names
- [ ] Adding a city places it in the currently active group
- [ ] If the group is full (6 cities), show an appropriate message

---

## Website Acceptance Criteria
- [ ] Single-page site (HTML/CSS/JS or a simple framework)
- [ ] Hero section with app name, tagline, and a screenshot/mockup
- [ ] Feature highlights section (key differentiators)
- [ ] Download button linking to the GitHub releases page
- [ ] Dark aesthetic matching the app's glassmorphism vibe
- [ ] Mobile-responsive

---

## GitHub Repo Acceptance Criteria
- [ ] Public repository
- [ ] Polished README with: app description, screenshots, installation instructions, build instructions, and license
- [ ] GitHub Releases with downloadable `.dmg` or `.zip` for each version
- [ ] MIT license

---

## Affected Screens & Components

| Screen / Component | What It Does |
|---|---|
| Menubar compact text | Shows selected city abbreviations + times, separated by · |
| Popover panel | Main UI container with glass material background |
| Search bar + settings gear | Search to add cities, gear opens settings (no close ×) |
| Group pills | Up to 3 switchable pill buttons |
| City row | Flag, name, offset/You, timeline bar, time, date, menubar dot, remove × |
| Home city indicator | 📍 on flag, "You" label, brighter name, subtle glow |
| Per-city timeline bar | 3px horizontal color bar (green/yellow/red) per city |
| Vertical scrub line | 1px line from slider through all city timeline bars |
| Time slider + now marker | Merged slider on color bar with permanent indigo "now" reference |
| Date label | Always-visible Today/Tomorrow/Yesterday below each time |
| Legend | Available · Heads up · Sleeping at bottom of popover |
| Settings view | Time format toggle, home timezone, group management |
| Website | One-page dark-themed marketing site |
| GitHub README | Project documentation |

---

## Edge Cases & Constraints

- **Cities in different days**: Date label changes from "Today" to "Tomorrow" or "Yesterday" when scrubbing. Always visible to prevent layout shift.
- **DST transitions**: Must use proper timezone data (not hardcoded offsets). Use macOS system TimeZone APIs.
- **Empty group**: Show a friendly empty state prompting the user to add cities.
- **All 3 groups full**: Clear message when trying to add a new city and all groups have 6 cities.
- **Duplicate city**: Prevent adding the same city to the same group twice.
- **Menubar overflow**: Limit to 3–4 cities visible in the menubar. If more are toggled, show a warning or only display the first few.
- **Group name length**: Enforce 12-character maximum with visual feedback.
- **First launch**: Default one group ("Work") with the user's local timezone auto-detected and marked as home. Prompt to add more cities.
- **Persistence**: City selections, groups, home city, menubar toggles, and settings must persist across app restarts (UserDefaults).
- **macOS compatibility**: Target macOS 13 (Ventura) or later.
- **Popover dismissal**: Closes when clicking outside (standard macOS popover behavior). No close × button.

---

## Design Direction

- **Aesthetic**: Dark glassmorphism — frosted glass panels with warm translucency over a dark background
- **Glass effect**: `rgba(255, 255, 255, 0.08)` background + 60px backdrop blur + saturate(1.6) — in SwiftUI this maps to `.ultraThinMaterial` or `.regularMaterial`
- **Typography**: SF Pro Display (system font), light weight (300) for times, medium (500) for city names, all using rgba white with varying opacity
- **Accent color**: Soft indigo `rgba(167, 180, 255)` — used for active menubar dots, now marker, date highlights, and current time display
- **Timeline colors**: Muted and transparent — sage green, warm amber, soft coral (see Color Coding section)
- **Key differentiators from Pretty Timezones**: Per-city timeline bars, vertical scrub line, 3-state color coding (Available/Heads up/Sleeping), group pills, per-city menubar toggle, home city indicator, always-visible date labels, permanent "now" marker on slider
- **Full design spec**: See `docs/design-brief.md` for exact values
- **Design reference mockup**: See `docs/design-mockup-v4.jsx` for the approved interactive prototype

---

## Tech Stack & Tooling

- **App**: Swift, SwiftUI, native macOS (NSStatusItem + NSPopover)
- **Glass effect**: SwiftUI `.material` modifiers (`.ultraThinMaterial`, `.regularMaterial`)
- **Website**: Static HTML/CSS/JS one-pager
- **Development**: Codex (primary), Claude Code (code review), Conductor.build for parallel agents, Warp.dev terminal
- **Design**: Paper.design (with MCP server for AI agent integration)
- **Version control**: GitHub
- **Code review workflow**: Conductor with Claude Code or Codex for building, the other for code review on branches

---

## Out of Scope (v1)

- App Store distribution
- "Type a specific time" input feature
- 4-state availability (sticking with 3-state: Available / Heads up / Sleeping)
- Calendar integration or meeting converter
- Keyboard shortcuts
- Natural language time input
- Copy formatted times to clipboard
- Light mode / theme toggle (v1 is dark glassmorphism only)
- Configurable working hours per city (fixed defaults for v1)

---

## Open Questions

- [ ] **App name** — TBD
- [ ] **macOS minimum version** — Ventura (13)? Sonoma (14)?
- [ ] **Website domain** — Custom domain or GitHub Pages default URL?
