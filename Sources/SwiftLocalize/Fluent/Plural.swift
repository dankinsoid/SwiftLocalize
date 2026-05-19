// @ai-generated(solo)
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

extension Fluent.PluralCategory {

	/// Maps a number to its CLDR plural category for the given language tag and rule type.
	///
	/// Sketch implementation: cardinal covers en, ru, uk, pl, cs, sk, ar, cy, sl, ja/ko/zh/vi/th/id/ms;
	/// ordinal covers en, fr, it, ca, hu, cy, uk. Unsupported tags fall back to English-style cardinal
	/// (one/other) or to `.other` for ordinals.
	///
	/// TODO: replace with full CLDR-generated tables for production. Each language's rule set is
	/// mechanically derivable from `cldr-core/supplemental/{plurals,ordinals}.json`.
	public static func of(_ n: Double, locale: Fluent.Tag, type: Fluent.PluralType = .cardinal) -> Fluent.PluralCategory {
		switch type {
		case .cardinal: return cardinal(n, language: locale.language)
		case .ordinal: return ordinal(n, language: locale.language)
		}
	}

	static func cardinal(_ n: Double, language: String) -> Fluent.PluralCategory {
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

	/// CLDR ordinal plural rules. Most languages only use `.other` for ordinals;
	/// those listed here have meaningful distinctions ("1st/2nd/3rd/4th" in English,
	/// "1er/2e/3e" in French, etc.).
  static func ordinal(_ n: Double, language: String) -> Fluent.PluralCategory {
		let absN = abs(n)
		let i = Int(absN.rounded(.down))
		// Ordinals only meaningful for non-negative integers; non-integers fall through to .other.
		guard absN == Double(i) else { return .other }
		let mod10 = i % 10
		let mod100 = i % 100

		switch language {
		case "en":
			if mod10 == 1, mod100 != 11 { return .one }   // 1st, 21st, 31st
			if mod10 == 2, mod100 != 12 { return .two }   // 2nd, 22nd, 32nd
			if mod10 == 3, mod100 != 13 { return .few }   // 3rd, 23rd, 33rd
			return .other                                  // 4th, 11th, 12th, 13th, …

		case "fr":
			return i == 1 ? .one : .other

		case "it":
			// 8°, 11°, 80°, 800° take the "many" form in Italian ordinal rules.
			return (i == 8 || i == 11 || i == 80 || i == 800) ? .many : .other

		case "ca":
			if i == 1 || i == 3 { return .one }
			if i == 2 { return .two }
			if i == 4 { return .few }
			return .other

		case "hu":
			return (i == 1 || i == 5) ? .one : .other

		case "cy":
			if i == 0 || i == 7 || i == 8 || i == 9 { return .zero }
			if i == 1 { return .one }
			if i == 2 { return .two }
			if i == 3 || i == 4 { return .few }
			if i == 5 || i == 6 { return .many }
			return .other

		case "uk":
			if mod10 == 3, mod100 != 13 { return .few }
			return .other

		default:
			return .other
		}
	}
}
