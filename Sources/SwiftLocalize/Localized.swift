import Foundation

@resultBuilder
public struct Localized<Value> {

	private let translations: [Language: Value]
	private let any: Value?
	private let fallback: Value

	public init(
		_ translations: [Language: Value] = [:],
		any: Value? = nil,
		default fallback: Value
	) {
		self.translations = translations
		self.any = any
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
	///   2. Same-family negotiation (`en-US` → `en`).
	///   3. Explicit `any:` slot, if provided.
	///   4. `default:` fallback.
	///
	/// Cross-language mixing only via the explicit `any:` / `default:` slots —
	/// never silently through another language's translation.
	public func resolve(_ language: Language = .current) -> Value {
		if let v = translations[language] { return v }
		let bare = language.languageOnly
		if bare != language, let v = translations[bare] { return v }
		if let v = any { return v }
		return fallback
	}
	
	/// Resolve to a value for `language`.
	///
	/// Lookup order:
	///   1. Exact tag (`en-US`).
	///   2. Same-family negotiation (`en-US` → `en`).
	///   3. Explicit `any:` slot, if provided.
	///   4. `default:` fallback.
	///
	/// Cross-language mixing only via the explicit `any:` / `default:` slots —
	/// never silently through another language's translation.
	public func callAsFunction(_ language: Language = .current) -> Value {
		resolve(language)
	}

	public var localized: Value { callAsFunction() }

	/// Languages with an explicit translation — does not include those reached
	/// only via `any:` / `default:`.
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
		// `any` is preserved only when both sides explicitly opted in —
		// combining a "fits any language" with a regular fallback would
		// silently promote the fallback to an `any`.
		let combinedAny: Value? = {
			guard let l = lhs.any, let r = rhs.any else { return nil }
			return l + r
		}()
		return Localized(merged, any: combinedAny, default: lhs.fallback + rhs.fallback)
	}

	public static func + (_ lhs: Localized, _ rhs: Value) -> Localized {
		var merged: [Language: Value] = [:]
		for (lang, v) in lhs.translations {
			merged[lang] = v + rhs
		}
		return Localized(
			merged,
			any: lhs.any.map { $0 + rhs },
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
			any: rhs.any.map { lhs + $0 },
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
