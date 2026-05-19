// @ai-generated(guided)
import Foundation

public extension Fluent {

	/// Unicode CLDR plural categories. These are NOT grammatical cases — they classify
	/// numbers into buckets the language treats identically for plural agreement.
	/// See https://cldr.unicode.org/index/cldr-spec/plural-rules.
	enum PluralCategory: String, CaseIterable, Hashable, Codable, Sendable {
		case zero, one, two, few, many, other
	}

	/// Which CLDR plural rule set applies. Cardinal = "5 books"; ordinal = "5th place".
	/// Fluent exposes this via `NUMBER($n, type: "ordinal")`.
	enum PluralType: String, Hashable, Codable, Sendable {
		case cardinal, ordinal
	}
}

public extension Fluent.PluralCategory {

	/// Resolve a number to its plural category using the default rule for `locale.language`.
	///
	/// Bundles don't go through here — they pre-resolve `pluralRule` at init and call its
	/// closures directly. Use this helper for one-off lookups without a bundle, or in tests.
	/// To use a custom rule, call `PluralRule.cardinal/ordinal(n)` on the rule value directly.
	static func of(_ n: Double, locale: Fluent.Tag, type: Fluent.PluralType = .cardinal) -> Fluent.PluralCategory {
		let rule = Fluent.PluralRule.default(for: locale.language)
		switch type {
		case .cardinal: return rule.cardinal(n)
		case .ordinal:  return rule.ordinal(n)
		}
	}
}
