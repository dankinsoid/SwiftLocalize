// @ai-generated(solo)
@testable import SwiftLocalize
import XCTest

/// Bidi isolation around placeables — `useIsolating` wraps each resolved
/// placeable in FSI (U+2068) / PDI (U+2069) so the Unicode Bidi Algorithm
/// can't reorder placeable content with the surrounding text.
final class FluentBidiTests: XCTestCase {

	private static let fsi = "\u{2068}"
	private static let pdi = "\u{2069}"

	private func helloBundle(useIsolating: Bool) -> Fluent.Bundle {
		var bundle = Fluent.Bundle(locale: .en, useIsolating: useIsolating)
		// FTL: hello = Hello, {$name}!
		bundle.add(Fluent.Message(
			id: "hello",
			value: Fluent.Pattern([
				.text("Hello, "),
				.placeable(.variableReference("name")),
				.text("!"),
			])
		))
		return bundle
	}

	func testIsolatingOnByDefault() {
		// New bundle without an explicit flag must match Fluent.js / fluent-rs (`true`).
		let bundle = Fluent.Bundle(locale: .en)
		XCTAssertTrue(bundle.useIsolating)
	}

	func testWrapsPlaceableInFsiPdi() {
		let bundle = helloBundle(useIsolating: true)
		XCTAssertEqual(
			bundle.format("hello", args: ["name": "Danil"]),
			"Hello, \(Self.fsi)Danil\(Self.pdi)!"
		)
	}

	func testWrapsRtlInLtrContext() {
		// The whole reason FSI/PDI exists: drop an Arabic name into an English
		// sentence without the Bidi Algorithm pulling the trailing "!" to the wrong side.
		let bundle = helloBundle(useIsolating: true)
		XCTAssertEqual(
			bundle.format("hello", args: ["name": "محمد"]),
			"Hello, \(Self.fsi)محمد\(Self.pdi)!"
		)
	}

	func testDisabledLeavesPlaceableBare() {
		let bundle = helloBundle(useIsolating: false)
		XCTAssertEqual(
			bundle.format("hello", args: ["name": "Danil"]),
			"Hello, Danil!"
		)
	}

	func testNestedPlaceablesGetNestedIsolates() {
		// {-brand}'s value contains another placeable {$owner}. Both layers wrap,
		// matching fluent.js / fluent-rs behavior — each placeable is its own scope.
		var bundle = Fluent.Bundle(locale: .en, useIsolating: true)
		bundle.add(Fluent.Term(
			id: "brand",
			value: Fluent.Pattern([
				.placeable(.variableReference("owner")),
				.text("'s App"),
			])
		))
		bundle.add(Fluent.Message(
			id: "welcome",
			value: Fluent.Pattern([
				.text("Welcome to "),
				.placeable(.termReference("brand", attribute: nil, arguments: Fluent.CallArguments(named: ["owner": .stringLiteral("Anna")]))),
				.text("."),
			])
		))
		let f = Self.fsi
		let p = Self.pdi
		XCTAssertEqual(
			bundle.format("welcome"),
			"Welcome to \(f)\(f)Anna\(p)'s App\(p)."
		)
	}

	func testEmptyPlaceableIsNotWrapped() {
		// An unresolved/empty value shouldn't introduce a phantom FSI/PDI pair —
		// matches fluent-rs which short-circuits when the formatted value is empty.
		var bundle = Fluent.Bundle(locale: .en, useIsolating: true)
		bundle.add(Fluent.Term(id: "empty", value: Fluent.Pattern([.text("")])))
		bundle.add(Fluent.Message(
			id: "msg",
			value: Fluent.Pattern([
				.text("A"),
				.placeable(.termReference("empty", attribute: nil, arguments: nil)),
				.text("B"),
			])
		))
		XCTAssertEqual(bundle.format("msg"), "AB")
	}
}
