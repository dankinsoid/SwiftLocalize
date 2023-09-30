@testable import SwiftLocalize
import XCTest

final class SwiftLocalizeTests: XCTestCase {
	
	func testExample() {
		let tree = Localized<String>([
			.ru: [
				[.neuter, .singular]: "дерево",
				.plural: "деревья",
			],
		])

		let beautiful = Localized<String>([
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

extension String {
	
	@Localized<String> static var ok: String {
		[.en: "Ok",
		 .ru: "Ок"]
	}
}
