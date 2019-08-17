import XCTest
@testable import SwiftLocalize

final class SwiftLocalizeTests: XCTestCase {
    
    func testExample() {
        
        let tree = Localize.Word("tree", [
            .ru: [
                [.neuter, .singular]: "дерево",
                .plural: "деревья"
            ]
        ])
        
        let beautiful = Localize.Word("beautiful", [
            .ru: [
                .plural: "красивые",
                .singular: [.masculine: "красивый", .feminine: "красивая", .neuter: "красивое"]
            ]
        ])
        
        let phrase = beautiful + " " + tree
        
        print(phrase.string(language: .ru, .singular))
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
