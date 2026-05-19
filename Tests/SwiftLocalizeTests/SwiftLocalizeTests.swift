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

	func testConcatFallbackForMissingLanguage() {
		// lhs has many languages; rhs has only .en. For .ru the result must
		// fall back to rhs's English instead of dropping rhs entirely.
		let lhs: Localized = [
			.en: "Transferred from ",
			.ru: "Перенесено из ",
			.de: "Übertragen aus ",
		]
		let rhs: Localized = [.en: "Apple Music"]

		let combined = lhs + rhs

		XCTAssertEqual(combined.string(language: .en), "Transferred from Apple Music")
		XCTAssertEqual(combined.string(language: .ru), "Перенесено из Apple Music")
		XCTAssertEqual(combined.string(language: .de), "Übertragen aus Apple Music")
	}

	func testConcatFallbackWhenRhsHasNonEnglishOnly() {
		// rhs has only .zh (e.g. QQ Music). lhs's English/Russian translations
		// should still get the service name appended via rhs's fallback.
		let lhs: Localized = [
			.en: "Transferred from ",
			.ru: "Перенесено из ",
		]
		let rhs: Localized = [.zh: "QQ音乐"]

		let combined = lhs + rhs

		XCTAssertEqual(combined.string(language: .en), "Transferred from QQ音乐")
		XCTAssertEqual(combined.string(language: .ru), "Перенесено из QQ音乐")
		XCTAssertEqual(combined.string(language: .zh), "Transferred from QQ音乐")
	}

	func testConcatBuilderPreservesAllLanguages() {
		// Mirrors the real-world `playlistDescription(from:)` shape: builder
		// concatenation of a multi-language prefix and a single-language name.
		@LocalizedBuilder
		func description(name: Localized) -> Localized {
			[.en: "from ",
			 .ru: "из ",
			 .fr: "de "]
			name
		}

		let result = description(name: [.en: "Spotify"])

		XCTAssertEqual(result.string(language: .en), "from Spotify")
		XCTAssertEqual(result.string(language: .ru), "из Spotify")
		XCTAssertEqual(result.string(language: .fr), "de Spotify")
	}

	static var allTests = [
		("testExample", testExample),
		("testConcatFallbackForMissingLanguage", testConcatFallbackForMissingLanguage),
		("testConcatFallbackWhenRhsHasNonEnglishOnly", testConcatFallbackWhenRhsHasNonEnglishOnly),
		("testConcatBuilderPreservesAllLanguages", testConcatBuilderPreservesAllLanguages),
	]
}
