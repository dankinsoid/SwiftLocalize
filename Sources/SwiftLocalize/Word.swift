import Foundation

public struct Word: ExpressibleByDictionaryLiteral, Hashable, Codable, ExpressibleByStringInterpolation {
    private var words: [Language: Forms] = [:]

    public var localized: String {
        get { string() }
        set {
            words[.current, default: Forms(newValue)][.default] = newValue
        }
    }

    @available(*, deprecated, message: "Word key is deprecated, use Word.init([:]) instead")
    public init(_: String, _ variants: [Language: Forms]) {
        self = Word(variants)
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
        self = Word(Dictionary(elements) { _, s in s })
    }

    public init(stringInterpolation: DefaultStringInterpolation) {
        self = Word(String(stringInterpolation: stringInterpolation))
    }

    public init(stringLiteral value: String.StringLiteralType) {
        self = Word(value)
    }

    public func string(language: Language = .current, _ form: FormType = .default) -> String {
        if form == .none, let forms = words[language] ?? words[.default] ?? words[.en] ?? words.first?.value {
            return forms.word ?? ""
        }
        return (words[language] ?? words[.default] ?? words[.en] ?? words.first?.value)?[form] ?? ""
    }

    public static func + (_ lhs: Word, _ rhs: Word) -> Word {
        Word(Swift.Dictionary(Array(lhs.words) + Array(rhs.words), uniquingKeysWith: +))
    }

    public static func += (_ lhs: inout Word, _ rhs: Word) {
        lhs = lhs + rhs
    }

    public static func += (_ lhs: inout Word, _ rhs: some StringProtocol) {
        lhs = lhs + rhs
    }

    public static func + (_ lhs: Word, _ rhs: some StringProtocol) -> Word {
        Word(lhs.words.mapValues { $0 + rhs })
    }

    public static func + (_ lhs: some StringProtocol, _ rhs: Word) -> Word {
        Word(rhs.words.mapValues { lhs + $0 })
    }

    public static func == (lhs: Word, rhs: Word) -> Bool {
        lhs.words == rhs.words
    }
}
