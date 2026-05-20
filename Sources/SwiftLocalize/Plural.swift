// @ai-generated(guided)
import Foundation

/// Unicode CLDR plural categories. These are NOT grammatical cases — they classify
/// numbers into buckets the language treats identically for plural agreement.
/// See https://cldr.unicode.org/index/cldr-spec/plural-rules.
public enum PluralCategory: String, CaseIterable, Hashable, Codable, Sendable, CodingKeyRepresentable {
	case zero, one, two, few, many, other
}

/// Which CLDR plural rule set applies. Cardinal = "5 books"; ordinal = "5th place".
public enum PluralType: String, Hashable, Codable, Sendable, CodingKeyRepresentable, CaseIterable {
	case cardinal, ordinal
}

public struct PluralCategorized<Number> {

	public var number: Number
	public var category: PluralCategory
	public var language: Language
	
	public init(number: Number, category: PluralCategory, language: Language) {
		self.number = number
		self.category = category
		self.language = language
	}
}

extension PluralCategorized: CustomStringConvertible {

	public var description: String {
		if let int = number as? any FormattableNumber {
			return int.formatted(lang: language)
		}
		if let number = number as? NSNumber {
			let formatter = NumberFormatter()
			formatter.locale = Locale(identifier: language.rawValue)
			return formatter.string(from: number) ?? "\(number)"
		}
		return "\(number)"
	}
}

extension PluralCategorized: Hashable where Number: Hashable {}
extension PluralCategorized: Equatable where Number: Equatable {}
extension PluralCategorized: Decodable where Number: Decodable {}
extension PluralCategorized: Encodable where Number: Encodable {}

public func ~=<Number: Equatable>(number: Number, pattern: PluralCategorized<Number>) -> Bool {
	pattern.number == number
}

public func ~=<Number>(category: PluralCategory, pattern: PluralCategorized<Number>) -> Bool {
	pattern.category == category
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

public extension FixedWidthInteger {

	/// Pick a form based on the CLDR **cardinal** plural category of `self` in `language`.
	///
	/// For counting — "1 song" / "5 songs" / "5 песен". The closure receives a
	/// `PluralCategorized<Self>` that pattern-matches against both `PluralCategory`
	/// cases (`.one`, `.few`, …) and the number itself (`case 0:`, `case 11:`).
	///
	/// ```swift
	/// n.plural(in: .ru) {
	///     switch $0 {
	///     case .one:  "\(n) песня"
	///     case .few:  "\(n) песни"
	///     default:    "\(n) песен"
	///     }
	/// }
	/// ```
	func plural<T>(in language: Language, _ body: (PluralCategorized<Self>) -> T) -> T {
		body(PluralCategorized(
			number: self,
			category: .of(Double(self), locale: language, type: .cardinal),
			language: language
		))
	}

	/// Pick a form based on the CLDR **ordinal** plural category of `self` in `language`.
	///
	/// For rank/position — "1st" / "2nd" / "21st" / "11th". Separate from `plural`
	/// because the CLDR rules differ: English ordinal categorises 1, 21, 31 as `.one`
	/// (matching the "-st" suffix), whereas cardinal collapses everything but 1 into `.other`.
	/// ```swift
	/// n.ordinal(in: .en) {
	///     switch $0 {
	///     case .one:  "\(n)st"
	///     case .two:  "\(n)nd"
	///     case .few:  "\(n)rd"
	///     default:    "\(n)th"
	///     }
	/// }
	/// ```
	func ordinal<T>(in language: Language, _ body: (PluralCategorized<Self>) -> T) -> T {
		body(PluralCategorized(
			number: self,
			category: .of(Double(self), locale: language, type: .ordinal),
			language: language
		))
	}
}

protocol FormattableNumber {
	
	func formatted(lang: Language) -> String
}

@available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
extension Int: FormattableNumber {
	func formatted(lang: Language) -> String {
		formatted(.number.language(lang))
	}
}
@available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
extension Int8: FormattableNumber {
	func formatted(lang: Language) -> String {
		formatted(.number.language(lang))
	}
}
@available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
extension Int16: FormattableNumber {
	func formatted(lang: Language) -> String {
		formatted(.number.language(lang))
	}
}
@available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
extension Int32: FormattableNumber {
	func formatted(lang: Language) -> String {
		formatted(.number.language(lang))
	}
}
@available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
extension Int64: FormattableNumber {
	func formatted(lang: Language) -> String {
		formatted(.number.language(lang))
	}
}
@available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
extension UInt: FormattableNumber {
	func formatted(lang: Language) -> String {
		formatted(.number.language(lang))
	}
}
@available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
extension UInt8: FormattableNumber {
	func formatted(lang: Language) -> String {
		formatted(.number.language(lang))
	}
}
@available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
extension UInt16: FormattableNumber {
	func formatted(lang: Language) -> String {
		formatted(.number.language(lang))
	}
}
@available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
extension UInt32: FormattableNumber {
	func formatted(lang: Language) -> String {
		formatted(.number.language(lang))
	}
}
@available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
extension UInt64: FormattableNumber {
	func formatted(lang: Language) -> String {
		formatted(.number.language(lang))
	}
}
@available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
extension Float: FormattableNumber {
	func formatted(lang: Language) -> String {
		formatted(.number.language(lang))
	}
}
@available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
extension Float16: FormattableNumber {
	func formatted(lang: Language) -> String {
		formatted(.number.language(lang))
	}
}
@available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
extension Double: FormattableNumber {
	func formatted(lang: Language) -> String {
		formatted(.number.language(lang))
	}
}
