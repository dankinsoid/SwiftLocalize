@testable import SwiftLocalize
import XCTest

final class SwiftLocalizeTests: XCTestCase {
	func testExample() {
		let tree = Localized([
			.ru: [
				[.neuter, .singular]: "дерево",
				.plural: "деревья",
			],
		])

		let beautiful = Localized([
			.ru: [
				.plural: "красивые",
				.singular: [.masculine: "красивый", .feminine: "красивая", .neuter: "красивое"],
			],
		])

		let phrase = beautiful + " " + tree

		print(phrase.string(language: .ru, .singular))
	}

	static var allTests = [
		("testExample", testExample),
	]
}
