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
		///
		/// Lookup order: full CLDR-aware negotiation against `variants.keys` (canonicalizes
		/// aliases, maximizes via likely subtags, walks `parentLocales`), then the explicit
		/// `fallbackChain`, then the first available variant. Returns `nil` only when
		/// `variants` is empty.
		public func callAsFunction(language: Tag = .current) -> Value? {
			let chain = LocaleNegotiation.matching(
				requested: [language] + fallbackChain,
				available: Array(variants.keys)
			)
			for tag in chain {
				if let v = variants[tag] { return v }
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
	///
	/// Value type: holds a snapshot of `[Tag: Bundle]`. Free `Sendable`, safe to pass across
	/// threads. For runtime updates, wrap in a snapshot store that publishes replacement values.
	struct LocalizedBundle: Sendable {

		public private(set) var bundles: [Tag: Bundle] = [:]
		public var fallbackChain: [Tag]

		public init(fallbackChain: [Tag] = [.en]) {
			self.fallbackChain = fallbackChain
		}

		public mutating func add(bundle: Bundle) {
			bundles[bundle.locale] = bundle
		}

		/// Returns or creates the bundle for the given locale.
		///
		/// Lazy-insert: with value semantics, the returned bundle is a copy of the stored one.
		/// Mutating the result does **not** propagate back to this `LocalizedBundle` — use
		/// `add(bundle:)` to publish updates.
		public mutating func bundle(for locale: Tag) -> Bundle {
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
			let chain = LocaleNegotiation.matching(
				requested: [language] + fallbackChain,
				available: Array(bundles.keys)
			)
			// First bundle in the chain that defines this message wins. Missing-message
			// fallthrough is what makes asymmetric translations work — a string only
			// translated in `en` still renders for `ru` users.
			for candidate in chain {
				if let bundle = bundles[candidate], bundle.messages[id] != nil {
					return bundle.format(id, attribute: attribute, args: args)
				}
			}
			// Nothing in the chain has the message. Fall through to the most-preferred bundle
			// so it can emit the standard `{message-id}` placeholder marker.
			if let preferred = chain.first.flatMap({ bundles[$0] }) {
				return preferred.format(id, attribute: attribute, args: args)
			}
			return "{" + id.rawValue + (attribute.map { "." + $0.rawValue } ?? "") + "}"
		}
	}
}
