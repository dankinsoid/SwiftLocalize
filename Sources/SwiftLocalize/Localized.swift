import Foundation

@resultBuilder
public struct Localized<Value> {

	public let base: (language: Language?, value: Value)
	public let translations: [Language: Value]
	
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
		self.base = (baseLanguage, baseValue)
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
		var translations = asDict
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
		if let lang = base.language { langs.insert(lang) }
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
	/// **Anchor (`base.language`)**:
	/// - Both sides universal (`base.language == nil`) → result is universal.
	/// - Exactly one side is anchored → that anchor.
	/// - Both sides anchored — picked from the merged per-language map by the
	///   first match in this priority chain: `lhs.base.language`,
	///   `rhs.base.language`, then `Locale.preferredLanguages` in order. If
	///   none of those land in the merged map, falls back to the alphabetically
	///   first language present; if the map is empty, falls back to
	///   `lhs.base.language` and debug-asserts — the base value here silently
	///   mixes anchors.
	///
	/// **Base value**: `lhs.resolved(baseLanguage) + rhs.resolved(baseLanguage)` —
	/// each side contributes its own best resolution for the chosen anchor via
	/// its own negotiation chain. A universal side resolves to its base value
	/// for any language; an anchored side only resolves through its own
	/// translations.
	///
	/// **Per-language translations**: for every language explicitly covered by
	/// either side, the result holds `lhs_lang + rhs_lang` — but only when both
	/// sides can produce a value for that language *without* silently falling
	/// through another anchor. A universal side contributes its base value to
	/// every slot of the other; an anchored side with no entry for `lang` and
	/// `base.language != lang` contributes nothing, and the slot is dropped
	/// rather than mixing languages. The entry for the chosen `baseLanguage` is
	/// stored in `base.value` and removed from `translations` to avoid duplication.
	///
	/// **Disagreeing anchors**: sides with different `base.language` still combine
	/// correctly when they cover the same languages through different anchors
	/// (e.g. `.en`-anchored with a `.fr` translation + `.fr`-anchored with an
	/// `.en` translation yields both `.en` and `.fr` slots).
	public static func + (_ lhs: Localized, _ rhs: Localized) -> Localized {
		let lTranslations = lhs.asDict
		let rTranslations = rhs.asDict
	
		let lAnyValue: Value? = lhs.base.language == nil ? lhs.base.value : nil
		let rAnyValue: Value? = rhs.base.language == nil ? rhs.base.value : nil

		let languages = Set(lTranslations.keys).union(rTranslations.keys)
		
		var mergedTranslations: [Language: Value] = [:]
		mergedTranslations.reserveCapacity(languages.count)

		for lang in languages {
			if let lValue = lTranslations[lang] ?? lAnyValue, let rValue = rTranslations[lang] ?? rAnyValue {
				mergedTranslations[lang] = lValue + rValue
			}
		}
		
		let baseLanguage: Language?
		let baseValue: Value
		if lhs.base.language == rhs.base.language {
			baseLanguage = lhs.base.language
			baseValue = lhs.base.value + rhs.base.value
		} else if lhs.base.language == nil {
			baseLanguage = rhs.base.language
			baseValue = lhs.resolved(rhs.base.language!) + rhs.base.value
		} else if rhs.base.language == nil {
			baseLanguage = lhs.base.language
			baseValue = lhs.base.value + rhs.resolved(lhs.base.language!)
		} else {
			var translationsKeys = Set(mergedTranslations.keys)
			let priorityLanguages = [lhs.base.language!, rhs.base.language!] + Locale.preferredLanguages.map(Language.init(rawValue:))
			let language: Language?
			if let lang = priorityLanguages.first(where: translationsKeys.contains) {
				language = lang
			} else {
				language = translationsKeys.sorted(by: { $0.rawValue < $1.rawValue }).first
			}
		
			if language == nil {
				assertionFailure("Localized + Localized: no shared coverage between anchors \(lhs.base.language!) and \(rhs.base.language!); base value will silently mix anchors.")
			}

			baseLanguage = language ?? lhs.base.language!
			baseValue = lhs.resolved(baseLanguage!) + rhs.resolved(baseLanguage!)
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
		return Localized(lhs.base.language, lhs.base.value + rhs, translations)
	}

	public static func + (_ lhs: Value, _ rhs: Localized) -> Localized {
		var translations: [Language: Value] = [:]
		for (lang, v) in rhs.translations {
			translations[lang] = lhs + v
		}
		return Localized(rhs.base.language, lhs + rhs.base.value, translations)
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
		let baseTag = base.language?.description ?? "any"
		return "Localized(\(baseTag): \(base.value), translations: [\(langs)])"
	}
}
