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
    
    func testCases() {
        let target: Localized = [.en: "VK", .ru: "ВКонтакте"]
        let text = youTransferIsReadyText(count: 235, target: target)
        print(
            text.string(language: .en),
            text.string(language: .ru),
            text.string(language: .en, .cases(NumberCase(for: 235))),
            text.string(language: .ru, .cases(NumberCase(for: 235))),
            separator: "\n"
        )
    }

    @LocalizedBuilder
    func youTransferIsReadyText(count: Int, target: Localized) -> Localized {
        [.en: "The search for your tracks is complete. We found \(count) ",
         .ru: "Поиск ваших треков завершен. Мы нашли \(count) "]
        [.en: [.cases(NumberCase.singular): "track", .cases(NumberCase.accusative): "tracks", .default: "tracks"],
         .ru: [.cases(NumberCase.singular): "трек", .cases(NumberCase.accusative): "трека", .default: "треков"]]
        [.en: "! You can now add them to ",
         .ru: "! Теперь вы можете добавить их в "]
        target
        "."
    }

	static var allTests = [
		("testExample", testExample),
	]
}
