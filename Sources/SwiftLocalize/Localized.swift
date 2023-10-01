import Foundation

@resultBuilder
public struct Localized<T>: ExpressibleByDictionaryLiteral {

	public private(set) var forms: [Language: Forms] = [:]

	public var localized: T? {
		get { localized() }
		set {
			guard let newValue else {
				forms[.current] = nil
				return
			}
			forms[.current, default: Forms(newValue)][.any] = newValue
		}
	}

	public init(_ form: T) {
		self = [.default: Forms(form)]
	}

	public init(_ variants: [Language: Forms]) {
		forms = variants
	}

	public subscript(_ language: Language) -> Forms? {
		get { forms[language] }
		set { forms[language] = newValue }
	}

	public init(dictionaryLiteral elements: (Language, Forms)...) {
		self = Localized(Dictionary(elements) { _, s in s })
	}

	public func localized(language: Language = .current, _ grammaticalSet: GrammaticalSet = .any) -> T? {
		if grammaticalSet == .any, let forms = forms[language] ?? forms[.default] ?? forms[.en] ?? forms.first?.value {
			return forms.word
		}
		return (forms[language] ?? forms[.default] ?? forms[.en] ?? forms.first?.value)?[grammaticalSet]
	}
}

extension Localized: Equatable where T: Equatable {

	public static func == (lhs: Localized, rhs: Localized) -> Bool {
		lhs.forms == rhs.forms
	}
}

extension Localized: Hashable where T: Hashable {}
