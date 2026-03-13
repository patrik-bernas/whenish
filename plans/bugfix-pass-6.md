# Bug Fix Brief: Pass 6

---

## Bug 1: Country flags are wrong for many cities

**What's wrong:** Athens shows 🇬🇧 (UK flag) instead of 🇬🇷 (Greece). This is part of a larger pattern — the flag mapping in CitySearchService.swift is unreliable and has many incorrect mappings.

**Fix:** The root cause is likely that the service maps timezone identifiers to flags using a flawed or incomplete lookup. The correct approach is:

1. Extract the country code from the timezone identifier. Apple's `TimeZone` doesn't directly give you a country code, BUT you can use `Locale.Region` or a mapping of timezone identifiers to ISO country codes.

2. Convert the ISO country code to a flag emoji using this reliable method:
```swift
func flagEmoji(for countryCode: String) -> String {
    let base: UInt32 = 127397 // Unicode regional indicator offset
    return countryCode.uppercased().unicodeScalars.map {
        String(UnicodeScalar(base + $0.value)!)
    }.joined()
}
```

3. Use a well-known timezone-to-country mapping. Here's the critical fix — create a dictionary that maps timezone identifiers to ISO 3166-1 alpha-2 country codes. Apple provides `TimeZone.knownTimeZoneIdentifiers` which are in the format "Region/City" (e.g. "Europe/Athens"). Use this curated mapping for common cities:

```swift
let timezoneToCountry: [String: String] = [
    "Europe/Athens": "GR",
    "Europe/Vienna": "AT",
    "Europe/Berlin": "DE",
    "Europe/London": "GB",
    "Europe/Paris": "FR",
    "Europe/Rome": "IT",
    "Europe/Madrid": "ES",
    "Europe/Amsterdam": "NL",
    "Europe/Dublin": "IE",
    "Europe/Lisbon": "PT",
    "Europe/Brussels": "BE",
    "Europe/Zurich": "CH",
    "Europe/Stockholm": "SE",
    "Europe/Oslo": "NO",
    "Europe/Copenhagen": "DK",
    "Europe/Helsinki": "FI",
    "Europe/Warsaw": "PL",
    "Europe/Prague": "CZ",
    "Europe/Budapest": "HU",
    "Europe/Bucharest": "RO",
    "Europe/Sofia": "BG",
    "Europe/Zagreb": "HR",
    "Europe/Belgrade": "RS",
    "Europe/Istanbul": "TR",
    "Europe/Moscow": "RU",
    "Europe/Kiev": "UA",
    "Asia/Tokyo": "JP",
    "Asia/Seoul": "KR",
    "Asia/Shanghai": "CN",
    "Asia/Hong_Kong": "HK",
    "Asia/Taipei": "TW",
    "Asia/Singapore": "SG",
    "Asia/Bangkok": "TH",
    "Asia/Jakarta": "ID",
    "Asia/Makassar": "ID",
    "Asia/Kolkata": "IN",
    "Asia/Dubai": "AE",
    "Asia/Riyadh": "SA",
    "Asia/Doha": "QA",
    "Asia/Karachi": "PK",
    "Asia/Dhaka": "BD",
    "Asia/Kuala_Lumpur": "MY",
    "Asia/Manila": "PH",
    "Asia/Ho_Chi_Minh": "VN",
    "Asia/Phnom_Penh": "KH",
    "Asia/Kathmandu": "NP",
    "Asia/Colombo": "LK",
    "Asia/Tbilisi": "GE",
    "Asia/Yerevan": "AM",
    "Asia/Baku": "AZ",
    "Asia/Jerusalem": "IL",
    "Asia/Beirut": "LB",
    "Asia/Amman": "JO",
    "Australia/Sydney": "AU",
    "Australia/Melbourne": "AU",
    "Australia/Brisbane": "AU",
    "Australia/Perth": "AU",
    "Australia/Adelaide": "AU",
    "Australia/Darwin": "AU",
    "Pacific/Auckland": "NZ",
    "Pacific/Chatham": "NZ",
    "Pacific/Fiji": "FJ",
    "Pacific/Honolulu": "US",
    "America/New_York": "US",
    "America/Chicago": "US",
    "America/Denver": "US",
    "America/Los_Angeles": "US",
    "America/Anchorage": "US",
    "America/Phoenix": "US",
    "America/Toronto": "CA",
    "America/Vancouver": "CA",
    "America/Edmonton": "CA",
    "America/Winnipeg": "CA",
    "America/Halifax": "CA",
    "America/Mexico_City": "MX",
    "America/Cancun": "MX",
    "America/Bogota": "CO",
    "America/Lima": "PE",
    "America/Santiago": "CL",
    "America/Buenos_Aires": "AR",
    "America/Argentina/Buenos_Aires": "AR",
    "America/Sao_Paulo": "BR",
    "America/Caracas": "VE",
    "America/Panama": "PA",
    "America/Costa_Rica": "CR",
    "America/Jamaica": "JM",
    "Africa/Cairo": "EG",
    "Africa/Lagos": "NG",
    "Africa/Nairobi": "KE",
    "Africa/Johannesburg": "ZA",
    "Africa/Casablanca": "MA",
    "Africa/Accra": "GH",
    "Africa/Addis_Ababa": "ET",
    "Atlantic/Reykjavik": "IS",
    "Indian/Maldives": "MV",
    "Indian/Mauritius": "MU",
]
```

4. For any timezone NOT in this dictionary, try to extract the country from the identifier region prefix (e.g. "Europe" doesn't help, but "Pacific/Chatham" → NZ can be looked up). As a last resort, show 🌍 as a fallback globe emoji, NEVER the wrong country flag.

5. **Audit every flag currently in the app.** Search through CitySearchService.swift and replace whatever logic is generating wrong flags with the approach above.

---

## Bug 2: Search results — must click on city name, not the whole card

**What's wrong:** To add a city from search results, the user has to click precisely on the city name text. The entire search result row should be tappable.

**Fix:** Make the entire search result row a single tappable area:

```swift
ForEach(searchResults) { result in
    Button(action: { viewModel.addCity(result) }) {
        HStack {
            Text(result.flag)
            VStack(alignment: .leading) {
                Text(result.name)
                Text(result.region)
            }
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .contentShape(Rectangle()) // Makes entire area tappable
    }
    .buttonStyle(.plain)
    .background(Color.white.opacity(0.001)) // Invisible but ensures hit testing
    .onHover { hovering in
        // Apply hover highlight to the entire row
    }
}
```

The key is `.contentShape(Rectangle())` which makes the full row respond to taps, not just the text.

Also add a hover state: when the mouse hovers over a search result row, the background should lighten to `rgba(255,255,255,0.06)`.

---

## Bug 3: Inconsistent divider line in search results

**What's wrong:** There's a divider line that appears between search results, but only between some items, creating an inconsistent look.

**Fix:** Either add dividers between ALL search results consistently, or remove them all. Recommended: add subtle 0.5px dividers between each result (same style as city row dividers):

```swift
if index < searchResults.count - 1 {
    Rectangle()
        .fill(Color.white.opacity(0.06))
        .frame(height: 0.5)
        .padding(.horizontal, 14)
}
```

No divider above the first result or below the last one.

---

## Bug 4: Menubar limited to 3 cities and jumps around

**What's wrong:** The menubar only shows 3 cities even if more have the menubar toggle active. Also, when opening/closing the popover, the menubar text shifts position.

**Fix:**
1. Allow up to 4 cities in the menubar (not 3). If more than 4 are toggled, show the first 4 sorted by timezone offset and silently omit the rest.

2. For the jumping issue, the problem is the status item width changes when the popover opens/closes. Use variable length BUT set a minimum width:

```swift
statusItem.length = NSStatusItem.variableLength
```

The jumping when the popover opens is likely because the popover anchor point shifts. To fix this, make sure `popover.show(relativeTo:of:preferredEdge:)` always uses the status item's button as the anchor:

```swift
func togglePopover() {
    if popover.isShown {
        popover.performClose(nil)
    } else {
        if let button = statusItem.button {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }
}
```

The popover should always drop down from the same anchor point regardless of the text content.

---

## After fixing, verify:
1. Search for Athens — shows 🇬🇷 (Greece flag)?
2. Search for Vienna — shows 🇦🇹 (Austria flag)?
3. Search for Dublin — shows 🇮🇪 (Ireland flag)?
4. Search for Chatham — shows 🇳🇿 (New Zealand flag)?
5. Can click anywhere on a search result row to add the city?
6. Search result rows highlight on hover?
7. Dividers between search results are consistent?
8. Menubar shows up to 4 cities in a single line?
9. Menubar doesn't jump when opening/closing the popover?
