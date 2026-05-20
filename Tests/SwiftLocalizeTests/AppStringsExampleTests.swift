// @ai-generated(solo)
//
// A realistic, app-side strings catalog wired through the SwiftLocalize public API.
// The goal is to surface what's ergonomic and what is not — every kind of usage
// a real feature module would hit (static constants, interpolation, plurals,
// ordinals, builder composition) is exercised below, then verified in tests.
//
// Pain points are documented inline where they appear so they're easy to spot
// when reviewing the API.

@testable import SwiftLocalize
import XCTest

// MARK: - Domain gender (separate type from `GrammaticalGender`)
//
// `GrammaticalGender` is a language property — the small fixed CLDR set used
// for inflection. The app's user gender is a data property whose vocabulary
// can drift (`nonBinary`, `unspecified`, …) without polluting the
// grammatical taxonomy. Keep them as separate types and map at the edge of
// each localized string — that's what `grammatical(in:)` below does.

enum UserGender {
	case male, female
}

extension UserGender {

	/// Map a person's gender to the slot the target language actually uses
	/// for human masculine / feminine.
	///
	///   - Polish has `.personal` for male humans (distinct from `.animate`
	///     used for male non-human animals).
	///   - Czech / Croatian / Slovak / Serbian / Malayalam split masculine
	///     into `.animate` / `.inanimate`; humans take `.animate`.
	///   - Common-gender languages (Danish / Dutch / Swedish) collapse both
	///     into `.common`.
	///   - Languages with no gender (en, ja, zh, …) get the raw masculine /
	///     feminine back — caller's `default` branch will ignore it.
	func grammatical(in language: Language) -> GrammaticalGender {
		let supported = language.grammaticalGenders
		switch self {
		case .female:
			return supported.contains(.feminine) ? .feminine
				 : supported.contains(.common)   ? .common
				 : .feminine
		case .male:
			return supported.contains(.personal)  ? .personal
				 : supported.contains(.animate)   ? .animate
				 : supported.contains(.masculine) ? .masculine
				 : supported.contains(.common)    ? .common
				 : .masculine
		}
	}
}

// MARK: - App strings catalog

enum AppStrings {

	// MARK: Static constants
	//
	// String-literal initializer (`ExpressibleByStringLiteral`) is the cleanest
	// shape — a one-language constant reads as a plain string.
	static let appName: Localized<String> = "Tunes"

	// Multi-language constants need the explicit
	// `Localized(baseLanguage, baseValue, translations)` initializer because
	// there's no `ExpressibleByDictionaryLiteral`. The base slot carries the
	// canonical source (here English) without having to repeat it in the
	// translations dictionary.
	static let cancel = Localized<String>(
		.en, "Cancel",
		[.ru: "Отмена", .de: "Abbrechen", .fr: "Annuler"]
	)

	static let delete = Localized<String>(
		.en, "Delete",
		[.ru: "Удалить", .de: "Löschen", .fr: "Supprimer"]
	)

	static let networkErrorTitle = Localized<String>(
		.en, "No internet connection",
		 [.ru: "Нет подключения к интернету",
		 .de: "Keine Internetverbindung",
		 .fr: "Pas de connexion internet"]
	)

	// MARK: Interpolation
	//
	// Each translation is a normal `String` literal, so `\(name)` interpolates
	// at call time. The cost is that translators see the full Swift source —
	// fine for in-codebase strings, not great if these ever ship out to a TMS.
	static func welcomeBack(name: String) -> Localized<String> {
		Localized(
			.en, "Welcome back, \(name)!",
			[.ru: "С возвращением, \(name)!",
			 .de: "Willkommen zurück, \(name)!",
			 .fr: "Bon retour, \(name) !"]
		)
	}

	// MARK: Plurals — cardinal
	//
	// `n.plural(in:_:)` dispatches `n` through the language's CLDR cardinal rule
	// and hands the category to the closure. The closure pattern-matches on
	// either `PluralCategory` cases or the number itself — both are supported
	// by `PluralCategorized`'s `~=` overloads.
	static func songsCount(_ n: Int) -> Localized<String> {
		Localized(
			.en, n.plural(in: .en) { n in
				switch n {
				case .one: "\(n) song"
				default:   "\(n) songs"
				}
			},
			[
				.ru: n.plural(in: .ru) { n in
					switch n {
					case .one: "\(n) песня"
					case .few: "\(n) песни"
					default:   "\(n) песен"
					}
				},
				.de: n.plural(in: .de) { n in
					switch n {
					case .one: "\(n) Lied"
					default:   "\(n) Lieder"
					}
				},
				.fr: n.plural(in: .fr) { n in
					switch n {
					case .one: "\(n) chanson"
					default:   "\(n) chansons"
					}
				},
			]
		)
	}

	static func minutesAgo(_ n: Int) -> Localized<String> {
		Localized(
			.en, n.plural(in: .en) { n in
				switch n {
				case .one: "1 minute ago"
				default:   "\(n) minutes ago"
				}
			},
			[
				.ru: n.plural(in: .ru) { n in
					switch n {
					case .one: "\(n) минуту назад"
					case .few: "\(n) минуты назад"
					default:   "\(n) минут назад"
					}
				},
			]
		)
	}

	// MARK: Plurals — ordinal
	//
	// `n.ordinal(in:_:)` is the parallel to `.plural` but routed through CLDR's
	// ordinal rule set. English needs four suffixes (st/nd/rd/th, with the
	// teens collapsing to "th"); Russian/German/French use a single suffix and
	// don't need the closure at all.
	static func placeNumber(_ n: Int) -> Localized<String> {
		Localized(
			.en, n.ordinal(in: .en) { n in
				switch n {
				case .one: "\(n)st place"
				case .two: "\(n)nd place"
				case .few: "\(n)rd place"
				default:   "\(n)th place"
				}
			},
			[
				.ru: "\(n)-е место",
				.de: "\(n). Platz",
				.fr: n.ordinal(in: .fr) { n in
					switch n {
					case .one: "\(n)ᵉʳ place"
					default:   "\(n)ᵉ place"
					}
				},
			]
		)
	}

	// MARK: Gender — verb / adjective agreement
	//
	// `GrammaticalGender` has no closure-based dispatch like `plural` does:
	// the gender is already known to the caller (it's a data property of the
	// user), so there's nothing to compute. The pattern is just a plain
	// `switch` per language, fed by the `UserGender.grammatical(in:)` mapper
	// defined above.
	//
	// English doesn't agree, so the base value ignores `gender`. Russian
	// past tense and French past participle with `être` agree in gender;
	// Polish past tense does too. `default` covers both the masculine slot
	// for the language *and* the language-without-gender case (en) when this
	// string is asked for a tag we didn't translate explicitly.
	static func signedIn(name: String, gender: UserGender) -> Localized<String> {
		let ru: String = switch gender.grammatical(in: .ru) {
			case .feminine: "\(name) вошла"
			default:        "\(name) вошёл"
		}
		let fr: String = switch gender.grammatical(in: .fr) {
			case .feminine: "\(name) s'est connectée"
			default:        "\(name) s'est connecté"
		}
		let pl: String = switch gender.grammatical(in: .pl) {
			case .feminine: "\(name) zalogowała się"
			default:        "\(name) zalogował się"
		}
		return Localized(
			.en, "\(name) signed in",
			[.ru: ru, .fr: fr, .pl: pl]
		)
	}

	// MARK: Composition via @LocalizedBuilder
	//
	// The builder is the API's high point — declarative concatenation that
	// preserves every language present in any fragment, with fallback per
	// fragment rather than dropping halves. A real composite string (a
	// playlist summary mixing static fragments, a user-supplied name, and
	// a pluralised count) reads almost like prose.
	@Localized<String>
	static func playlistSummary(name: Localized<String>, count: Int) -> Localized<String> {
		Localized<String>(
			.en, "Playlist “",
			[.ru: "Плейлист «", .de: "Playlist „", .fr: "Liste « "]
		)
		name
		Localized<String>(
			.en, "”, ",
			[.ru: "», ", .de: "“, ", .fr: " », "]
		)
		songsCount(count)
		"."
	}
}

// MARK: - Tests

final class AppStringsExampleTests: XCTestCase {

	// MARK: Constants

	func testConstantsResolveByLanguage() {
		XCTAssertEqual(AppStrings.cancel.resolved(.en), "Cancel")
		XCTAssertEqual(AppStrings.cancel.resolved(.ru), "Отмена")
		XCTAssertEqual(AppStrings.cancel.resolved(.de), "Abbrechen")
		XCTAssertEqual(AppStrings.cancel.resolved(.fr), "Annuler")
	}

	func testRegionalVariantFallsBackToBaseLanguage() {
		// `en-US` is not in the table; CLDR-aware negotiation should walk to `en`.
		XCTAssertEqual(AppStrings.cancel.resolved("en-US"), "Cancel")
		XCTAssertEqual(AppStrings.cancel.resolved("ru-RU"), "Отмена")
		XCTAssertEqual(AppStrings.cancel.resolved("de-AT"), "Abbrechen")
	}

	func testUnknownLanguageFallsBackToDefault() {
		XCTAssertEqual(AppStrings.cancel.resolved("ja"), "Cancel")
		XCTAssertEqual(AppStrings.networkErrorTitle.resolved("zh"), "No internet connection")
	}

	func testStringLiteralConstantIsLanguageAgnostic() {
		XCTAssertEqual(AppStrings.appName.resolved(.en), "Tunes")
		XCTAssertEqual(AppStrings.appName.resolved(.ru), "Tunes")
		XCTAssertEqual(AppStrings.appName.resolved("ja"), "Tunes")
	}

	// MARK: Interpolation

	func testInterpolation() {
		XCTAssertEqual(
			AppStrings.welcomeBack(name: "Anna").resolved(.en),
			"Welcome back, Anna!"
		)
		XCTAssertEqual(
			AppStrings.welcomeBack(name: "Анна").resolved(.ru),
			"С возвращением, Анна!"
		)
	}

	// MARK: Plurals — cardinal

	func testPluralsEnglish() {
		XCTAssertEqual(AppStrings.songsCount(0).resolved(.en), "0 songs")
		XCTAssertEqual(AppStrings.songsCount(1).resolved(.en), "1 song")
		XCTAssertEqual(AppStrings.songsCount(2).resolved(.en), "2 songs")
		XCTAssertEqual(AppStrings.songsCount(42).resolved(.en), "42 songs")
	}

	func testPluralsRussian() {
		// 1, 21, 31… → one
		XCTAssertEqual(AppStrings.songsCount(1).resolved(.ru), "1 песня")
		XCTAssertEqual(AppStrings.songsCount(21).resolved(.ru), "21 песня")
		// 2–4, 22–24… → few
		XCTAssertEqual(AppStrings.songsCount(2).resolved(.ru), "2 песни")
		XCTAssertEqual(AppStrings.songsCount(3).resolved(.ru), "3 песни")
		XCTAssertEqual(AppStrings.songsCount(22).resolved(.ru), "22 песни")
		// 0, 5–20, 25–30… → many
		XCTAssertEqual(AppStrings.songsCount(0).resolved(.ru), "0 песен")
		XCTAssertEqual(AppStrings.songsCount(5).resolved(.ru), "5 песен")
		XCTAssertEqual(AppStrings.songsCount(11).resolved(.ru), "11 песен")
		XCTAssertEqual(AppStrings.songsCount(25).resolved(.ru), "25 песен")
	}

	func testPluralsFrenchAndGerman() {
		XCTAssertEqual(AppStrings.songsCount(0).resolved(.fr), "0 chanson") // fr: 0 and 1 → one
		XCTAssertEqual(AppStrings.songsCount(1).resolved(.fr), "1 chanson")
		XCTAssertEqual(AppStrings.songsCount(2).resolved(.fr), "2 chansons")

		XCTAssertEqual(AppStrings.songsCount(1).resolved(.de), "1 Lied")
		XCTAssertEqual(AppStrings.songsCount(7).resolved(.de), "7 Lieder")
	}

	func testMinutesAgoUsesOneForBoth() {
		XCTAssertEqual(AppStrings.minutesAgo(1).resolved(.en), "1 minute ago")
		XCTAssertEqual(AppStrings.minutesAgo(5).resolved(.en), "5 minutes ago")
		XCTAssertEqual(AppStrings.minutesAgo(1).resolved(.ru), "1 минуту назад")
		XCTAssertEqual(AppStrings.minutesAgo(5).resolved(.ru), "5 минут назад")
	}

	// MARK: Plurals — ordinal

	func testEnglishOrdinals() {
		XCTAssertEqual(AppStrings.placeNumber(1).resolved(.en), "1st place")
		XCTAssertEqual(AppStrings.placeNumber(2).resolved(.en), "2nd place")
		XCTAssertEqual(AppStrings.placeNumber(3).resolved(.en), "3rd place")
		XCTAssertEqual(AppStrings.placeNumber(4).resolved(.en), "4th place")
		// Teens collapse to "th".
		XCTAssertEqual(AppStrings.placeNumber(11).resolved(.en), "11th place")
		XCTAssertEqual(AppStrings.placeNumber(12).resolved(.en), "12th place")
		XCTAssertEqual(AppStrings.placeNumber(13).resolved(.en), "13th place")
		// And then resume.
		XCTAssertEqual(AppStrings.placeNumber(21).resolved(.en), "21st place")
		XCTAssertEqual(AppStrings.placeNumber(22).resolved(.en), "22nd place")
	}

	func testOtherLanguageOrdinals() {
		XCTAssertEqual(AppStrings.placeNumber(1).resolved(.ru), "1-е место")
		XCTAssertEqual(AppStrings.placeNumber(2).resolved(.de), "2. Platz")
		XCTAssertEqual(AppStrings.placeNumber(1).resolved(.fr), "1ᵉʳ place")
		XCTAssertEqual(AppStrings.placeNumber(2).resolved(.fr), "2ᵉ place")
	}

	// MARK: Gender — language metadata

	func testGrammaticalGendersPerLanguage() {
		// Three-gender languages (m / f / n).
		XCTAssertEqual(Language.ru.grammaticalGenders, [.masculine, .feminine, .neuter])
		XCTAssertEqual(Language.de.grammaticalGenders, [.masculine, .feminine, .neuter])
		// Romance — masculine / feminine, no neuter.
		XCTAssertEqual(Language.fr.grammaticalGenders, [.masculine, .feminine])
		XCTAssertEqual(Language.es.grammaticalGenders, [.masculine, .feminine])
		// Slavic animacy split — no plain `.masculine`; it's `.animate` /`.inanimate`.
		XCTAssertEqual(Language.cs.grammaticalGenders, [.animate, .inanimate, .feminine, .neuter])
		// Polish adds `.personal` on top of animacy — for human-male nouns.
		XCTAssertTrue(Language.pl.grammaticalGenders.contains(.personal))
		// Common gender — masculine and feminine merged.
		XCTAssertEqual(Language.da.grammaticalGenders, [.common, .neuter])
		XCTAssertEqual(Language.nl.grammaticalGenders, [.common, .neuter])
		// No grammatical gender — emptiness is a usable signal (skip gender logic).
		XCTAssertTrue(Language.en.grammaticalGenders.isEmpty)
		XCTAssertTrue(Language("ja").grammaticalGenders.isEmpty)
		XCTAssertTrue(Language("zh").grammaticalGenders.isEmpty)
	}

	func testGrammaticalGendersResolvesAliasesAndRegions() {
		// `iw` is the deprecated alias for `he` — canonicalization should
		// land on Hebrew's set even though only `he` is in the CLDR table.
		XCTAssertEqual(Language("iw").grammaticalGenders, [.masculine, .feminine])
		XCTAssertEqual(Language("he").grammaticalGenders, [.masculine, .feminine])
		// Region tags share the parent language's set (CLDR keys are primary
		// subtag only). `ru-RU` / `de-AT` / `fr-CA` should all match the bare
		// language's genders.
		XCTAssertEqual(Language("ru-RU").grammaticalGenders, [.masculine, .feminine, .neuter])
		XCTAssertEqual(Language("de-AT").grammaticalGenders, [.masculine, .feminine, .neuter])
		XCTAssertEqual(Language("fr-CA").grammaticalGenders, [.masculine, .feminine])
		XCTAssertEqual(Language("en-GB").grammaticalGenders, [])
	}

	// MARK: Gender — domain mapping

	func testUserGenderMapsToLanguageSpecificCategory() {
		// Standard three-gender — direct masculine / feminine.
		XCTAssertEqual(UserGender.male.grammatical(in: .ru),   .masculine)
		XCTAssertEqual(UserGender.female.grammatical(in: .ru), .feminine)
		XCTAssertEqual(UserGender.male.grammatical(in: .de),   .masculine)
		XCTAssertEqual(UserGender.female.grammatical(in: .fr), .feminine)
		// Slavic animacy split — male humans land on `.animate`, not `.masculine`.
		XCTAssertEqual(UserGender.male.grammatical(in: .cs),   .animate)
		XCTAssertEqual(UserGender.female.grammatical(in: .cs), .feminine)
		// Polish prefers `.personal` over `.animate` for male humans.
		XCTAssertEqual(UserGender.male.grammatical(in: .pl),   .personal)
		XCTAssertEqual(UserGender.female.grammatical(in: .pl), .feminine)
		// Common-gender languages collapse both.
		XCTAssertEqual(UserGender.male.grammatical(in: .da),   .common)
		XCTAssertEqual(UserGender.female.grammatical(in: .da), .common)
		// No-gender language — mapping is irrelevant; caller's `default`
		// branch will ignore the result. We return the literal masculine /
		// feminine slot so equality is at least deterministic.
		XCTAssertEqual(UserGender.male.grammatical(in: .en),   .masculine)
		XCTAssertEqual(UserGender.female.grammatical(in: .en), .feminine)
	}

	// MARK: Gender — localized strings

	func testSignedInRussianAgreesInGender() {
		XCTAssertEqual(AppStrings.signedIn(name: "Анна",  gender: .female).resolved(.ru), "Анна вошла")
		XCTAssertEqual(AppStrings.signedIn(name: "Иван",  gender: .male).resolved(.ru),   "Иван вошёл")
	}

	func testSignedInFrenchAgreesInGender() {
		// Past participle with `être` agrees with the subject's gender.
		XCTAssertEqual(AppStrings.signedIn(name: "Anna", gender: .female).resolved(.fr), "Anna s'est connectée")
		XCTAssertEqual(AppStrings.signedIn(name: "Marc", gender: .male).resolved(.fr),   "Marc s'est connecté")
	}

	func testSignedInPolishAgreesInGender() {
		// Polish past tense agrees in gender; for the 2nd-person form here,
		// male humans use the masculine-personal form (`.personal` via
		// `UserGender.grammatical`), which switches our `default` branch.
		XCTAssertEqual(AppStrings.signedIn(name: "Anna",  gender: .female).resolved(.pl), "Anna zalogowała się")
		XCTAssertEqual(AppStrings.signedIn(name: "Marek", gender: .male).resolved(.pl),   "Marek zalogował się")
	}

	func testSignedInEnglishIgnoresGender() {
		// English doesn't agree in gender — both calls produce the same string.
		XCTAssertEqual(AppStrings.signedIn(name: "Anna", gender: .female).resolved(.en), "Anna signed in")
		XCTAssertEqual(AppStrings.signedIn(name: "Marc", gender: .male).resolved(.en),   "Marc signed in")
	}

	// MARK: Builder composition

	func testPlaylistSummaryComposesFragmentsPerLanguage() {
		let summary = AppStrings.playlistSummary(
			// `nil` anchor → `name` acts as a universal fallback in concat, so a
			// language without its own translation (here `.de`) can still wrap the
			// base value instead of dropping the whole slot.
			name: Localized(nil, "Chill Vibes", [.ru: "Чилл-плейлист"]),
			count: 3
		)
		XCTAssertEqual(summary.resolved(.en), "Playlist “Chill Vibes”, 3 songs.")
		XCTAssertEqual(summary.resolved(.ru), "Плейлист «Чилл-плейлист», 3 песни.")
		// `name` has no `.de` translation but the builder uses each fragment's
		// own fallback chain, so the German shell wraps the English name.
		XCTAssertEqual(summary.resolved(.de), "Playlist „Chill Vibes“, 3 Lieder.")
	}

	func testPlaylistSummaryHandlesSingularInEnglish() {
		let summary = AppStrings.playlistSummary(
			name: Localized(.en, "Solo"),
			count: 1
		)
		XCTAssertEqual(summary.resolved(.en), "Playlist “Solo”, 1 song.")
	}
}
