// @ai-generated(guided)
import Foundation

public extension Fluent {

	/// Plural rule for a single language: maps numbers to CLDR plural categories.
	///
	/// A rule is a pair of pure functions (cardinal + ordinal) — no language state, no
	/// shared mutable registry. `Fluent.Bundle` picks its rule once at init (from
	/// `PluralRule.default(for:)` or a caller-supplied override) and stores it as a `let`,
	/// so lookups during formatting are direct closure calls with zero synchronization.
	///
	/// To support a language not in `defaults`, construct your own value and pass it to
	/// `Bundle(locale:, pluralRule:)`. The per-language defaults live in
	/// `PluralRule+Generated.swift`, regenerated from CLDR via
	/// `Scripts/generate-plural-rules.py`.
	struct PluralRule: Sendable {

		public let cardinal: @Sendable (Double) -> PluralCategory
		public let ordinal:  @Sendable (Double) -> PluralCategory

		public init(
			cardinal: @escaping @Sendable (Double) -> PluralCategory,
			ordinal:  @escaping @Sendable (Double) -> PluralCategory = { _ in .other }
		) {
			self.cardinal = cardinal
			self.ordinal = ordinal
		}
	}
}

public extension Fluent.PluralRule {

	/// Returns the rule for a BCP-47 primary language subtag. Falls back to
	/// English-style one/other when the language is not present in `defaults`.
	static func `default`(for language: String, or fallback: @autoclosure () -> Self = identity) -> Self {
		defaults[language] ?? fallback()
	}

	static let identity = Self(cardinal: { abs($0) == 1 ? .one : .other })
}
