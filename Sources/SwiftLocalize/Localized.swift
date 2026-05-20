import Foundation

@resultBuilder
public struct Localized<Value> {

	public let translations: [Language: Value]
	public let fallback: Value

	public init(
		_ translations: [Language: Value] = [:],
		default fallback: Value
	) {
		self.translations = translations
		self.fallback = fallback
	}

	/// Wrap a single value as a `Localized` with no per-language translations.
	/// The same value is returned for every language.
	public init(_ value: Value) {
		self.init(default: value)
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
	public func resolve(_ language: Language = .current) -> Value {
		if let v = translations[language] { return v }
		if !translations.isEmpty {
			let chain = LocaleNegotiation.matching(
				requested: [language],
				available: Array(translations.keys)
			)
			for tag in chain {
				if let v = translations[tag] { return v }
			}
		}
		return fallback
	}

	/// See `resolve(_:)`.
	public func callAsFunction(_ language: Language = .current) -> Value {
		resolve(language)
	}

	public var localized: Value { callAsFunction() }

	/// Languages with an explicit translation — does not include those reached
	/// only via `default:`.
	public var explicitLanguages: Set<Language> { Set(translations.keys) }
}

// MARK: - Concatenation
//
// Composition along the value axis: `Localized<String> + Localized<String>`
// concatenates per language. Only available where `Value` supports
// `append(contentsOf:)` — strings, arrays, attributed strings.

extension Localized where Value: RangeReplaceableCollection {

	public static func + (_ lhs: Localized, _ rhs: Localized) -> Localized {
		// Resolve each side at every language present in either, so a side
		// without that language contributes via its own fallback chain rather
		// than dropping its half.
		let keys = lhs.explicitLanguages.union(rhs.explicitLanguages)
		var merged: [Language: Value] = [:]
		for key in keys {
			merged[key] = lhs(key) + rhs(key)
		}
		return Localized(merged, default: lhs.fallback + rhs.fallback)
	}

	public static func + (_ lhs: Localized, _ rhs: Value) -> Localized {
		var merged: [Language: Value] = [:]
		for (lang, v) in lhs.translations {
			merged[lang] = v + rhs
		}
		return Localized(
			merged,
			default: lhs.fallback + rhs
		)
	}

	public static func + (_ lhs: Value, _ rhs: Localized) -> Localized {
		var merged: [Language: Value] = [:]
		for (lang, v) in rhs.translations {
			merged[lang] = lhs + v
		}
		return Localized(
			merged,
			default: lhs + rhs.fallback
		)
	}

	public static func += (_ lhs: inout Localized, _ rhs: Localized) {
		lhs = lhs + rhs
	}

	public static func += (_ lhs: inout Localized, _ rhs: Value) {
		lhs = lhs + rhs
	}
}

// MARK: - Description (deprecated to flush silent `.current` resolution)
//
// Conforming to `CustomStringConvertible` is what makes `"\(localized)"` —
// or any `String(describing:)` / `print` — produce a localized string at
// `.current`. That's the silent path we want callers to notice. Keep the
// conformance for visibility in debugging, but warn on use so the implicit
// path doesn't sneak into UI strings unobserved.

extension Localized: CustomStringConvertible where Value: CustomStringConvertible {

	@available(*, deprecated, message: "Implicit `.current` resolution. Use `localized.localized` for the current locale, or `localized(.en)` for an explicit language.")
	public var description: String { callAsFunction().description }
}

// MARK: - Literal conformances

extension Localized: ExpressibleByExtendedGraphemeClusterLiteral where Value: ExpressibleByStringLiteral {

	public init(extendedGraphemeClusterLiteral value: Value.ExtendedGraphemeClusterLiteralType) {
		self.init(default: Value(extendedGraphemeClusterLiteral: value))
	}
}

extension Localized: ExpressibleByStringLiteral where Value: ExpressibleByStringLiteral {

	public init(stringLiteral value: Value.StringLiteralType) {
		self.init(default: Value(stringLiteral: value))
	}
}

extension Localized: ExpressibleByUnicodeScalarLiteral where Value: ExpressibleByStringLiteral {

	public init(unicodeScalarLiteral value: Value.UnicodeScalarLiteralType) {
		self.init(default: Value(unicodeScalarLiteral: value))
	}
}

extension Localized: ExpressibleByStringInterpolation where Value: ExpressibleByStringInterpolation {

	public init(stringInterpolation: Value.StringInterpolation) {
		self.init(default: Value(stringInterpolation: stringInterpolation))
	}
}
