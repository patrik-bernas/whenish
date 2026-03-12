# Timezone App (Working Title)

A free, open-source macOS menubar timezone converter with a playful, visual design.

> **Status:** In development

## Features

- 🕐 **Menubar quick view** — See your important city times right in the macOS menubar
- 🌍 **Timezone groups** — Organize cities into up to 3 groups (Work, Family, etc.)
- 🎨 **Per-city availability bars** — See at a glance who's in working hours, winding down, or sleeping
- ⏱️ **Time scrubber** — Drag the slider to see what time it will be everywhere, with a vertical line connecting all timelines
- 🏳️ **Country flags** — Visual city identification at a glance
- ⚙️ **12h / 24h toggle** — Display times the way you prefer

## Screenshots

*Coming soon*

## Installation

1. Go to [Releases](../../releases)
2. Download the latest `.dmg` file
3. Open the `.dmg` and drag the app to your Applications folder
4. Launch from Applications — the app will appear in your menubar

## Building from Source

### Requirements
- macOS 13 (Ventura) or later
- Xcode 15+

### Steps
```bash
git clone https://github.com/YOUR_USERNAME/timezone-app.git
cd timezone-app
open TimezoneApp.xcodeproj
# Build and run in Xcode (⌘R)
```

## Tech Stack

- Swift + SwiftUI
- Native macOS menubar app (NSStatusItem + NSPopover)

## Contributing

Contributions are welcome! Please open an issue first to discuss what you'd like to change.

## License

MIT License — see [LICENSE](LICENSE) for details.

## Acknowledgments

Inspired by [Pretty Timezones](https://prettytimezones.com) by [@ky__zo](https://x.com/ky__zo).
