# TrackMe Localization Guide

## Supported Languages

TrackMe currently supports the following languages covering major iPhone markets worldwide:

- **English** (en) - Base language
- **Japanese** (ja) - 日本語 (70% iPhone market share in Japan)
- **Mandarin Chinese** (zh-Hans) - 简体中文 (Simplified Chinese)
- **German** (de) - Deutsch
- **Spanish** (es) - Español
- **French** (fr) - Français
- **Italian** (it) - Italiano
- **Portuguese** (pt) - Português

## Potential Future Languages

Based on iPhone market penetration and user demographics, might want to add:

### Medium Priority (based on market share)

- **Swedish** (sv) - Svenska - Scandinavia has high iPhone adoption
- **Norwegian** (no/nb) - Norsk - Norway has high affluence and iPhone usage
- **Danish** (da) - Dansk - Denmark has strong iPhone market
- **Finnish** (fi) - Suomi - Finland has tech-savvy population
- **Polish** (pl) - Polski - Growing Eastern European market
- **Turkish** (tr) - Türkçe - Large and growing smartphone market
- **Vietnamese** (vi) - Tiếng Việt - Fast-growing Southeast Asian market
- **Indonesian** (id) - Bahasa Indonesia - Large population, growing smartphone adoption
- **Hindi** (hi) - हिन्दी - India's growing iOS market (small % but huge population)

### Lower Priority (based on market share)

- **Thai** (th) - ไทย - Strong Southeast Asian tourism destination
- **Greek** (el) - Ελληνικά - Tourism destination
- **Czech** (cs) - Čeština - Central Europe
- **Hungarian** (hu) - Magyar - Central Europe
- **Hebrew** (he) - עברית - Israel has high tech adoption
- **Malay** (ms) - Bahasa Melayu - Malaysia and Singapore
- **Traditional Chinese** (zh-Hant) - 繁體中文 - Taiwan, Hong Kong

## Localization Files

### Structure

```
TrackMe/
├── en.lproj/
│   ├── InfoPlist.strings    # English Info.plist keys
│   └── Localizable.strings  # English UI strings
├── ja.lproj/
│   ├── InfoPlist.strings    # Japanese Info.plist keys
│   └── Localizable.strings  # Japanese UI strings
├── zh-Hans.lproj/
│   ├── InfoPlist.strings    # Simplified Chinese Info.plist keys
│   └── Localizable.strings  # Simplified Chinese UI strings
├── de.lproj/
│   ├── InfoPlist.strings    # German Info.plist keys
│   └── Localizable.strings  # German UI strings
├── es.lproj/
│   ├── InfoPlist.strings    # Spanish Info.plist keys
│   └── Localizable.strings  # Spanish UI strings
├── fr.lproj/
│   ├── InfoPlist.strings    # French Info.plist keys
│   └── Localizable.strings  # French UI strings
├── it.lproj/
│   ├── InfoPlist.strings    # Italian Info.plist keys
│   └── Localizable.strings  # Italian UI strings
└── pt.lproj/
    ├── InfoPlist.strings    # Portuguese Info.plist keys
    └── Localizable.strings  # Portuguese UI strings
```

### InfoPlist.strings

Contains localized versions of Info.plist keys, including:

- Location permission descriptions (NSLocationAlwaysAndWhenInUseUsageDescription, etc.)
- App display name (CFBundleDisplayName)

### Localizable.strings

Contains all UI strings used throughout the app, organized by:

- Tracking View strings
- History View strings
- Map View strings
- Common strings (buttons, errors, units)
- Travel-centric narrative suggestions (Road Trip, City Tour, Scenic Drive, etc.)

## Using Localized Strings in Code

### SwiftUI

To use localized strings in SwiftUI views, wrap strings in `Text()` with the key:

```swift
// Current (hardcoded)
Text("Start Tracking")

// Localized (to be implemented)
Text("Start Tracking")  // SwiftUI automatically looks up the key
```

### UIKit / Swift

For programmatic strings:

```swift
// Current
let message = "GPS Tracking Active"

// Localized
let message = NSLocalizedString("GPS Tracking Active", comment: "Status message")
```

## String Categories

### 1. Status Messages

- GPS tracking states
- Background/foreground status
- Active session indicators

### 2. Navigation & Tabs

- Tab bar titles
- Navigation bar titles
- Screen headers

### 3. Buttons & Actions

- Start/Stop tracking
- OK/Cancel
- Settings navigation

### 4. Permission Messages

- Location permission prompts
- Background access explanations
- Settings redirection messages

### 5. Session Information

- Current session details
- Location data display
- Statistics labels

### 6. Time & Distance Units

- Hours, minutes, seconds
- Kilometers, meters
- Speed units (km/h, m/s)

### 7. Error & Success Messages

- Error notifications
- Success confirmations
- Warning messages

## Adding a New Language

### 1. Create Language Directory

```bash
mkdir TrackMe/{language_code}.lproj
```

### 2. Copy English Files

```bash
cp TrackMe/en.lproj/InfoPlist.strings TrackMe/{language_code}.lproj/
cp TrackMe/en.lproj/Localizable.strings TrackMe/{language_code}.lproj/
```

### 3. Translate Strings

Translate the right side of each key-value pair:
```
"Start Tracking" = "Your Translation";
```

### 4. Update Xcode Project

- Add the new .lproj folder to the Xcode project
- In Project Settings > Info > Localizations, add the new language

## Testing Localization

### In Simulator

1. Open Settings app
2. Go to General > Language & Region
3. Add/select your language
4. Restart TrackMe

### In Xcode Scheme

1. Edit Scheme > Run
2. Options > App Language
3. Select language to test

### Using Arguments

Add launch argument:

```
-AppleLanguages (de)
-AppleLanguages (ja)
-AppleLanguages (zh-Hans)
```

## Translation Notes

### Travel-Centric Narrative Suggestions

All languages include localized travel-specific suggestions:
- Road Trip / City Tour
- Scenic Drive / Hiking Trail
- Beach Walk / Mountain Adventure
- Cycling Route / Ferry Crossing

### Language-Specific Notes

**German (de)**
- Formal "Sie" form used throughout
- Technical terms (GPS, Tracking) kept in English as commonly used
- Units follow metric system (km, m)

**Japanese (ja)**
- Polite form (です/ます) used throughout
- Natural Japanese phrasing for UI elements
- Katakana used for technical terms (GPS, アプリ)

**Mandarin Chinese (zh-Hans)**
- Simplified Chinese characters
- Formal tone appropriate for app UI
- Technical terms translated with commonly used Chinese equivalents

**Spanish (es)**
- Formal "usted" form used for consistency
- Latin American and European Spanish compatible
- Units follow metric system

**French (fr)**
- Formal "vous" form used throughout
- Proper French UI conventions followed
- Some English terms kept (Road Trip) as commonly used

**Italian (it)**
- Formal "Lei" form used throughout
- Natural Italian phrasing
- Units follow metric system

**Portuguese (pt)**
- Brazilian Portuguese conventions
- Formal "você" form
- Units follow metric system

### Plural Forms

For languages with complex plural rules, use `.stringsdict` files:

```xml
<key>%d locations</key>
<dict>
    <key>NSStringLocalizedFormatKey</key>
    <string>%#@locations@</string>
    <key>locations</key>
    <dict>
        <key>NSStringFormatSpecTypeKey</key>
        <string>NSStringPluralRuleType</string>
        <key>NSStringFormatValueTypeKey</key>
        <string>d</string>
        <key>one</key>
        <string>%d Standort</string>
        <key>other</key>
        <string>%d Standorte</string>
    </dict>
</dict>
```

## Privacy & Compliance

### Location Permission Descriptions

Must be clear and accurate in all languages:

- Explain why location access is needed
- Describe background tracking functionality
- Match Apple's Human Interface Guidelines

### Required Keys

- NSLocationWhenInUseUsageDescription
- NSLocationAlwaysAndWhenInUseUsageDescription
- NSLocationAlwaysUsageDescription (iOS 10+)

## String Formatting

### Date/Time

Use system formatters for locale-aware formatting:

```swift
let formatter = DateFormatter()
formatter.dateStyle = .medium
formatter.timeStyle = .short
// Automatically uses locale settings
```

### Numbers

Use NumberFormatter for proper decimal/thousands separators:

```swift
let formatter = NumberFormatter()
formatter.numberStyle = .decimal
formatter.maximumFractionDigits = 2
```

### Distance/Speed

Units should match locale preferences:

```swift
let measurement = Measurement(value: distance, unit: UnitLength.meters)
let formatter = MeasurementFormatter()
formatter.string(from: measurement)  // Handles locale conversion
```

## Best Practices

1. **Always use keys**: Never hardcode user-facing strings
2. **Keep keys in English**: Use descriptive English keys
3. **Add comments**: Provide context in comments for translators
4. **Test thoroughly**: Test all flows in each language
5. **Watch string length**: UI should accommodate longer translations
6. **Use formatters**: Let iOS handle locale-specific formatting
7. **Update together**: Update all localizations when adding features

## Resources

- [Apple Localization Guide](https://developer.apple.com/localization/)
- [iOS Human Interface Guidelines - Localization](https://developer.apple.com/design/human-interface-guidelines/localization)
- [String Catalog Documentation](https://developer.apple.com/documentation/xcode/localizing-and-varying-text-with-a-string-catalog)

## Maintenance

### Regular Tasks

- [ ] Review strings when adding new features
- [ ] Update all localized versions together
- [ ] Test permission prompts in each language
- [ ] Verify UI layouts accommodate all languages
- [ ] Check for truncation or overflow issues

### Version Control

- All .strings files should be tracked in git
- Include localization changes in feature PRs
- Document breaking changes that affect translations

## Contact

For translation questions or to contribute translations:

- Create an issue on GitHub
- Label with "localization"
- Provide context and screenshots if needed
