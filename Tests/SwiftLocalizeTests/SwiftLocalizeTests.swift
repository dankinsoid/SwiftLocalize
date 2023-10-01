@testable import SwiftLocalize
import XCTest

final class SwiftLocalizeTests: XCTestCase {
	
    func test_GrammaticalSet_contains() {
        let set1: GrammaticalSet = [.singular, .neuter]
        let set2: GrammaticalSet = [.plural, .neuter]
        let set3: GrammaticalSet = [.singular, .masculine]
        let set4: GrammaticalSet = [.singular, .feminine]
        let set5: GrammaticalSet = [.singular, .neuter]
        
        XCTAssertTrue(set1.contains(.neuter))
        XCTAssertTrue(set2.contains(.neuter))
        XCTAssertFalse(set3.contains(.neuter))
        XCTAssertFalse(set4.contains(.neuter))
        XCTAssertTrue(set5.contains(.neuter))
    }
	
    func testExample() {
		let tree = Localized<String>([
			.ru: [.neuter: [
                .singular: "дерево",
                .plural: "деревья"
            ]]
		])

		let beautiful = Localized<String>([
			.ru: [
				.plural: "красивые",
				.singular: [
                    .masculine: "красивый",
                    .feminine: "красивая",
                    .neuter: "красивое"
                ],
			]
		])

		let phrase = beautiful + " " + tree

        print(phrase.forms)
        XCTAssertEqual(phrase.string(language: .ru, .singular), "красивое дерево")
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
