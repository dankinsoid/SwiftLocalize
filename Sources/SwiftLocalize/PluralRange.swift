// @ai-generated(guided)
import Foundation

/// A range of numbers tagged with the CLDR plural category to use for it.
///
/// Parallel to `PluralCategorized` but for two endpoints. The category is the
/// language's verdict on `(start_category, end_category)` from CLDR
/// `pluralRanges.json`, not just the category of one endpoint — e.g. `1...5`
/// in Russian is `.many` ("1\u{2013}5 яблок"), not `.one` (from `1`) or `.many`
/// (from `5`) by coincidence; it's what CLDR explicitly says about the pair.
public struct PluralRangeCategorized<Number> {

	public var start: Number
	public var end: Number
	public var category: PluralCategory
	public var language: Language

	public init(start: Number, end: Number, category: PluralCategory, language: Language) {
		self.start = start
		self.end = end
		self.category = category
		self.language = language
	}
}

extension PluralRangeCategorized: CustomStringConvertible {

	/// Locale-formatted endpoints joined by the language's CLDR range pattern,
	/// e.g. `"1\u{2013}5"` (en/ru), `"1\u{ff5e}5"` (ja). When start and end format
	/// to the same string (typical for `n...n`), collapses to a single value so
	/// `(5...5).plural(in: .ru) { "\($0) яблок" }` yields `"5 яблок"` rather
	/// than `"5\u{2013}5 яблок"`.
	public var description: String {
		let s = Self.format(start, in: language)
		let e = Self.format(end, in: language)
		if s == e { return s }
		return s.rangeJoined(to: e, in: language)
	}

	private static func format(_ value: Number, in language: Language) -> String {
		if let formattable = value as? any FormattableNumber {
			return formattable.formatted(lang: language)
		}
		if let nsnum = value as? NSNumber {
			let formatter = NumberFormatter()
			formatter.locale = Locale(identifier: language.rawValue)
			return formatter.string(from: nsnum) ?? "\(value)"
		}
		return "\(value)"
	}
}

extension PluralRangeCategorized: Hashable where Number: Hashable {}
extension PluralRangeCategorized: Equatable where Number: Equatable {}
extension PluralRangeCategorized: Decodable where Number: Decodable {}
extension PluralRangeCategorized: Encodable where Number: Encodable {}

/// Pattern-match on `PluralCategory` inside a `switch` over a categorized range —
/// mirrors `PluralCategorized`'s `~=` so range and single-number switches read the
/// same way.
public func ~=<Number>(category: PluralCategory, pattern: PluralRangeCategorized<Number>) -> Bool {
	pattern.category == category
}

public extension PluralCategory {

	/// Resolve the cardinal plural category for the range `[start, end]` in `language`.
	///
	/// Looks up the CLDR `pluralRanges` table (keyed by primary subtag) for the
	/// `(start_category, end_category)` pair. When the language is absent from
	/// the table — or the specific pair is — falls back to the end endpoint's
	/// own plural category, matching UTS #35: *"if no value is found, the
	/// result is the value for the end."*
	///
	/// Cardinal only by CLDR design; pluralRanges has no ordinal counterpart.
	static func ofRange(_ start: Double, _ end: Double, locale: Language) -> PluralCategory {
		let rule = PluralRule.default(for: locale.language)
		let startCat = rule.cardinal(start)
		let endCat = rule.cardinal(end)
		if let resolved = PluralRangeData.ranges[locale.language]?[startCat]?[endCat] {
			return resolved
		}
		return endCat
	}
}

public extension ClosedRange where Bound: FixedWidthInteger {

	/// Pick a form based on the CLDR **cardinal** plural category of the range
	/// in `language`.
	///
	/// CLDR defines a per-language 2D table mapping `(start_category, end_category)`
	/// to a single result category — different from picking either endpoint:
	/// in Russian `1...5` is `.many` ("1\u{2013}5 яблок"), not `.one` or `.few`.
	/// Use this when you'd otherwise be guessing which endpoint to dispatch on.
	///
	/// ```swift
	/// (1...5).plural(in: .ru) { r in
	///     switch r {
	///     case .one:  "\(r) яблоко"
	///     case .few:  "\(r) яблока"
	///     default:    "\(r) яблок"
	///     }
	/// }
	/// // → "1–5 яблок"
	/// ```
	func plural<T>(in language: Language, _ body: (PluralRangeCategorized<Bound>) -> T) -> T {
		body(PluralRangeCategorized(
			start: lowerBound,
			end: upperBound,
			category: .ofRange(
				Double(lowerBound), Double(upperBound),
				locale: language
			),
			language: language
		))
	}
}
