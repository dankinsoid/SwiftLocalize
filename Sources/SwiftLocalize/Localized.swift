import Foundation

@resultBuilder
public struct Localized<Value> {

	public let base: (language: Language?, value: Value)
	public let translations: [Language: Value]

	public init(
		_ baseLanguage: Language?,
		_ baseValue: Value,
		_ translations: [Language: Value] = [:]
	) {
		self.translations = translations
		self.base = (baseLanguage, baseValue)
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
		var translations = self.translations
		if let baseLanguage = base.language, translations[baseLanguage] == nil {
			translations[baseLanguage] = base.value
		}
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
	/// Result is universal (`base.language == nil`) iff both sides are universal;
	/// otherwise it's anchored to the first non-nil `base.language` of the two,
	/// left-biased on conflict. For every language explicitly covered by either
	/// side, the result holds `lhs.resolved(lang) + rhs.resolved(lang)` — so a
	/// universal side contributes its base value to every language slot of the
	/// other, and a localized side's missing translation falls back through its
	/// own negotiation chain (never silently through the other side's language).
	public static func + (_ lhs: Localized, _ rhs: Localized) -> Localized {
		// Two non-nil base languages should agree — otherwise `base.value` of the
		// result mixes scripts (lhs.base.value in lhs's language + rhs.base.value
		// in rhs's language, tagged as one of them). Caller bug worth surfacing.
		if let l = lhs.base.language, let r = rhs.base.language, l != r {
			assertionFailure("Localized + Localized: base languages disagree (\(l) vs \(r)); concatenated base mixes scripts.")
		}

		var languages = Set(lhs.translations.keys).union(rhs.translations.keys)
		if let lang = lhs.base.language { languages.insert(lang) }
		if let lang = rhs.base.language { languages.insert(lang) }

		let resultLanguage = lhs.base.language ?? rhs.base.language
		var translations: [Language: Value] = [:]
		for lang in languages where lang != resultLanguage {
			translations[lang] = lhs.resolved(lang) + rhs.resolved(lang)
		}
		return Localized(resultLanguage, lhs.base.value + rhs.base.value, translations)
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
