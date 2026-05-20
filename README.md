# SwiftLocalize

[![License](https://img.shields.io/cocoapods/l/SwiftLocalize.svg?style=flat)](https://cocoapods.org/pods/SwiftLocalize)
[![Swift](https://img.shields.io/badge/Swift-5.7+-orange.svg)](https://swift.org)
[![Platforms](https://img.shields.io/badge/platform-iOS%20|%20macOS%20|%20tvOS%20|%20watchOS%20|%20Linux-lightgrey.svg)](#installation)

A CLDR-backed localization toolkit for Swift. Carry translations alongside the code that uses them, with first-class support for plural rules, grammatical gender, locale negotiation, and per-language typography — no `.strings` files, no Bundle indirection.

## Highlights

- **`Localized<Value>`** — a generic container of per-language values (not just strings — also images, attributed strings, or any custom type; adds `+` for any `RangeReplaceableCollection`).
- **Open `Language` type** — any BCP-47 tag (`en`, `zh-Hant-TW`, `es-419`, …) plus 180+ generated named constants (`.en`, `.ru`, `.ja`, …).
- **CLDR plural rules** — `n.plural(in:)` and `n.ordinal(in:)` dispatch through the language's own rule set (`one`/`few`/`many`/`other`/…); `(a...b).plural(in:)` resolves the 2D `pluralRanges` table.
- **Grammatical gender** — `Language.grammaticalGenders` returns the language's CLDR-classified gender set (`[.animate, .inanimate, .feminine, .neuter]` for cs, `[.common, .neuter]` for da, `[]` for en/ja/zh, …).
- **Locale negotiation** — `zh-TW` matches an available `zh-Hant`, `en-AU` walks to `en-001` then `en`, deprecated `iw` canonicalizes to `he` — all data-driven from CLDR.
- **Typography helpers** — `"Hi".quoted(in: .ru)` → `«Hi»`; `"2020".rangeJoined(to: "2025", in: .ja)` → `2020～2025`.
- **Composition** — `+` and `[Localized<…>].joined(separator:)` concatenate per-language with smart fallback; `Localized` itself is a `@resultBuilder` for declarative composition with control flow.

## Quick example

```swift
import SwiftLocalize

enum Strings {

    // Single-language constant — string literal works directly.
    static let appName: Localized<String> = "Tunes"

    // Multi-language constant: anchor language + translations dictionary.
    static let cancel = Localized<String>(
        .en, "Cancel",
        [.ru: "Отмена", .de: "Abbrechen", .fr: "Annuler"]
    )

    // Same value, but typed as `String` — the result builder auto-resolves
    // against the user's preferred languages on every access.
    @Localized<String>
    static var delete: String {
        Localized<String>(.en, "Delete", [.ru: "Удалить", .es: "Eliminar"])
    }

    // Interpolation: each translation is a plain Swift string.
    static func welcome(name: String) -> Localized<String> {
        Localized(
            .en, "Welcome back, \(name)!",
            [.ru: "С возвращением, \(name)!",
             .de: "Willkommen zurück, \(name)!"]
        )
    }

    // Cardinal plurals via CLDR rules.
    // `$0` is a `PluralCategorized` — interpolating it formats the number
    // for the current language (decimal separator, digit grouping, …).
    static func songs(_ n: Int) -> Localized<String> {
        Localized(
            .en, n.plural(in: .en) { switch $0 {
                case .one: "\($0) song"
                default:   "\($0) songs"
            }},
            [.ru: n.plural(in: .ru) { switch $0 {
                case .one: "\($0) песня"      // 1, 21, 31…
                case .few: "\($0) песни"      // 2–4, 22–24…
                default:   "\($0) песен"      // 0, 5–20, 11–14…
            }}]
        )
    }
}

Strings.cancel.resolved(.ru)      // "Отмена"
Strings.cancel.resolved("en-US")  // "Cancel"   — walks en-US → en
Strings.cancel.resolved("ja")     // "Cancel"   — falls back to anchor
Strings.welcome(name: "Анна").resolved(.ru) // "С возвращением, Анна!"
Strings.songs(5).resolved(.ru)              // "5 песен"

// callAsFunction sugar — same as `.resolved(_:)` / `.resolved()`.
Strings.cancel(.ru)               // "Отмена"
Strings.cancel()                  // resolves against the user's preferred chain
Strings.songs(5)(.ru)             // "5 песен"

// `delete` is typed `String`, not `Localized<String>` — the builder already
// resolved it. Read it like any other constant.
label.text = Strings.delete
```

## Core concepts

### `Localized<Value>`

A value typed by `Value`, holding an optional anchor (`baseLanguage` + `baseValue`) and a `[Language: Value]` translations map. Construction shapes:

```swift
// 1. Anchored — base language is explicit.
Localized<String>(.en, "Cancel", [.ru: "Отмена"])

// 2. Universal (no anchor) — the base value applies to any language not in the map.
Localized<String>(nil, "🟢", [.en: "Green", .ru: "Зелёный"])

// 3. String literal — language-agnostic constant.
let appName: Localized<String> = "Tunes"

// 4. Interpolation — uses the conforming Value type's interpolation.
let greeting: Localized<String> = "Hello, \(name)"
```

Resolve a value:

```swift
loc.resolved()              // user's preferred languages, in order
loc.resolved(.ru)           // single language
loc.resolved(preferring: [.ru, .en, .de])   // priority chain
loc.tryResolved(.ru)        // nil if nothing in the ru family matches (no anchor fallback)

// callAsFunction is sugar for `.resolved(_:)` / `.resolved()`:
loc(.ru)                    // == loc.resolved(.ru)
loc()                       // == loc.resolved()
```

`Localized` is `Sendable`, `Hashable`, `Codable`, and `Equatable` whenever `Value` is.

> **Note:** `CustomStringConvertible` is implemented (so `"\(loc)"` produces a localized string against the user's preferred chain), but the interpolation form is deprecated — prefer `loc.resolved()` or `loc(.en)` to make the language choice explicit.

### `Language` — open BCP-47 tags

```swift
public struct Language: Hashable, Codable, Sendable, RawRepresentable,
                        ExpressibleByStringLiteral, CustomStringConvertible { … }
```

Any tag is acceptable — both BCP-47 (`en-US`) and POSIX (`en_US`) inputs are normalized to the canonical BCP-47 form on init. 180+ generated constants (one per ISO 639-1 code) live in `Languages+Generated.swift`:

```swift
Language.en, .ru, .de, .ja, .zh, .ar, .he, .hi, .ko, ...
Language("zh-Hant-TW")     // regional variants — string init
Language.current           // best-effort from Locale.preferredLanguages
```

Parsed subtags are exposed as `.language`, `.script`, `.region`, plus `languageOnly` (strip region/script).

### Locale negotiation

When `resolved(_:)` doesn't find an exact tag in the translations map, it walks a CLDR-backed chain:

1. **Canonicalize** deprecated aliases — `iw` → `he`, `in` → `id`, region `BU` → `MM`, script `Qaai` → `Zinh`.
2. **Likely-subtag expansion** — `zh-TW` matches an available `zh-Hant` (because `zh-TW` maximizes to `zh-Hant-TW`).
3. **Parent walk** — `en-AU` → `en-001` → `en`; `es-AR` → `es-419` → `es`; `zh-Hant-TW` → `zh-Hant`.

Only if all of that fails does it fall through to the anchor `baseValue`. Cross-language mixing happens only via that explicit slot — never silently through another language's translation.

`LocaleNegotiation` is also exposed directly for use outside `Localized`:

```swift
LocaleNegotiation.matching(
    requested: [Language("zh-TW"), .en],
    available: [Language("zh-Hant"), .en, .ru]
)
// → [zh-Hant, en]

LocaleNegotiation.filtering(    // every available match, priority order
    requested: [Language("en-GB")],
    available: [.en, Language("en-US"), .de]
)
```

## Plurals

Plural rules and categories follow Unicode CLDR. Categories: `zero`, `one`, `two`, `few`, `many`, `other`. The set a language uses, and which numbers go into each bucket, is per-language data; SwiftLocalize ships generated tables for all CLDR languages.

### Cardinal — counting

```swift
n.plural(in: .ru) {
    switch $0 {
    case .one: "\($0) песня"
    case .few: "\($0) песни"
    default:   "\($0) песен"
    }
}
```

The closure receives a `PluralCategorized<Int>` that pattern-matches on either `PluralCategory` cases (`.one`, `.few`, …) or the number itself (`case 0:`, `case 11:`).

Interpolating `$0` (`"\($0)"`) renders the number using the language's own locale — French gets `1 234,5`, Indian English gets `12,34,567`, Japanese gets fullwidth digits when appropriate — so you don't need to format the number separately and interpolate it back in.

### Ordinal — rank / position

```swift
n.ordinal(in: .en) {
    switch $0 {
    case .one: "\($0)st place"   // 1, 21, 31…
    case .two: "\($0)nd place"   // 2, 22, 32…
    case .few: "\($0)rd place"   // 3, 23, 33…
    default:   "\($0)th place"   // 11–13, everything else
    }
}
```

Cardinal and ordinal use *different* rule sets — English cardinal collapses everything but 1 to `.other`, but ordinal splits 1/2/3/teens/rest.

### Plural ranges — 2D table

```swift
(1...5).plural(in: .ru) { r in
    switch r {
    case .one: "\(r) песня"
    case .few: "\(r) песни"
    default:   "\(r) песен"
    }
}
// → "1–5 песен"     — CLDR says ru (one + many) → many
//                     not .one from 1, not .many by coincidence from 5
```

This consults CLDR's `pluralRanges.json` — a per-language map of `(start_category, end_category) → result_category`. Picking either endpoint manually would land on the wrong form for compound cases like Russian `one + many` or French `one + other`.

Interpolating `r` (a `PluralRangeCategorized`) joins both endpoints through the language's range pattern (`–` in en/ru/de, `～` in ja, `-` in zh) with locale-formatted numbers; when start equals end it collapses to a single value, so `(5...5).plural(in: .ru) { "\($0) яблок" }` yields `"5 яблок"` rather than `"5–5 яблок"`.

For languages absent from `pluralRanges.json` (e.g. Maltese), the end endpoint's own plural category is used per UTS #35.

### Custom rules

If a language isn't in the generated defaults, or you need a non-standard rule, build a `PluralRule` value and use it directly:

```swift
let myRule = PluralRule(
    cardinal: { n in n == 0 ? .zero : (n == 1 ? .one : .other) },
    ordinal:  { _ in .other }
)
```

## Grammatical gender

`Language.grammaticalGenders` returns the set of CLDR grammatical genders the language distinguishes. These are *grammatical*, not biological — they're the categories used for noun and adjective agreement.

```swift
Language.ru.grammaticalGenders   // [.masculine, .feminine, .neuter]
Language.fr.grammaticalGenders   // [.masculine, .feminine]
Language.cs.grammaticalGenders   // [.animate, .inanimate, .feminine, .neuter]
Language.pl.grammaticalGenders   // [.animate, .inanimate, .personal, .feminine, .neuter]
Language.da.grammaticalGenders   // [.common, .neuter]
Language.en.grammaticalGenders   // []   — no grammatical gender
```

`GrammaticalGender` itself has no closure-based dispatch like plurals do — the gender is data the caller already has (a user property, a noun class), so use a plain `switch`:

```swift
func signedIn(name: String, gender: GrammaticalGender) -> Localized<String> {
    let ru: String = switch gender {
        case .feminine: "\(name) вошла"
        default:        "\(name) вошёл"
    }
    return Localized(.en, "\(name) signed in", [.ru: ru])
}
```

Lookup canonicalizes the tag (`iw` → `he`) and treats region/script variants as inheriting the parent language's set (`ru-RU`, `de-AT`, `fr-CA` all match the bare-language gender set).

## Composition

### `+` operator

For any `Value` conforming to `RangeReplaceableCollection` (i.e. `String`, `Array`, `AttributedString`, …):

```swift
let beautiful = Localized<String>(.en, "beautiful", [.ru: "красивое"])
let tree      = Localized<String>(.en, "tree", [.ru: "дерево"])

let phrase = beautiful + " " + tree
phrase.resolved(.en)   // "beautiful tree"
phrase.resolved(.ru)   // "красивое дерево"
```

Concatenation does per-language CLDR-negotiated lookup on both sides. A side missing a translation contributes nothing rather than silently mixing languages; universal sides (`baseLanguage == nil`) contribute their base value to every slot.

### `Sequence.joined(separator:)`

Multi-operand concatenation in a single pass — mirrors `[String].joined(separator:)` from the standard library:

```swift
let items = [
    Localized<String>(.en, "apples",  [.ru: "яблоки"]),
    Localized<String>(.en, "oranges", [.ru: "апельсины"]),
    Localized<String>(.en, "pears",   [.ru: "груши"]),
]

items.joined(separator: ", ").resolved(.ru)
// → "яблоки, апельсины, груши"

// Works on any Sequence — pipelines from .map / .filter included.
breadcrumbs.map(\.localized).joined(separator: " > ")
```

Equivalent to `parts[0] + sep + parts[1] + … + sep + parts[n-1]`, but computes the language union once and resolves each operand exactly once per language instead of N−1 binary merges. The separator is optional (omit for plain concatenation) and participates like a regular operand — universal contributes to every slot, anchored can drop a slot when it has no translation for that language. Both `+` and the result builder delegate here under the hood: the result builder collects all its elements first and makes a single one-pass call, while chained `+` (`a + b + c + d`) is still N−1 binary calls because Swift folds `+` left-associatively — switch to `.joined(separator:)` for long chains.

When all operands are anchored to different languages and none have cross-translations covering each other, no slot can faithfully hold the result. The composition is tagged `Language.mul` (BCP-47 "multiple languages") and asserts in debug — distinct from a `nil` anchor ("language-agnostic by design") so the polyglot result is visible at the type level instead of being silently demoted to universal.

### Result builder

`Localized` itself is annotated `@resultBuilder`, so the type name doubles as the builder attribute. Use it for declarative composition with full control flow:

```swift
@Localized<String>
static func playlistSummary(name: Localized<String>, count: Int) -> Localized<String> {
    Localized<String>(.en, "Playlist “", [.ru: "Плейлист «", .de: "Playlist „"])
    name
    Localized<String>(.en, "”, ",          [.ru: "», ",        .de: "“, "])
    songs(count)
    "."
}

playlistSummary(name: Localized(nil, "Chill Vibes", [.ru: "Чилл-плейлист"]),
                count: 3).resolved(.ru)
// → "Плейлист «Чилл-плейлист», 3 песни."
```

The return type of the builder-annotated function picks what comes back. Declare `-> Localized<String>` to get the composed `Localized` value (and resolve it later); declare `-> String` to have the builder call `.resolved()` against the user's preferred chain and hand you the plain value:

```swift
// Returns a Localized<String> — caller controls when/how to resolve.
@Localized<String>
static func title(_ name: Localized<String>) -> Localized<String> {
    "Playlist: "
    name
}

// Returns a plain String, already resolved for the current user.
@Localized<String>
static func currentTitle(_ name: Localized<String>) -> String {
    "Playlist: "
    name
}
```

## Typography

### Quotation marks

```swift
"Привет".quoted(in: .ru)            // «Привет»
"world".quoted(in: .en)             // "world"
"innen".quoted(in: .de, level: 1)   // ‚innen' — alternate pair for nested quotes
```

`Language.quotationMarks(level:)` returns the CLDR `delimiters.json` pair for the language (primary at even levels, alternate at odd). Parent-chain resolution applies, with a universal `und` fallback.

### Range patterns

```swift
"2020".rangeJoined(to: "2025", in: .en)   // "2020–2025"
"2020".rangeJoined(to: "2025", in: .ja)   // "2020～2025"
"2020".rangeJoined(to: "2025", in: .zh)   // "2020-2025"

Language.ja.rangePattern        // "{0}～{1}"
Language.ja.rangeSeparator      // "～"
```

## Installation

### Swift Package Manager

```swift
// swift-tools-version:5.7
let package = Package(
    name: "MyApp",
    dependencies: [
        .package(url: "https://github.com/dankinsoid/SwiftLocalize.git", from: "2.0.0")
    ],
    targets: [
        .target(name: "MyApp", dependencies: ["SwiftLocalize"])
    ]
)
```

### CocoaPods

```ruby
pod 'SwiftLocalize'
```

## Regenerating CLDR data

All `*+Generated.swift` files are produced from the [`unicode-org/cldr-json`](https://github.com/unicode-org/cldr-json) dataset by dev-only executable targets. They default to fetching live from `main` (override with `CLDR_BRANCH`) but accept paths or URLs to pin to a snapshot.

```bash
swift run GenerateLanguageConstants
swift run GenerateLocaleData          # likely subtags, parent locales, aliases
swift run GeneratePluralRules         # cardinal + ordinal closures per language
swift run GeneratePluralRanges        # 2D (start, end) → result tables
swift run GenerateGrammaticalGender   # per-language gender sets
swift run GenerateDelimiters          # quotation marks
swift run GenerateRangePatterns       # numeric range patterns
```

Each generator accepts optional positional arguments — see the per-target documentation in [`Package.swift`](Package.swift) and the script directories under [`Scripts/`](Scripts/).

## Author

Voidilov — voidilov@gmail.com

## License

SwiftLocalize is available under the MIT license. See the [LICENSE](LICENSE) file for more info.
