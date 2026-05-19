// @ai-generated(solo)
import Foundation

public extension Fluent {

	/// Unicode CLDR plural categories. These are NOT grammatical cases — they classify
	/// numbers into buckets the language treats identically for plural agreement.
	/// See https://cldr.unicode.org/index/cldr-spec/plural-rules.
	enum PluralCategory: String, CaseIterable, Hashable, Codable, Sendable {
		case zero, one, two, few, many, other
	}
}

public extension Fluent.PluralCategory {

	/// Maps a number to its CLDR plural category for the given language tag.
	///
	/// Sketch implementation: covers en, ru, uk, pl, cs, sk, ar, cy, sl, ja/ko/zh/vi/th/id/ms.
	/// For unsupported tags falls back to English-style (one/other).
	///
	/// TODO: replace with full CLDR-generated table for production. Each language's
	/// rule set is mechanically derivable from `cldr-core/supplemental/plurals.json`.
	static func of(_ n: Double, locale: Fluent.Tag) -> Fluent.PluralCategory {
		Self.cardinal(n, language: locale.language)
	}

	internal static func cardinal(_ n: Double, language: String) -> Fluent.PluralCategory {
		let absN = abs(n)
		let i = Int(absN.rounded(.down))
		let isInteger = absN == Double(i)
		let mod10 = i % 10
		let mod100 = i % 100

		switch language {
		case "ja", "ko", "zh", "vi", "th", "id", "ms", "fa", "tr", "hu":
			return .other

		case "en", "de", "nl", "sv", "da", "nb", "fi", "et", "el", "it", "es", "pt", "ca":
			return absN == 1 ? .one : .other

		case "fr", "hi":
			return (absN >= 0 && absN < 2) ? .one : .other

		case "ru", "uk", "be":
			if !isInteger { return .other }
			if mod10 == 1, mod100 != 11 { return .one }
			if (2 ... 4).contains(mod10), !(12 ... 14).contains(mod100) { return .few }
			return .many

		case "pl":
			if !isInteger { return .other }
			if i == 1 { return .one }
			if (2 ... 4).contains(mod10), !(12 ... 14).contains(mod100) { return .few }
			return .many

		case "cs", "sk":
			if !isInteger { return .other }
			if i == 1 { return .one }
			if (2 ... 4).contains(i) { return .few }
			return .many

		case "ar":
			if absN == 0 { return .zero }
			if absN == 1 { return .one }
			if absN == 2 { return .two }
			if isInteger, (3 ... 10).contains(mod100) { return .few }
			if isInteger, (11 ... 99).contains(mod100) { return .many }
			return .other

		case "cy":
			if absN == 0 { return .zero }
			if absN == 1 { return .one }
			if absN == 2 { return .two }
			if absN == 3 { return .few }
			if absN == 6 { return .many }
			return .other

		case "sl":
			if !isInteger { return .other }
			if mod100 == 1 { return .one }
			if mod100 == 2 { return .two }
			if mod100 == 3 || mod100 == 4 { return .few }
			return .other

		case "he":
			if absN == 1 { return .one }
			if absN == 2 { return .two }
			if isInteger, i % 10 == 0, i >= 20 { return .many }
			return .other

		default:
			return absN == 1 ? .one : .other
		}
	}
}
