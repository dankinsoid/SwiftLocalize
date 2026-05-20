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
	// Pain point: there is no `Localized`-level plural primitive, so the caller
	// must dispatch per language. The `plural(_:in:_:)` helper below collapses
	// that to a single line per language, but the developer still has to:
	//   1. know which CLDR categories the language uses,
	//   2. construct all forms eagerly (no laziness), and
	//   3. repeat the number interpolation inside every form.
	// In practice (2) and (3) are not real costs — formatting is cheap and the
	// repetition is mechanical — but (1) is the actual translator burden.
	static func songsCount(_ n: Int) -> Localized<String> {
		Localized(
			.en, plural(n, in: .en, [
				.one:   "\(n) song",
				.other: "\(n) songs",
			]),
			[
				.ru: plural(n, in: .ru, [
					.one:   "\(n) песня",
					.few:   "\(n) песни",
					.many:  "\(n) песен",
					.other: "\(n) песни",
				]),
				.de: plural(n, in: .de, [
					.one:   "\(n) Lied",
					.other: "\(n) Lieder",
				]),
				.fr: plural(n, in: .fr, [
					.one:   "\(n) chanson",
					.other: "\(n) chansons",
				]),
			]
		)
	}

	static func minutesAgo(_ n: Int) -> Localized<String> {
		Localized(
			.en, plural(n, in: .en, [
				.one:   "1 minute ago",
				.other: "\(n) minutes ago",
			]),
			[
				.ru: plural(n, in: .ru, [
					.one:   "\(n) минуту назад",
					.few:   "\(n) минуты назад",
					.many:  "\(n) минут назад",
					.other: "\(n) минут назад",
				]),
			]
		)
	}

	// MARK: Plurals — ordinal
	//
	// Same shape as cardinal but routed through `PluralType.ordinal`. English
	// ordinals are the canonical example (1st / 2nd / 3rd / 4th, with the
	// teens collapsing to "th"). Russian/German/French use a single suffix.
	static func placeNumber(_ n: Int) -> Localized<String> {
		Localized(
			.en, ordinal(n, in: .en, [
				.one:   "\(n)st place",
				.two:   "\(n)nd place",
				.few:   "\(n)rd place",
				.other: "\(n)th place",
			]),
			[
				.ru: "\(n)-е место",
				.de: "\(n). Platz",
				.fr: ordinal(n, in: .fr, [
					.one:   "\(n)ᵉʳ place",
					.other: "\(n)ᵉ place",
				]),
			]
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

// MARK: - Plural helpers
//
// These would live in the app, not the library — they bridge a per-language
// `[PluralCategory: String]` table to a single resolved string. Falling back
// to `.other` matches CLDR semantics (every language defines `.other`).

private extension AppStrings {

	static func plural(_ n: Int, in language: Language, _ forms: [PluralCategory: String]) -> String {
		let category = PluralCategory.of(Double(n), locale: language, type: .cardinal)
		return forms[category] ?? forms[.other] ?? ""
	}

	static func ordinal(_ n: Int, in language: Language, _ forms: [PluralCategory: String]) -> String {
		let category = PluralCategory.of(Double(n), locale: language, type: .ordinal)
		return forms[category] ?? forms[.other] ?? ""
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
