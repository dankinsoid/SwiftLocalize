// @ai-generated(solo)
@testable import SwiftLocalize
import XCTest

/// Sanity tests for the new Fluent-compatible sketch. Each test reflects an
/// FTL example from the Fluent docs so it's clear what the API is meant to mirror.
final class FluentSketchTests: XCTestCase {

	// MARK: Helpers

	private func coinsBundle(locale: Fluent.Tag) -> Fluent.Bundle {
		var bundle = Fluent.Bundle(locale: locale, useIsolating: false)

		// FTL equivalent:
		// coins = { $count ->
		//     [one] монета
		//     [few] монеты
		//    *[other] монет
		// }
		let coinsRu = Fluent.Message(
			id: "coins",
			value: Fluent.Pattern([
				.placeable(.select(Fluent.SelectExpression(
					selector: .variableReference("count"),
					variants: [
						Fluent.Variant(key: .identifier("one"), value: .text("монета")),
						Fluent.Variant(key: .identifier("few"), value: .text("монеты")),
						Fluent.Variant(key: .identifier("other"), value: .text("монет")),
					],
					defaultIndex: 2
				))),
			])
		)

		let coinsEn = Fluent.Message(
			id: "coins",
			value: Fluent.Pattern([
				.placeable(.select(Fluent.SelectExpression(
					selector: .variableReference("count"),
					variants: [
						Fluent.Variant(key: .identifier("one"), value: .text("coin")),
						Fluent.Variant(key: .identifier("other"), value: .text("coins")),
					],
					defaultIndex: 1
				))),
			])
		)

		bundle.add(locale == .ru ? coinsRu : coinsEn)
		return bundle
	}

	// MARK: Tests

	func testPluralRussian() {
		let bundle = coinsBundle(locale: .ru)
		XCTAssertEqual(bundle.format("coins", args: ["count": 1]), "монета")
		XCTAssertEqual(bundle.format("coins", args: ["count": 2]), "монеты")
		XCTAssertEqual(bundle.format("coins", args: ["count": 5]), "монет")
		XCTAssertEqual(bundle.format("coins", args: ["count": 11]), "монет")
		XCTAssertEqual(bundle.format("coins", args: ["count": 21]), "монета")
		XCTAssertEqual(bundle.format("coins", args: ["count": 22]), "монеты")
	}

	func testPluralEnglish() {
		let bundle = coinsBundle(locale: .en)
		XCTAssertEqual(bundle.format("coins", args: ["count": 1]), "coin")
		XCTAssertEqual(bundle.format("coins", args: ["count": 0]), "coins")
		XCTAssertEqual(bundle.format("coins", args: ["count": 42]), "coins")
	}

	func testPluralArabicCategories() {
		// Arabic spec: 0→zero, 1→one, 2→two, 3-10→few, 11-99→many, else→other.
		XCTAssertEqual(PluralCategory.of(0, locale: .ar), .zero)
		XCTAssertEqual(PluralCategory.of(1, locale: .ar), .one)
		XCTAssertEqual(PluralCategory.of(2, locale: .ar), .two)
		XCTAssertEqual(PluralCategory.of(5, locale: .ar), .few)
		XCTAssertEqual(PluralCategory.of(50, locale: .ar), .many)
		XCTAssertEqual(PluralCategory.of(100, locale: .ar), .other)
	}

	func testWelshHasAllSixCategories() {
		// Welsh actually uses all six categories.
		XCTAssertEqual(PluralCategory.of(0, locale: .cy), .zero)
		XCTAssertEqual(PluralCategory.of(1, locale: .cy), .one)
		XCTAssertEqual(PluralCategory.of(2, locale: .cy), .two)
		XCTAssertEqual(PluralCategory.of(3, locale: .cy), .few)
		XCTAssertEqual(PluralCategory.of(6, locale: .cy), .many)
		XCTAssertEqual(PluralCategory.of(7, locale: .cy), .other)
	}

	func testVariablePlaceable() {
		var bundle = Fluent.Bundle(locale: .en, useIsolating: false)
		// FTL: hello = Hello, {$name}!
		bundle.add(Fluent.Message(
			id: "hello",
			value: Fluent.Pattern([
				.text("Hello, "),
				.placeable(.variableReference("name")),
				.text("!"),
			])
		))
		XCTAssertEqual(bundle.format("hello", args: ["name": "Danil"]), "Hello, Danil!")
		// Missing variable surfaces as visible placeholder, not a crash.
		XCTAssertEqual(bundle.format("hello"), "Hello, {$name}!")
	}

	func testMessageReference() {
		var bundle = Fluent.Bundle(locale: .en, useIsolating: false)
		// FTL:
		// brand-name = Foo
		// greeting = Welcome to {brand-name}!
		bundle.add(Fluent.Message(id: "brand-name", value: .text("Foo")))
		bundle.add(Fluent.Message(
			id: "greeting",
			value: Fluent.Pattern([
				.text("Welcome to "),
				.placeable(.messageReference("brand-name", attribute: nil)),
				.text("!"),
			])
		))
		XCTAssertEqual(bundle.format("greeting"), "Welcome to Foo!")
	}

	func testTermWithLocalArgs() {
		var bundle = Fluent.Bundle(locale: .en, useIsolating: false)
		// FTL:
		// -brand = { $case ->
		//     [accusative] FooCorp
		//    *[nominative] FooCorp Inc.
		// }
		// about = About {-brand(case: "accusative")}.
		bundle.add(Fluent.Term(
			id: "brand",
			value: Fluent.Pattern([
				.placeable(.select(Fluent.SelectExpression(
					selector: .variableReference("case"),
					variants: [
						Fluent.Variant(key: .identifier("accusative"), value: .text("FooCorp")),
						Fluent.Variant(key: .identifier("nominative"), value: .text("FooCorp Inc.")),
					],
					defaultIndex: 1
				))),
			])
		))
		bundle.add(Fluent.Message(
			id: "about",
			value: Fluent.Pattern([
				.text("About "),
				.placeable(.termReference(
					"brand",
					attribute: nil,
					arguments: Fluent.CallArguments(named: ["case": .stringLiteral("accusative")])
				)),
				.text("."),
			])
		))
		XCTAssertEqual(bundle.format("about"), "About FooCorp.")
	}

	func testNumberFunctionCurrency() {
		var bundle = Fluent.Bundle(locale: .en, useIsolating: false)
		// FTL: price = Total: {NUMBER($amount, style: "currency", currency: "USD")}
		bundle.add(Fluent.Message(
			id: "price",
			value: Fluent.Pattern([
				.text("Total: "),
				.placeable(.functionReference(
					"NUMBER",
					arguments: Fluent.CallArguments(
						positional: [.variableReference("amount")],
						named: [
							"style": .stringLiteral("currency"),
							"currency": .stringLiteral("USD"),
						]
					)
				)),
			])
		))
		// We don't assert the exact glyph (locale-dependent symbol) — just that USD is in there.
		let out = bundle.format("price", args: ["amount": 9.99])
		XCTAssertTrue(out.contains("9.99") || out.contains("9,99"), "got: \(out)")
		XCTAssertTrue(out.contains("$") || out.contains("USD"), "got: \(out)")
	}

	// MARK: Generic Localized<Value>

	func testGenericLocalizedString() {
		let flag: Fluent.Localized<String> = [
			.en: "🇬🇧",
			.ru: "🇷🇺",
		]
		XCTAssertEqual(flag(language: .ru), "🇷🇺")
		XCTAssertEqual(flag(language: .en), "🇬🇧")
		// Unknown language falls back to first available.
		XCTAssertNotNil(flag(language: .ja))
	}

	func testGenericLocalizedNonString() {
		// Demonstrates Localized<T> with an arbitrary value type.
		struct Asset: Hashable, Sendable { let path: String }
		let icon: Fluent.Localized<Asset> = [
			.en: Asset(path: "icon_en.png"),
			.ru: Asset(path: "icon_ru.png"),
		]
		XCTAssertEqual(icon(language: .ru)?.path, "icon_ru.png")
	}

	func testLocalizedBundleRouting() {
		var bundle = Fluent.LocalizedBundle()
		bundle.add(bundle: coinsBundle(locale: .en))
		bundle.add(bundle: coinsBundle(locale: .ru))

		XCTAssertEqual(bundle.format("coins", args: ["count": 5], language: .ru), "монет")
		XCTAssertEqual(bundle.format("coins", args: ["count": 1], language: .en), "coin")
		// Falls back to .en when language not registered.
		XCTAssertEqual(bundle.format("coins", args: ["count": 1], language: .ja), "coin")
	}

	// MARK: Ordinals

	func testOrdinalEnglishCategories() {
		// en: 1→one(1st), 2→two(2nd), 3→few(3rd), other for the rest (including 11/12/13).
		XCTAssertEqual(PluralCategory.of(1, locale: .en, type: .ordinal), .one)
		XCTAssertEqual(PluralCategory.of(2, locale: .en, type: .ordinal), .two)
		XCTAssertEqual(PluralCategory.of(3, locale: .en, type: .ordinal), .few)
		XCTAssertEqual(PluralCategory.of(4, locale: .en, type: .ordinal), .other)
		XCTAssertEqual(PluralCategory.of(11, locale: .en, type: .ordinal), .other)
		XCTAssertEqual(PluralCategory.of(12, locale: .en, type: .ordinal), .other)
		XCTAssertEqual(PluralCategory.of(13, locale: .en, type: .ordinal), .other)
		XCTAssertEqual(PluralCategory.of(21, locale: .en, type: .ordinal), .one)
		XCTAssertEqual(PluralCategory.of(22, locale: .en, type: .ordinal), .two)
		XCTAssertEqual(PluralCategory.of(23, locale: .en, type: .ordinal), .few)
		XCTAssertEqual(PluralCategory.of(101, locale: .en, type: .ordinal), .one)
	}

	func testOrdinalCardinalAreIndependent() {
		// Sanity: cardinal "2 books" → other, but ordinal "2nd" → two.
		XCTAssertEqual(PluralCategory.of(2, locale: .en, type: .cardinal), .other)
		XCTAssertEqual(PluralCategory.of(2, locale: .en, type: .ordinal), .two)
	}

	func testOrdinalWelshCategories() {
		// Welsh ordinal: 0,7,8,9→zero; 1→one; 2→two; 3,4→few; 5,6→many; else→other.
		XCTAssertEqual(PluralCategory.of(0, locale: .cy, type: .ordinal), .zero)
		XCTAssertEqual(PluralCategory.of(1, locale: .cy, type: .ordinal), .one)
		XCTAssertEqual(PluralCategory.of(2, locale: .cy, type: .ordinal), .two)
		XCTAssertEqual(PluralCategory.of(3, locale: .cy, type: .ordinal), .few)
		XCTAssertEqual(PluralCategory.of(5, locale: .cy, type: .ordinal), .many)
		XCTAssertEqual(PluralCategory.of(7, locale: .cy, type: .ordinal), .zero)
		XCTAssertEqual(PluralCategory.of(10, locale: .cy, type: .ordinal), .other)
	}

	func testOrdinalSelectorViaNUMBER() {
		// FTL equivalent of the canonical Fluent ordinal example:
		// your-rank = { NUMBER($pos, type: "ordinal") ->
		//     [one] You finished {$pos}st
		//     [two] You finished {$pos}nd
		//     [few] You finished {$pos}rd
		//    *[other] You finished {$pos}th
		// }
		var bundle = Fluent.Bundle(locale: .en, useIsolating: false)
		bundle.add(Fluent.Message(
			id: "your-rank",
			value: Fluent.Pattern([
				.placeable(.select(Fluent.SelectExpression(
					selector: .functionReference(
						"NUMBER",
						arguments: Fluent.CallArguments(
							positional: [.variableReference("pos")],
							named: ["type": .stringLiteral("ordinal")]
						)
					),
					variants: [
						Fluent.Variant(key: .identifier("one"), value: Fluent.Pattern([
							.text("You finished "), .placeable(.variableReference("pos")), .text("st"),
						])),
						Fluent.Variant(key: .identifier("two"), value: Fluent.Pattern([
							.text("You finished "), .placeable(.variableReference("pos")), .text("nd"),
						])),
						Fluent.Variant(key: .identifier("few"), value: Fluent.Pattern([
							.text("You finished "), .placeable(.variableReference("pos")), .text("rd"),
						])),
						Fluent.Variant(key: .identifier("other"), value: Fluent.Pattern([
							.text("You finished "), .placeable(.variableReference("pos")), .text("th"),
						])),
					],
					defaultIndex: 3
				))),
			])
		))
		XCTAssertEqual(bundle.format("your-rank", args: ["pos": 1]), "You finished 1st")
		XCTAssertEqual(bundle.format("your-rank", args: ["pos": 2]), "You finished 2nd")
		XCTAssertEqual(bundle.format("your-rank", args: ["pos": 3]), "You finished 3rd")
		XCTAssertEqual(bundle.format("your-rank", args: ["pos": 4]), "You finished 4th")
		XCTAssertEqual(bundle.format("your-rank", args: ["pos": 11]), "You finished 11th")
		XCTAssertEqual(bundle.format("your-rank", args: ["pos": 21]), "You finished 21st")
		XCTAssertEqual(bundle.format("your-rank", args: ["pos": 22]), "You finished 22nd")
	}

	func testOrdinalDoesNotAffectCardinalSelectors() {
		// A plain $count selector (cardinal) must keep cardinal behaviour even when the test
		// passes an integer that would shift category under ordinal rules.
		let bundle = coinsBundle(locale: .en)
		// 2 → cardinal "other" → "coins". (Under ordinal rules en would say "two".)
		XCTAssertEqual(bundle.format("coins", args: ["count": 2]), "coins")
	}

	func testLanguageTagNormalization() {
		XCTAssertEqual(Fluent.Tag("EN-us").rawValue, "en-US")
		XCTAssertEqual(Fluent.Tag("en-US").languageOnly, .en)
		XCTAssertEqual(Fluent.Tag("zh-Hans-CN").language, "zh")
	}
}
