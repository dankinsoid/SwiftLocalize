// @ai-generated(guided)
import Foundation

/// Grammatical gender as classified by CLDR `grammaticalFeatures.json`.
///
/// Distinct from biological/social gender — these are language-level
/// categories for noun and adjective agreement. The set a language uses
/// depends on the language (`Language.grammaticalGenders`); not every
/// language has every value, and some have none at all (en, ja, zh, ko, …).
///
/// Standard three-gender languages (ru, de, el, …) use
/// `masculine` / `feminine` / `neuter`. Romance languages (fr, es, pt, it)
/// drop `neuter`. Common-gender languages (da, nl, sv) merge masculine and
/// feminine into `common`, leaving `common` / `neuter`. Slavic languages
/// (cs, hr, sk, sr, ml) split masculine into `animate` / `inanimate`;
/// Polish further adds `personal` for human-male nouns.
public enum GrammaticalGender: String, CaseIterable, Hashable, Codable, Sendable {
	case masculine, feminine, neuter, common, animate, inanimate, personal
}

/// A grammatical gender paired with a language — what `inflect(in:)` hands
/// to its closure. Mirrors `PluralCategorized`'s role on the plural side.
///
/// The pattern-match overload below lets `switch` cases stay terse:
/// `case .feminine:` matches `GenderCategorized` whose `gender == .feminine`.
public struct GenderCategorized: Hashable, Codable, Sendable {

	public var gender: GrammaticalGender
	public var language: Language

	public init(gender: GrammaticalGender, language: Language) {
		self.gender = gender
		self.language = language
	}
}

/// Lets `switch gc { case .feminine: … }` work without naming `.gender`.
public func ~= (category: GrammaticalGender, pattern: GenderCategorized) -> Bool {
	pattern.gender == category
}

public extension GrammaticalGender {

	/// Pick a form based on grammatical gender in `language`.
	///
	/// The closure receives a `GenderCategorized` that pattern-matches
	/// against `GrammaticalGender` cases. For languages without a
	/// grammatical gender system (en, ja, zh, …) supply a `default` branch —
	/// the gender is still passed through, but the caller should treat all
	/// branches as equivalent.
	///
	/// ```swift
	/// user.gender.inflect(in: .ru) {
	///     switch $0 {
	///     case .feminine: "Ты пришла"
	///     default:        "Ты пришёл"
	///     }
	/// }
	/// ```
	///
	/// Cross-language fallback (`fr` asked about `.neuter`, which fr lacks)
	/// is the caller's responsibility — typically the `default` branch
	/// covers it, but `Language.grammaticalGenders` is available for an
	/// explicit `contains` check when needed.
	func inflect<T>(in language: Language, _ body: (GenderCategorized) -> T) -> T {
		body(GenderCategorized(gender: self, language: language))
	}
}

public extension Language {

	/// Grammatical genders this language distinguishes per CLDR
	/// `grammaticalFeatures.json`.
	///
	/// Lookup is on the canonical primary subtag (`iw` → `he` → key `he`),
	/// since the CLDR file is keyed by language only — region/script
	/// variants share the same set.
	///
	/// Returns an empty set for languages with no grammatical gender
	/// (en, ja, zh, ko, fi, hu, tr, vi, fil, ms, th, lo, my, ne, am, az,
	/// ky, uz, bn, …). Callers can use emptiness as a fast skip for any
	/// gender-dependent formatting.
	///
	/// Examples:
	///   - `Language.ru.grammaticalGenders` → `[.masculine, .feminine, .neuter]`
	///   - `Language.fr.grammaticalGenders` → `[.masculine, .feminine]`
	///   - `Language.cs.grammaticalGenders` → `[.animate, .inanimate, .feminine, .neuter]`
	///   - `Language.pl.grammaticalGenders` → `[.animate, .inanimate, .personal, .feminine, .neuter]`
	///   - `Language.da.grammaticalGenders` → `[.common, .neuter]`
	///   - `Language.en.grammaticalGenders` → `[]`
	var grammaticalGenders: Set<GrammaticalGender> {
		GrammaticalGenderData.genders[canonical.language] ?? []
	}
}
