import Foundation

public typealias Word = Localized<String>

@resultBuilder
public struct Localized<Value>: ExpressibleByDictionaryLiteral, Hashable, Codable, ExpressibleByStringInterpolation {

	private var words: [Language: Forms] = [:]

	public var localized: String {
		get { string() }
		set {
			words[.current, default: Forms(newValue)][.default] = newValue
		}
	}

	@available(*, deprecated, message: "Localized key is deprecated, use Localized.init([:]) instead")
	public init(_: String, _ variants: [Language: Forms]) {
		self = Localized(variants)
	}

	public init(_ word: some StringProtocol) {
		self = [.default: Forms(word)]
	}

	public init(_ variants: [Language: Forms]) {
		if variants.isEmpty {
			words = [.default: ""]
		} else {
			words = variants
		}
	}

	public subscript(_ language: Language) -> Forms? {
		get { words[language] }
		set { words[language] = newValue }
	}

	public init(dictionaryLiteral elements: (Language, Forms)...) {
		self = Localized(Dictionary(elements) { _, s in s })
	}

	public init(stringInterpolation: DefaultStringInterpolation) {
		self = Localized(String(stringInterpolation: stringInterpolation))
	}

	public init(stringLiteral value: String.StringLiteralType) {
		self = Localized(value)
	}

	public func string(language: Language = .current, _ form: FormType = .default) -> String {
		if form == .none, let forms = words[language] ?? words[.default] ?? words[.en] ?? words.first?.value {
			return forms.word ?? ""
		}
		return (words[language] ?? words[.default] ?? words[.en] ?? words.first?.value)?[form] ?? ""
	}

	public static func + (_ lhs: Localized, _ rhs: Localized) -> Localized {
		Localized(Swift.Dictionary(Array(lhs.words) + Array(rhs.words), uniquingKeysWith: +))
	}

	public static func += (_ lhs: inout Localized, _ rhs: Localized) {
		lhs = lhs + rhs
	}

	public static func += (_ lhs: inout Localized, _ rhs: some StringProtocol) {
		lhs = lhs + rhs
	}

	public static func + (_ lhs: Localized, _ rhs: some StringProtocol) -> Localized {
		Localized(lhs.words.mapValues { $0 + rhs })
	}

	public static func + (_ lhs: some StringProtocol, _ rhs: Localized) -> Localized {
		Localized(rhs.words.mapValues { lhs + $0 })
	}

	public static func == (lhs: Localized, rhs: Localized) -> Bool {
		lhs.words == rhs.words
	}
}
