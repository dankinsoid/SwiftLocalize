import Foundation

@resultBuilder
public struct Localized<Value> {

	public var base: (language: Language?, value: Value) {
		(baseLanguage, baseValue)
	}
	public let translations: [Language: Value]
	private let baseLanguage: Language?
	private let baseValue: Value
	
	var asDict: [Language: Value] {
		var dict = translations
		if let lang = base.language, dict[lang] == nil { dict[lang] = base.value }
		return dict
	}

	public init(
		_ baseLanguage: Language?,
		_ baseValue: Value,
		_ translations: [Language: Value] = [:]
	) {
		self.translations = translations
		self.baseLanguage = baseLanguage
		self.baseValue = baseValue
	}

	/// Same value with CLDR-canonical language keys: deprecated aliases collapsed
	/// (`iw`↔`he`, `in`↔`id`, `BU`↔`MM`, `Qaai`↔`Zinh`).
	///
	/// Likely-subtag pairs (`zh-TW`↔`zh-Hant`) are intentionally out of scope —
	/// expanding them would discard region-specific translations. `resolved`
	/// handles those at lookup time via `LocaleNegotiation`.
	///
	/// On alias collisions (e.g. both `iw` and `he` present), one value wins —
	/// order is unspecified. Holding both forms is a caller-side bug.
	public var canonical: Localized {
		Localized(
			base.language?.canonical,
			base.value,
			Dictionary(translations.map { ($0.key.canonical, $0.value) }, uniquingKeysWith: { first, _ in first })
		)
	}

	/// Resolve to a value, preferring `languages` in priority order.
	///
	/// Walks the chain and returns the value for the first language that
	/// matches an available translation via CLDR-aware negotiation:
	/// canonicalizes deprecated aliases (`iw` → `he`), expands via likely
	/// subtags (`zh-TW` matches available `zh-Hant`), walks parent chains
	/// (`en-AU` → `en-001` → `en`, `es-AR` → `es-419` → `es`).
	///
	/// Falls back to `default:` if no language in the chain matches.
	/// Cross-language mixing only via the explicit `default:` slot — never
	/// silently through another language's translation.
	///
	/// `resolved(_:)` and `resolved()` are thin wrappers over this.
	public func resolved(preferring languages: [Language]) -> Value {
		guard !languages.isEmpty, !translations.isEmpty else { return base.value }
		let translations = asDict
		if languages.count == 1, let v = translations[languages[0]] { return v }
		if !translations.isEmpty {
			let chain = LocaleNegotiation.matching(
				requested: languages,
				available: Array(translations.keys)
			)
			for tag in chain {
				if let v = translations[tag] { return v }
			}
		}
		return base.value
	}
	
	/// Resolve to a value for `language`.
	///
	/// Lookup order:
	///   1. Exact tag (`en-US`).
	///   2. CLDR-aware negotiation against `translations.keys`: canonicalizes
	///      deprecated aliases (`iw` → `he`), expands via likely subtags
	///      (`zh-TW` matches available `zh-Hant`), walks CLDR parent chains
	///      (`en-AU` → `en-001` → `en`, `es-AR` → `es-419` → `es`).
	///   3. `default:` fallback.
	///
	/// Cross-language mixing only via the explicit `default:` slot — never
	/// silently through another language's translation.
	public func resolved(_ language: Language) -> Value {
		resolved(preferring: [language])
	}

	/// Resolve against the user's full preferred-language chain
	/// (`Locale.preferredLanguages`), so a user with `["fr", "en"]` gets the
	/// English translation when French is missing — instead of dropping to
	/// `default:`.
	///
	/// Same CLDR-aware negotiation as `resolved(_:)`, but with multiple
	/// requested locales in priority order.
	public func resolved() -> Value {
		resolved(preferring: Locale.preferredLanguages.map(Language.init(rawValue:)))
	}

	/// Like `resolved(preferring:)` but returns `nil` when no language in the
	/// chain matches an explicit translation — never falls through to the
	/// anchor's `base.value`.
	///
	/// Negotiation rules are the same as `resolved`: canonicalize aliases
	/// (`iw`↔`he`), expand likely subtags (`zh-TW`↔`zh-Hant`), walk parent
	/// chains (`en-AU`→`en-001`→`en`). A non-nil result is therefore always
	/// in the same language family as one of the requested locales — useful
	/// for composing localized values without silently mixing in the anchor's
	/// language.
	public func tryResolved(preferring languages: [Language]) -> Value? {
		let translations = asDict
		guard !languages.isEmpty else { return nil }
		guard !translations.isEmpty else { return baseValue }
		if languages.count == 1, let v = translations[languages[0]] { return v }
		let chain = LocaleNegotiation.matching(
			requested: languages,
			available: Array(translations.keys)
		)
		for tag in chain {
			if let v = translations[tag] { return v }
		}
		if baseLanguage == nil { return baseValue }
		return nil
	}

	/// Like `resolved(_:)` but returns `nil` when no translation matches.
	/// See `tryResolved(preferring:)` for details.
	public func tryResolved(_ language: Language) -> Value? {
		tryResolved(preferring: [language])
	}

	/// See `resolved(_:)`.
	public func callAsFunction(_ language: Language) -> Value {
		resolved(language)
	}

	/// See `resolved()`.
	public func callAsFunction() -> Value {
		resolved()
	}

	/// Languages this value explicitly speaks: `translations.keys` plus
	/// `base.language` when non-nil. A purely language-agnostic value
	/// (e.g. `Localized(nil, 42)`) returns an empty set.
	public var availableLanguages: Set<Language> {
		var langs = Set(translations.keys)
		if let lang = baseLanguage { langs.insert(lang) }
		return langs
	}
}

// MARK: - Concatenation
//
// Composition along the value axis: `Localized<String> + Localized<String>`
// concatenates per language. Only available where `Value` supports
// `append(contentsOf:)` — strings, arrays, attributed strings.

extension Localized where Value: RangeReplaceableCollection {

	/// Concatenate two localized values.
	///
	/// **Per-language translations**: for every language covered by either side,
	/// the result holds `lhs.tryResolved(lang) + rhs.tryResolved(lang)` — that
	/// is, CLDR-negotiated lookups on both sides (canonical aliases, likely
	/// subtags, parent walks). A side that can't produce a value for `lang`
	/// without falling through to its anchor contributes nothing, and the slot
	/// is dropped rather than mixing languages. A universal side
	/// (`base.language == nil`) contributes its base value to every slot.
	///
	/// **Anchor (`base.language`)**:
	/// - Both sides universal → result is universal.
	/// - Exactly one side anchored → that anchor.
	/// - Both anchored — picked from the merged per-language map by the first
	///   match in this priority chain: `lhs.base.language`, `rhs.base.language`,
	///   then `Locale.preferredLanguages` in order. If none of those land in
	///   the merged map, falls back to the alphabetically first language
	///   present; if the map is empty (no shared coverage at all), falls back
	///   to `lhs.base.language` and debug-asserts — the base value there
	///   silently mixes anchors.
	///
	/// **Base value**: when the chosen anchor has a merged slot, that slot's
	/// value is used (so translation overrides on either side are honored).
	/// For a universal result, `lhs.base.value + rhs.base.value`. The slot for
	/// the chosen `baseLanguage` is then removed from `translations` to avoid
	/// duplication with `base.value`.
	///
	/// **Disagreeing anchors**: sides with different `base.language` still combine
	/// correctly when they cover the same languages through different anchors
	/// (e.g. `.en`-anchored with a `.fr` translation + `.fr`-anchored with an
	/// `.en` translation yields both `.en` and `.fr` slots). Alias and
	/// likely-subtag pairs (`iw`↔`he`, `zh-TW`↔`zh-Hant`) also pair correctly
	/// — that's `tryResolved`'s job, not exact-key lookup.
	public static func + (_ lhs: Localized, _ rhs: Localized) -> Localized {
		let languages = lhs.availableLanguages.union(rhs.availableLanguages)

		var mergedTranslations: [Language: Value] = [:]
		mergedTranslations.reserveCapacity(languages.count)

		// `tryResolved` participates in CLDR negotiation (aliases, likely-subtags,
		// parent walks) — same-language matches only. Cross-language mixing into
		// a slot happens only via the universal `lAnyValue`/`rAnyValue`, which
		// by definition carry no language commitment.
		for lang in languages {
			if let lValue = lhs.tryResolved(lang),
			   let rValue = rhs.tryResolved(lang) {
				mergedTranslations[lang] = lValue + rValue
			}
		}

		let baseLanguage: Language?
		if lhs.baseLanguage == rhs.baseLanguage {
			baseLanguage = lhs.baseLanguage
		} else if lhs.baseLanguage == nil {
			baseLanguage = rhs.baseLanguage
		} else if rhs.baseLanguage == nil {
			baseLanguage = lhs.baseLanguage
		} else {
			let translationsKeys = Set(mergedTranslations.keys)
			let priorityLanguages = [lhs.baseLanguage!, rhs.baseLanguage!] + Locale.preferredLanguages.map(Language.init(rawValue:))
			baseLanguage = priorityLanguages.first(where: translationsKeys.contains)
				?? translationsKeys.sorted(by: { $0.rawValue < $1.rawValue }).first
			if baseLanguage == nil {
				assertionFailure("Localized + Localized: no shared coverage between anchors \(lhs.baseLanguage!) and \(rhs.baseLanguage!); base value will silently mix anchors.")
			}
		}

		let baseValue: Value
		if let lang = baseLanguage {
			// Anchored result — prefer the merged slot (catches translation overrides
			// on either side). Falls back to raw `resolved` only on the asserted
			// no-shared-coverage path above.
			baseValue = mergedTranslations[lang] ?? (lhs.resolved(lang) + rhs.resolved(lang))
		} else {
			baseValue = lhs.baseValue + rhs.baseValue
		}

		if let baseLanguage {
			mergedTranslations.removeValue(forKey: baseLanguage)
		}

		return Localized(baseLanguage, baseValue, mergedTranslations)
	}

	public static func + (_ lhs: Localized, _ rhs: Value) -> Localized {
		var translations: [Language: Value] = [:]
		for (lang, v) in lhs.translations {
			translations[lang] = v + rhs
		}
		return Localized(lhs.baseLanguage, lhs.baseValue + rhs, translations)
	}

	public static func + (_ lhs: Value, _ rhs: Localized) -> Localized {
		var translations: [Language: Value] = [:]
		for (lang, v) in rhs.translations {
			translations[lang] = lhs + v
		}
		return Localized(rhs.baseLanguage, lhs + rhs.baseValue, translations)
	}

	public static func += (_ lhs: inout Localized, _ rhs: Localized) {
		lhs = lhs + rhs
	}

	public static func += (_ lhs: inout Localized, _ rhs: Value) {
		lhs = lhs + rhs
	}
}

// MARK: - Description (deprecated to flush silent preferred-chain resolution)
//
// Conforming to `CustomStringConvertible` is what makes `"\(localized)"` —
// or any `String(describing:)` / `print` — produce a localized string
// negotiated against the user's preferred languages. That's the silent path
// we want callers to notice. Keep the conformance for visibility in
// debugging, but warn on use so the implicit path doesn't sneak into UI
// strings unobserved.

extension Localized: CustomStringConvertible {

	public var description: String { "\(callAsFunction())" }
}

// MARK: - Literal conformances

extension Localized: ExpressibleByExtendedGraphemeClusterLiteral where Value: ExpressibleByStringLiteral {

	public init(extendedGraphemeClusterLiteral value: Value.ExtendedGraphemeClusterLiteralType) {
		self.init(nil, Value(extendedGraphemeClusterLiteral: value))
	}
}

extension Localized: ExpressibleByStringLiteral where Value: ExpressibleByStringLiteral {

	public init(stringLiteral value: Value.StringLiteralType) {
		self.init(nil, Value(stringLiteral: value))
	}
}

extension Localized: ExpressibleByUnicodeScalarLiteral where Value: ExpressibleByStringLiteral {

	public init(unicodeScalarLiteral value: Value.UnicodeScalarLiteralType) {
		self.init(nil, Value(unicodeScalarLiteral: value))
	}
}

extension Localized: ExpressibleByStringInterpolation where Value: ExpressibleByStringInterpolation {

	public init(stringInterpolation: Value.StringInterpolation) {
		self.init(nil, Value(stringInterpolation: stringInterpolation))
	}
}

extension DefaultStringInterpolation {

		@available(*, deprecated, message: "Implicit preferred-language resolution. Use `localized.resolved()` or `localized(.en)`.")
		public mutating func appendInterpolation<Value>(_ value: Localized<Value>) {
			appendLiteral(value.description)
		}
}

extension Localized: CustomDebugStringConvertible {

	public var debugDescription: String {
		let langs = translations.keys.map(\.description).joined(separator: ", ")
		let baseTag = baseLanguage?.description ?? "any"
		return "Localized(\(baseTag): \(baseValue), translations: [\(langs)])"
	}
}

extension Localized: Equatable where Value: Equatable {}
extension Localized: Hashable where Value: Hashable {}
extension Localized: Sendable where Value: Sendable {}
extension Localized: Decodable where Value: Decodable {}
extension Localized: Encodable where Value: Encodable {}
