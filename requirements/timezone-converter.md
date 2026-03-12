# Timezone Converter for macOS

## Summary
A free, open-source macOS menubar timezone converter app with a light, playful aesthetic. Users can track times across multiple cities organized into groups, visualize each city's availability with color-coded timeline bars, and scrub through time with an interactive slider. The project includes the native Mac app, a simple landing page website, and an open-source GitHub repo for distribution.

## User Story
As someone who works or communicates across multiple timezones, I want a lightweight menubar app that shows me the current time in my important cities — and lets me quickly see when people are available — so that I can schedule calls and messages at respectful hours.

---

## Project Scope

This project has **three deliverables**:

### 1. The macOS App (core product)
A native macOS menubar application built with Swift.

### 2. The Website
A simple one-page marketing/landing site with a hero section, feature highlights, and a download button linking to the GitHub releases page.

### 3. The GitHub Repo
An open-source repository with a polished README and GitHub Releases for distribution (.dmg or .zip). No App Store distribution — users download directly from GitHub.

---

## App Features & Acceptance Criteria

### Menubar Icon & Compact View
- [ ] App lives in the macOS menubar
- [ ] Menubar displays abbreviated city times for user-selected cities (e.g. `LA 01:59 | NY 04:59 | FR 10:59`)
- [ ] Clicking the menubar icon opens a popover panel

### Popover Panel — Layout (top to bottom)
- [ ] **Search bar** at the top — type to search and add cities
- [ ] **Group pills** — up to 3 groups displayed as pill buttons directly below the search bar; clicking a pill switches to that group
- [ ] **City list** — shows cities in the active group (max 6 per group)
- [ ] **Time slider / color bar** at the bottom

### City Row — Each row displays:
- [ ] Country flag emoji
- [ ] City name
- [ ] Time offset from local time (e.g. `+7h`, `-9h`, `Same`)
- [ ] Current time (updated live)
- [ ] Small **per-city color timeline bar** showing availability across 24 hours
- [ ] **Menubar toggle icon** — tap to include/exclude this city from the menubar compact view
- [ ] **Remove button** (×) to delete the city from the group
- [ ] Faint horizontal divider line between city rows for visual clarity

### Per-City Timeline Bar — Color Coding (3 states)
- [ ] **Green** = Working hours (good to contact, roughly 9am–5pm local)
- [ ] **Yellow** = Early morning / evening (might be okay, roughly 7–9am and 5–9pm local)
- [ ] **Red** = Sleeping hours (don't disturb, roughly 9pm–7am local)
- [ ] Each city's bar is aligned horizontally so the same x-position = the same moment in time

### Time Slider
- [ ] The slider dot sits directly **on** the bottom color bar (merged — no separate slider track)
- [ ] Scrub range: -24 hours to +24 hours from now
- [ ] A **continuous vertical line** extends upward from the slider dot through every per-city timeline bar
- [ ] When the slider moves, all displayed times update to reflect the selected offset
- [ ] Display the offset label (e.g. `+2h 10m from now`) near the slider
- [ ] A "Now" button resets the slider to the current time

### Timezone Groups
- [ ] Up to **3 groups** maximum
- [ ] Groups appear as pill-shaped buttons below the search bar
- [ ] Tapping a pill switches the city list to that group
- [ ] Each group holds up to **6 cities**
- [ ] Users can name/rename groups
- [ ] Users can add and remove cities from groups

### Settings
- [ ] Accessible via a gear icon in the popover
- [ ] **Time format toggle**: 12-hour or 24-hour display
- [ ] Any other necessary preferences (TBD — keep minimal for v1)

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
- [ ] Clean, light aesthetic matching the app's playful vibe
- [ ] Mobile-responsive

---

## GitHub Repo Acceptance Criteria
- [ ] Public repository
- [ ] Polished README with: app description, screenshots, installation instructions, build instructions, and license
- [ ] GitHub Releases with downloadable `.dmg` or `.zip` for each version
- [ ] Open-source license (MIT)

---

## Affected Screens & Components

| Screen / Component | What It Does |
|---|---|
| Menubar icon + compact text | Shows selected city times in the macOS menubar |
| Popover panel | Main UI — search, groups, city list, slider |
| City row | Flag, name, offset, time, timeline bar, menubar toggle, remove |
| Per-city timeline bar | Horizontal color bar (green/yellow/red) per city |
| Time slider + vertical line | Merged slider on bottom color bar with vertical line through all rows |
| Group pills | Up to 3 switchable pill buttons below search |
| Settings view | Gear icon opens time format toggle + any other prefs |
| Website | One-page marketing site |
| GitHub README | Project documentation |

---

## Edge Cases & Constraints

- **Cities in different days**: When the slider is scrubbed far enough, some cities may show a different date (e.g. "Thu, Feb 5"). This should be indicated on the city row.
- **DST transitions**: Timezone offsets change during Daylight Saving Time transitions. The app must use proper timezone data (not hardcoded offsets).
- **Empty group**: If a group has no cities, show a friendly empty state prompting the user to add cities.
- **All 3 groups full**: If all groups are at capacity, the user should get a clear message when trying to add a new city.
- **Duplicate city**: Prevent adding the same city to the same group twice.
- **Menubar overflow**: If many cities are toggled for menubar display, the text could get too long. Consider a max (e.g. 3–4 cities in menubar) or truncation.
- **First launch**: On first open, provide a sensible default (e.g. one group with the user's local timezone pre-filled, empty otherwise).
- **Persistence**: City selections, groups, and settings must persist across app restarts.
- **macOS compatibility**: Target macOS 13 (Ventura) or later (TBD — depends on Swift API needs).

---

## Design Direction

- **Aesthetic**: Light and playful — similar to Pretty Timezones' light mode but with our own identity
- **Key differentiator from Pretty Timezones**: Per-city timeline bars with vertical scrub line connecting them all, plus timezone groups
- **The vertical line + per-city bars is the signature interaction** — it makes the time relationship between cities immediately visual
- **Full design brief**: See `docs/design-brief.md` for exact colors, typography, spacing, and layout

---

## Tech Stack & Tooling

- **App**: Swift, SwiftUI, native macOS (menubar app with popover)
- **Website**: Simple HTML/CSS/JS one-pager (or lightweight framework)
- **Development**: Claude Code in Cursor, Conductor.build for parallel agents, Warp.dev terminal
- **Version control**: GitHub
- **Design tool**: Paper.design (with MCP server for AI agent integration)
- **Code review workflow goal**: Use Conductor with Claude Code or Codex for building, the other for code review on branches

---

## Out of Scope (v1)

- App Store distribution (direct GitHub download only)
- "Type a specific time" input feature
- 4-state availability (Working/Awake/Annoying/Sleeping) — using simplified 3-state (Green/Yellow/Red)
- Calendar integration or meeting converter
- Keyboard shortcuts
- Natural language time input
- Copy formatted times to clipboard
- Multiple themes or dark mode (v1 is light/playful only)

---

## Open Questions

- [ ] **App name** — TBD
- [ ] **macOS minimum version** — Ventura (13)? Sonoma (14)?
- [ ] **Working hours definition** — Are green/yellow/red boundaries configurable per city, or fixed defaults (e.g. 9–5 green, 7–9 & 5–9 yellow, 9pm–7am red)?
- [ ] **Website domain** — Will you buy a custom domain or use GitHub Pages default URL?
