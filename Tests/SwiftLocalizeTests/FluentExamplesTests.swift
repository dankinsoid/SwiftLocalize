// @ai-generated(solo)
@testable import SwiftLocalize
import XCTest

/// Side-by-side examples: each test mirrors an FTL source block shown in the
/// comment above it. Lets you eyeball the ergonomic gap between Fluent text
/// syntax and the current programmatic AST builder API.
final class FluentExamplesTests: XCTestCase {

	// MARK: Example 1 — message with an attribute
	//
	// # FTL
	// hello = Hello, {$name}!
	//     .greeting = Hi {$name}

	func testExample1_helloWithAttribute() {
		var bundle = Fluent.Bundle(locale: .en, useIsolating: false)
		bundle.add(Fluent.Message(
			id: "hello",
			value: Fluent.Pattern([
				.text("Hello, "),
				.placeable(.variableReference("name")),
				.text("!"),
			]),
			attributes: [
				Fluent.Attribute(
					id: "greeting",
					value: Fluent.Pattern([
						.text("Hi "),
						.placeable(.variableReference("name")),
					])
				),
			]
		))

		XCTAssertEqual(bundle.format("hello", args: ["name": "Danil"]), "Hello, Danil!")
		XCTAssertEqual(bundle.format("hello", attribute: "greeting", args: ["name": "Danil"]), "Hi Danil")
	}

	// MARK: Example 2 — plural selector with NUMBER() function
	//
	// # FTL
	// unread-emails = { $count ->
	//     [one] You have one unread email.
	//    *[other] You have { NUMBER($count) } unread emails.
	// }

	func testExample2_unreadEmails() {
		var bundle = Fluent.Bundle(locale: .en, useIsolating: false)
		bundle.add(Fluent.Message(
			id: "unread-emails",
			value: Fluent.Pattern([
				.placeable(.select(Fluent.SelectExpression(
					selector: .variableReference("count"),
					variants: [
						Fluent.Variant(
							key: .identifier("one"),
							value: .text("You have one unread email.")
						),
						Fluent.Variant(
							key: .identifier("other"),
							value: Fluent.Pattern([
								.text("You have "),
								.placeable(.functionReference(
									"NUMBER",
									arguments: Fluent.CallArguments(positional: [.variableReference("count")])
								)),
								.text(" unread emails."),
							])
						),
					],
					defaultIndex: 1
				))),
			])
		))

		XCTAssertEqual(bundle.format("unread-emails", args: ["count": 1]), "You have one unread email.")
		XCTAssertEqual(bundle.format("unread-emails", args: ["count": 1234]), "You have 1,234 unread emails.")
	}

	// MARK: Example 3 — gender + plural selectors, en vs ru
	//
	// English uses possessive (his/her/their) — gender on the pronoun.
	// Russian uses verb agreement (добавил/добавила) — gender on the verb,
	// and the noun "фото" is indeclinable so plural categories collapse on the
	// noun itself, but the number is what we want to surface.
	//
	// # en.ftl
	// shared-photos =
	//     {$userName} {$photoCount ->
	//         [one] added a new photo
	//        *[other] added {$photoCount} new photos
	//     } to {$userGender ->
	//         [male] his stream
	//         [female] her stream
	//        *[other] their stream
	//     }.
	//
	// # ru.ftl
	// shared-photos =
	//     {$userName} {$userGender ->
	//         [feminine] добавила
	//        *[masculine] добавил
	//     } {$photoCount ->
	//         [one] {$photoCount} новое фото
	//         [few] {$photoCount} новых фото
	//        *[other] {$photoCount} новых фото
	//     } в свой профиль.

	private func sharedPhotosEN() -> Fluent.Bundle {
		var bundle = Fluent.Bundle(locale: .en, useIsolating: false)
		bundle.add(Fluent.Message(
			id: "shared-photos",
			value: Fluent.Pattern([
				.placeable(.variableReference("userName")),
				.text(" "),
				.placeable(.select(Fluent.SelectExpression(
					selector: .variableReference("photoCount"),
					variants: [
						Fluent.Variant(key: .identifier("one"), value: .text("added a new photo")),
						Fluent.Variant(key: .identifier("other"), value: Fluent.Pattern([
							.text("added "),
							.placeable(.variableReference("photoCount")),
							.text(" new photos"),
						])),
					],
					defaultIndex: 1
				))),
				.text(" to "),
				.placeable(.select(Fluent.SelectExpression(
					selector: .variableReference("userGender"),
					variants: [
						Fluent.Variant(key: .identifier("male"), value: .text("his stream")),
						Fluent.Variant(key: .identifier("female"), value: .text("her stream")),
						Fluent.Variant(key: .identifier("other"), value: .text("their stream")),
					],
					defaultIndex: 2
				))),
				.text("."),
			])
		))
		return bundle
	}

	private func sharedPhotosRU() -> Fluent.Bundle {
		var bundle = Fluent.Bundle(locale: .ru, useIsolating: false)
		bundle.add(Fluent.Message(
			id: "shared-photos",
			value: Fluent.Pattern([
				.placeable(.variableReference("userName")),
				.text(" "),
				.placeable(.select(Fluent.SelectExpression(
					selector: .variableReference("userGender"),
					variants: [
						Fluent.Variant(key: .identifier("feminine"), value: .text("добавила")),
						Fluent.Variant(key: .identifier("masculine"), value: .text("добавил")),
					],
					defaultIndex: 1
				))),
				.text(" "),
				.placeable(.select(Fluent.SelectExpression(
					selector: .variableReference("photoCount"),
					variants: [
						Fluent.Variant(key: .identifier("one"), value: Fluent.Pattern([
							.placeable(.variableReference("photoCount")),
							.text(" новое фото"),
						])),
						Fluent.Variant(key: .identifier("few"), value: Fluent.Pattern([
							.placeable(.variableReference("photoCount")),
							.text(" новых фото"),
						])),
						Fluent.Variant(key: .identifier("other"), value: Fluent.Pattern([
							.placeable(.variableReference("photoCount")),
							.text(" новых фото"),
						])),
					],
					defaultIndex: 2
				))),
				.text(" в свой профиль."),
			])
		))
		return bundle
	}

	func testExample3_sharedPhotosEN() {
		let bundle = sharedPhotosEN()
		XCTAssertEqual(
			bundle.format("shared-photos", args: [
				"userName": "Anna",
				"photoCount": 1,
				"userGender": "female",
			]),
			"Anna added a new photo to her stream."
		)
		XCTAssertEqual(
			bundle.format("shared-photos", args: [
				"userName": "Alex",
				"photoCount": 7,
				"userGender": "other",
			]),
			"Alex added 7 new photos to their stream."
		)
	}

	func testExample3_sharedPhotosRU() {
		let bundle = sharedPhotosRU()
		XCTAssertEqual(
			bundle.format("shared-photos", args: [
				"userName": "Анна",
				"photoCount": 1,
				"userGender": "feminine",
			]),
			"Анна добавила 1 новое фото в свой профиль."
		)
		XCTAssertEqual(
			bundle.format("shared-photos", args: [
				"userName": "Иван",
				"photoCount": 7,
				"userGender": "masculine",
			]),
			"Иван добавил 7 новых фото в свой профиль."
		)
	}
}
