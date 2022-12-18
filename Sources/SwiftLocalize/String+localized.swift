import Foundation

public extension String {
    static func localized(_ word: Word) -> String {
        word.localized
    }

    static func localized(@LocalizedBuilder _ word: () -> String) -> String {
        word()
    }
}
