import Foundation

public extension String {

	static func localized<T: StringProtocol>(_ word: Localized<T>) -> String {
		String(word.string)
	}

	static func localized(@Localized<String> _ word: () -> String) -> String {
		word()
	}
}
