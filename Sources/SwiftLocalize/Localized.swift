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
		guard !translations.isEmpty else { return baseValue } // asDict may be empty only if base is universal
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

	/// Apply `transform` to the base value and every translation. Language
	/// keys and the anchor (`base.language`) are preserved.
	// @ai-generated(solo)
	public func map<T>(_ transform: (Value) throws -> T) rethrows -> Localized<T> {
		try Localized<T>(
			baseLanguage,
			transform(baseValue),
			translations.mapValues(transform)
		)
	}
}

// MARK: - Concatenation
//
// Composition along the value axis: `Localized<String> + Localized<String>`
// concatenates per language. Only available where `Value` supports
// `append(contentsOf:)` — strings, arrays, attributed strings.

extension Localized where Value: RangeReplaceableCollection {

	/// Concatenate two localized values. Thin wrapper over
	/// `Sequence.joined(separator:)` — see there for per-language merging,
	/// anchor selection, and the `mul`-demotion rule for compositions with
	/// no shared coverage.
	public static func + (_ lhs: Localized, _ rhs: Localized) -> Localized {
		[lhs, rhs].joined()
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

public extension Sequence {

	/// Concatenate localized values into one, optionally with `separator`
	/// between adjacent elements.
	///
	/// One-pass equivalent of `parts[0] + sep + parts[1] + ... + sep + parts[n-1]`
	/// — computes the language union once and resolves each operand exactly
	/// once per language, avoiding the N−1 binary merges (and their repeated
	/// CLDR negotiation) that chained `+` would do. Binary `+` and the
	/// `Localized` result builder both delegate here.
	///
	/// **Per-language translations.** For every language covered by any
	/// operand, the result holds the concatenation of all operands'
	/// `tryResolved(lang)` values, with `separator` interleaved. CLDR
	/// negotiation participates on each lookup (canonical aliases, likely
	/// subtags, parent walks). An operand that can't produce a value for
	/// `lang` without falling through to its anchor drops the slot rather
	/// than silently mixing languages. A universal operand (`base.language
	/// == nil`) contributes its base value to every slot. The separator
	/// participates as a regular operand on both counts.
	///
	/// **Anchor (`base.language`).**
	/// - All operands universal → result is universal (`nil`).
	/// - Exactly one distinct anchor across operands → that anchor.
	/// - Multiple anchors with shared coverage → picked from the merged
	///   per-language map in this priority chain: each operand's anchor in
	///   caller order, then `Locale.preferredLanguages`; falls back to the
	///   alphabetically first covered language.
	/// - Multiple anchors with **no shared coverage** → the result tags as
	///   `Language.mul` (BCP-47 "multiple languages") and asserts in debug.
	///   The base value is the operand-by-operand concatenation of base
	///   values — content the caller asked for, with an honest tag that
	///   marks it distinguishable from intentional universal values.
	///
	/// **Base value.** When the chosen anchor has a merged slot, that slot's
	/// value is used (translation overrides on either side are honored). For
	/// universal or `mul` results, base values are concatenated directly.
	/// The slot for the chosen anchor is then removed from `translations` to
	/// avoid duplication with `base.value`.
	///
	/// **Disagreeing anchors.** Operands with different `base.language` still
	/// combine correctly when they cover the same languages through different
	/// anchors (e.g. `.en`-anchored with a `.fr` translation + `.fr`-anchored
	/// with an `.en` translation yields both `.en` and `.fr` slots). Alias
	/// and likely-subtag pairs (`iw`↔`he`, `zh-TW`↔`zh-Hant`) also pair
	/// correctly — that's `tryResolved`'s job, not exact-key lookup.
	///
	/// Edge cases: an empty sequence returns an empty universal value; a
	/// single element is returned unchanged (separator ignored).
	func joined<V: RangeReplaceableCollection>(
		separator: Localized<V>? = nil
	) -> Localized<V> where Element == Localized<V> {
		let parts = Array(self)
		guard !parts.isEmpty else { return Localized<V>(nil, V()) }
		if parts.count == 1 { return parts[0] }

		var languages = Set<Language>()
		for p in parts { languages.formUnion(p.availableLanguages) }
		if let separator { languages.formUnion(separator.availableLanguages) }

		var merged: [Language: V] = [:]
		merged.reserveCapacity(languages.count)

		for lang in languages {
			var sepValue: V? = nil
			if let separator {
				guard let v = separator.tryResolved(lang) else { continue }
				sepValue = v
			}
			var combined = V()
			var ok = true
			for (i, p) in parts.enumerated() {
				guard let v = p.tryResolved(lang) else { ok = false; break }
				if i > 0, let sepValue { combined.append(contentsOf: sepValue) }
				combined.append(contentsOf: v)
			}
			if ok { merged[lang] = combined }
		}

		// Collect anchors in caller order, deduplicated. Separator's anchor
		// participates too — an anchored separator commits the result to its
		// language family the same way an anchored part does.
		var anchors: [Language] = []
		var seen = Set<Language>()
		for p in parts {
			if let lang = p.base.language, seen.insert(lang).inserted {
				anchors.append(lang)
			}
		}
		if let lang = separator?.base.language, seen.insert(lang).inserted {
			anchors.append(lang)
		}

		// Concat of base values (operand-by-operand, with separator). Used
		// when the result is universal *or* when no anchor has full coverage
		// and we tag `mul`.
		func mixedBaseValue() -> V {
			var v = parts[0].base.value
			for i in 1..<parts.count {
				if let separator { v.append(contentsOf: separator.base.value) }
				v.append(contentsOf: parts[i].base.value)
			}
			return v
		}

		let baseLanguage: Language?
		let baseValue: V

		if anchors.isEmpty {
			baseLanguage = nil
			baseValue = mixedBaseValue()
		} else if anchors.count == 1 {
			// Every operand either shares this anchor or is universal — both
			// always resolve under it, so `merged[anchor]` is populated.
			baseLanguage = anchors[0]
			baseValue = merged[anchors[0]]!
		} else {
			let mergedKeys = Set(merged.keys)
			let priority = anchors + Locale.preferredLanguages.map(Language.init(rawValue:))
			if let picked = priority.first(where: mergedKeys.contains)
				?? mergedKeys.sorted(by: { $0.rawValue < $1.rawValue }).first {
				baseLanguage = picked
				baseValue = merged[picked]!
			} else {
				// No language covers all operands. The result necessarily
				// mixes languages; tag `mul` so callers can distinguish it
				// from `nil`-anchored "universal by design" values.
				assertionFailure("Sequence<Localized>.joined: no shared coverage among anchors \(anchors); result tagged `mul`.")
				baseLanguage = .mul
				baseValue = mixedBaseValue()
			}
		}

		var translations = merged
		if let baseLanguage {
			translations.removeValue(forKey: baseLanguage)
		}

		return Localized<V>(baseLanguage, baseValue, translations)
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
