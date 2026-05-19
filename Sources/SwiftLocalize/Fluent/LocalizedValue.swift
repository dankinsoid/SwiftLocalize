// @ai-generated(solo)
import Foundation

public extension Fluent {

	/// Generic per-language container. Holds a value of arbitrary type per language tag.
	///
	/// Use for non-string assets where Fluent semantics don't apply: images, colors, audio,
	/// config blobs. For strings with plural/select/placeable, use `Bundle` / `LocalizedBundle`.
	///
	///     let flag: Fluent.Localized<String> = [
	///         .en: "🇬🇧",
	///         .ru: "🇷🇺",
	///     ]
	///     flag()              // current locale
	///     flag(language: .ru) // explicit
	///
	/// `Localized<UIImage>`, `Localized<URL>` etc. work the same way.
	struct Localized<Value>: ExpressibleByDictionaryLiteral {

		public var variants: [Tag: Value]
		/// Order in which to look up values when the requested language is missing.
		/// Default: empty (i.e. the first available variant wins after the request misses).
		public var fallbackChain: [Tag]

		public init(_ variants: [Tag: Value], fallbackChain: [Tag] = []) {
			self.variants = variants
			self.fallbackChain = fallbackChain
		}

		public init(dictionaryLiteral elements: (Tag, Value)...) {
			variants = Dictionary(uniqueKeysWithValues: elements)
			fallbackChain = []
		}

		public subscript(language: Tag) -> Value? {
			get { variants[language] }
			set { variants[language] = newValue }
		}

		/// Resolve to a `Value` for the requested language.
		/// Lookup order: requested → languageOnly(requested) → fallbackChain → first variant.
		public func callAsFunction(language: Tag = .current) -> Value? {
			if let v = variants[language] { return v }
			let base = language.languageOnly
			if base != language, let v = variants[base] { return v }
			for fb in fallbackChain {
				if let v = variants[fb] { return v }
			}
			return variants.first?.value
		}
	}
}

extension Fluent.Localized: Equatable where Value: Equatable {}
extension Fluent.Localized: Hashable where Value: Hashable {}
extension Fluent.Localized: Sendable where Value: Sendable {}
extension Fluent.Localized: Codable where Value: Codable {}

// MARK: - String convenience

public extension Fluent.Localized where Value == String {

	/// String-only convenience that never returns nil — falls back to "".
	func string(language: Fluent.Tag = .current) -> String {
		callAsFunction(language: language) ?? ""
	}
}

// MARK: - Multi-locale Fluent bundle

public extension Fluent {

	/// Aggregates one Fluent `Bundle` per locale and routes `format` calls to the right one.
	///
	/// Typical usage: load FTL resources into bundles keyed by locale, then call
	/// `localizedBundle.format("coins-count", args: ["count": 5])` and let it pick the
	/// bundle for the current language.
	final class LocalizedBundle: @unchecked Sendable {

		public private(set) var bundles: [Tag: Bundle] = [:]
		public var fallbackChain: [Tag]

		public init(fallbackChain: [Tag] = [.en]) {
			self.fallbackChain = fallbackChain
		}

		public func add(bundle: Bundle) {
			bundles[bundle.locale] = bundle
		}

		/// Returns or creates the bundle for the given locale.
		public func bundle(for locale: Tag) -> Bundle {
			if let b = bundles[locale] { return b }
			let new = Bundle(locale: locale)
			bundles[locale] = new
			return new
		}

		public func format(
			_ id: Identifier,
			attribute: Identifier? = nil,
			args: Arguments = [:],
			language: Tag = .current
		) -> String {
			let chain = [language, language.languageOnly] + fallbackChain
			for candidate in chain {
				if let bundle = bundles[candidate], bundle.messages[id] != nil {
					return bundle.format(id, attribute: attribute, args: args)
				}
			}
			return bundles[language]?.format(id, attribute: attribute, args: args)
				?? "{" + id.rawValue + (attribute.map { "." + $0.rawValue } ?? "") + "}"
		}
	}
}
