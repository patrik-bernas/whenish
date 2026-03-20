# PRODUCT.md — Whenish

## What is this?
A free, open-source macOS menubar timezone converter with a dark glassmorphism aesthetic. Users click the menubar icon to see a frosted-glass popover with their saved cities, organized into switchable groups, with visual availability timeline bars and a time scrubber.

## Project Structure
```
timezone-app/
├── README.md               ← GitHub-facing project description
├── LICENSE                  ← MIT license
├── PRODUCT.md               ← You are here — app context for AI agents
├── CHANGELOG.md             ← Track changes
├── requirements/
│   └── timezone-converter.md ← Full requirements spec
├── plans/                   ← Implementation plans (created by /plan)
├── docs/
│   ├── design-brief.md      ← Pixel-perfect design spec for Paper & SwiftUI
│   ├── design-mockup-v4.jsx ← Approved interactive React prototype (reference only)
│   └── midnight-aurora-background.css ← Reusable background gradient
├── src/                     ← Swift source code (Xcode project)
├── website/                 ← One-page marketing site
└── .github/                 ← GitHub templates, workflows
```

## Tech Stack
- **Language:** Swift
- **UI Framework:** SwiftUI
- **App Type:** macOS menubar app (NSStatusItem + NSPopover)
- **Glass Effect:** SwiftUI `.ultraThinMaterial` / `.regularMaterial`
- **Min macOS:** 13.0 (Ventura) — TBD
- **Distribution:** GitHub Releases (.dmg or .zip)
- **Website:** Static HTML/CSS/JS one-pager

## Design Direction
- **Dark glassmorphism** — frosted glass panels (`rgba(255,255,255,0.08)` + 60px backdrop blur) with warm translucency
- **Accent:** Soft indigo `rgba(167, 180, 255)` at varying opacities
- **Signature features:**
  - Per-city color timeline bars (Available/Heads up/Sleeping in muted green/yellow/red)
  - Vertical scrub line connecting slider to all city timelines
  - Switchable timezone groups (up to 5, pill buttons)
  - Per-city menubar toggle dot (illuminated indigo / dim gray)
  - Home city indicator (📍 + "You" label + subtle glow)
  - Always-visible date labels (Today/Tomorrow/Yesterday) to prevent layout shift
  - Permanent "now" marker on slider bar
  - Current local time displayed instead of "Now" text
- **Typography:** SF Pro Display, light weight (300) for times, medium (500) for names
- **No close × button** — popover dismisses on outside click

## Key Constraints
- No App Store distribution (direct GitHub download)
- No backend / no server — everything is local
- Must persist data across app restarts (UserDefaults or similar)
- Must handle DST transitions correctly (use system timezone data, not hardcoded offsets)
- Group names limited to 12 characters
- Max 5 cities per group, max 5 groups
- 3–4 city limit for menubar compact display

## Design Reference Files
- **Full design spec:** `docs/design-brief.md`
- **Approved interactive prototype:** `docs/design-mockup-v4.jsx` (React — for visual reference only, not production code)
- **Background gradient:** `docs/midnight-aurora-background.css`
- **Requirements:** `requirements/requirements-timezone-converter.md`
