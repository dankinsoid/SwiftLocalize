import XCTest
@testable import SwiftLocalize

final class SwiftLocalizeTests: XCTestCase {
    
    func testExample() {
        let tree = Localize.Word("tree", [.ru: [[.neuter, .singular]: "дерево", .plural: "деревья"]])
        let be = Localize.Word("beatiful", [
            .ru: [
                .plural: "красивые",
                .singular: [.masculine: "красивый", .feminine: "красивая", .common: "красивое"]
            ]
        ])
        let two = be + " " + tree
        print(two.string(language: .ru, .plural))
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
