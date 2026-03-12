# PRODUCT.md — Timezone App

## What is this?
A free, open-source macOS menubar timezone converter. Users click the menubar icon to see a popover with their saved cities, organized into groups, with visual availability indicators.

## Project Structure
```
timezone-app/
├── README.md
├── LICENSE
├── PRODUCT.md          ← You are here
├── CHANGELOG.md        ← Track changes here
├── requirements/       ← Feature requirements docs
├── plans/              ← Implementation plans
├── src/                ← Swift source code (Xcode project)
├── website/            ← One-page marketing site
├── docs/               ← Design briefs, additional documentation
└── .github/            ← GitHub templates, workflows
```

## Tech Stack
- **Language:** Swift
- **UI Framework:** SwiftUI
- **App Type:** macOS menubar app (NSStatusItem + NSPopover)
- **Min macOS:** 13.0 (Ventura) — TBD
- **Distribution:** GitHub Releases (.dmg or .zip)
- **Website:** Static HTML/CSS/JS one-pager

## Design Direction
- Light and playful aesthetic
- Signature feature: per-city color timeline bars with a vertical scrub line connecting them
- 3-state availability: Green (working), Yellow (early/late), Red (sleeping)
- Up to 3 timezone groups, switchable via pill buttons
- Menubar compact view shows user-selected city abbreviations + times

## Key Constraints
- No App Store distribution (direct GitHub download)
- No backend / no server — everything is local
- Must persist data across app restarts (UserDefaults or similar)
- Must handle DST transitions correctly (use system timezone data)
