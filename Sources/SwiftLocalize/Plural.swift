// @ai-generated(guided)
import Foundation

/// Unicode CLDR plural categories. These are NOT grammatical cases — they classify
/// numbers into buckets the language treats identically for plural agreement.
/// See https://cldr.unicode.org/index/cldr-spec/plural-rules.
public enum PluralCategory: String, CaseIterable, Hashable, Codable, Sendable {
	case zero, one, two, few, many, other
}

/// Which CLDR plural rule set applies. Cardinal = "5 books"; ordinal = "5th place".
public enum PluralType: String, Hashable, Codable, Sendable {
	case cardinal, ordinal
}

public extension PluralCategory {

	/// Resolve a number to its plural category using the default rule for `locale.language`.
	///
	/// Bundles don't go through here — they pre-resolve `pluralRule` at init and call its
	/// closures directly. Use this helper for one-off lookups without a bundle, or in tests.
	/// To use a custom rule, call `PluralRule.cardinal/ordinal(n)` on the rule value directly.
	static func of(_ n: Double, locale: Language, type: PluralType = .cardinal) -> PluralCategory {
		let rule = PluralRule.default(for: locale.language)
		switch type {
		case .cardinal: return rule.cardinal(n)
		case .ordinal:  return rule.ordinal(n)
		}
	}
}
