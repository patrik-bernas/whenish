# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

### Added
- Initial project structure (README, LICENSE, PRODUCT.md, .gitignore)
- Requirements document v2 — updated to reflect v4 design decisions
- Design brief v2 — pixel-perfect spec with dark glassmorphism tokens
- Interactive design prototype (design-mockup-v4.jsx) — approved
- Midnight Aurora background gradient (reusable CSS asset)

### Design Decisions (from discovery phase)
- Dark glassmorphism aesthetic (pivoted from original light/playful direction)
- 3-state availability: Available (green), Heads up (yellow), Sleeping (red)
- Per-city timeline bars with vertical scrub line
- Up to 3 timezone groups, pill-based switching, 12-char name limit
- Per-city menubar toggle dot (indigo glow when active)
- Home city with 📍 indicator, "You" label, and subtle glow
- Always-visible date labels (Today/Tomorrow/Yesterday) to prevent layout shift
- Permanent "now" marker on slider bar
- Current local time replaces "Now" text
- No close × button — popover dismisses on outside click
- Legend (Available / Heads up / Sleeping) inside the popover
- Max 6 cities per group, 3–4 cities in menubar compact view
