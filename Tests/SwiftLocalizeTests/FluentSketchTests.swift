// @ai-generated(solo)
@testable import SwiftLocalize
import XCTest

/// Sanity tests for the new Fluent-compatible sketch. Each test reflects an
/// FTL example from the Fluent docs so it's clear what the API is meant to mirror.
final class FluentSketchTests: XCTestCase {

	// MARK: Helpers

	private func coinsBundle(locale: Fluent.Tag) -> Fluent.Bundle {
		let bundle = Fluent.Bundle(locale: locale)

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
		XCTAssertEqual(Fluent.PluralCategory.of(0, locale: .ar), .zero)
		XCTAssertEqual(Fluent.PluralCategory.of(1, locale: .ar), .one)
		XCTAssertEqual(Fluent.PluralCategory.of(2, locale: .ar), .two)
		XCTAssertEqual(Fluent.PluralCategory.of(5, locale: .ar), .few)
		XCTAssertEqual(Fluent.PluralCategory.of(50, locale: .ar), .many)
		XCTAssertEqual(Fluent.PluralCategory.of(100, locale: .ar), .other)
	}

	func testWelshHasAllSixCategories() {
		// Welsh actually uses all six categories.
		XCTAssertEqual(Fluent.PluralCategory.of(0, locale: .cy), .zero)
		XCTAssertEqual(Fluent.PluralCategory.of(1, locale: .cy), .one)
		XCTAssertEqual(Fluent.PluralCategory.of(2, locale: .cy), .two)
		XCTAssertEqual(Fluent.PluralCategory.of(3, locale: .cy), .few)
		XCTAssertEqual(Fluent.PluralCategory.of(6, locale: .cy), .many)
		XCTAssertEqual(Fluent.PluralCategory.of(7, locale: .cy), .other)
	}

	func testVariablePlaceable() {
		let bundle = Fluent.Bundle(locale: .en)
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
		let bundle = Fluent.Bundle(locale: .en)
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
		let bundle = Fluent.Bundle(locale: .en)
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
		let bundle = Fluent.Bundle(locale: .en)
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
		let bundle = Fluent.LocalizedBundle()
		bundle.add(bundle: coinsBundle(locale: .en))
		bundle.add(bundle: coinsBundle(locale: .ru))

		XCTAssertEqual(bundle.format("coins", args: ["count": 5], language: .ru), "монет")
		XCTAssertEqual(bundle.format("coins", args: ["count": 1], language: .en), "coin")
		// Falls back to .en when language not registered.
		XCTAssertEqual(bundle.format("coins", args: ["count": 1], language: .ja), "coin")
	}

	func testLanguageTagNormalization() {
		XCTAssertEqual(Fluent.Tag("EN-us").rawValue, "en-US")
		XCTAssertEqual(Fluent.Tag("en-US").languageOnly, .en)
		XCTAssertEqual(Fluent.Tag("zh-Hans-CN").language, "zh")
	}
}
