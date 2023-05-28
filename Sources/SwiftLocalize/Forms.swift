import Foundation

public extension Localized {

	enum CountForm {
		case plural, singular
	}

	enum Gender {
		case masculine, feminine, neuter, common
	}

	struct FormType: OptionSet, Hashable, ExpressibleByIntegerLiteral, Codable {
		public typealias IntegerLiteralType = UInt

		public var rawValue: UInt

		public static func count(_ count: CountForm) -> FormType {
			switch count {
			case .singular: return .singular
			case .plural: return .plural
			}
		}

		public static func gender(_ gender: Gender) -> FormType {
			switch gender {
			case .masculine: return .masculine
			case .feminine: return .feminine
			case .neuter: return .neuter
			case .common: return .common
			}
		}

		public static func cases<C: LanguageCaseProtocol>(_ cases: C...) -> FormType {
			FormType(rawValue: cases
				.map { (UInt($0.rawValue) << 6) | $0.forms.rawValue }
				.reduce(0, |))
		}

		public static var `default`: FormType { .none }
		public static var none: FormType { 0 }
		public static var singular: FormType { 1 }
		public static var plural: FormType { 2 }
		public static var masculine: FormType { 4 }
		public static var feminine: FormType { 8 }
		public static var neuter: FormType { 16 }
		public static var common: FormType { 32 }

		public init(rawValue: UInt) {
			self.rawValue = rawValue
		}

		public init(integerLiteral value: UInt) {
			rawValue = value
		}

		public mutating func formUnion(_ other: __owned Localized.FormType) {
			rawValue = rawValue | other.rawValue
		}

		public mutating func formIntersection(_ other: Localized.FormType) {
			rawValue = rawValue & other.rawValue
		}

		public mutating func formSymmetricDifference(_ other: __owned Localized.FormType) {
			rawValue = rawValue ^ other.rawValue
		}
	}

	struct Forms: ExpressibleByStringInterpolation, ExpressibleByDictionaryLiteral, Hashable, Codable {
		public typealias StringLiteralType = String

		fileprivate var forms: [FormType: String]

		public var word: String? {
			get { forms[.default] ?? forms.first?.value }
			set { forms[.default] = newValue }
		}

		public subscript(_ form: FormType) -> String? {
			get {
				forms[form] ??
					forms.filter { form.contains($0.key) }.values.first ??
					forms.filter { $0.key.intersection(form) != .none }.values.first
			}
			set {
				forms[form] = newValue
			}
		}

		public init(dictionaryLiteral elements: (FormType, Forms)...) {
			forms = [:]
			elements.forEach {
				let type = $0.0
				$0.1.forms.forEach {
					forms[[type, $0.0]] = $0.1
				}
			}
		}

		public init(_ elements: [FormType: String]) {
			forms = elements
		}

		public init(_ value: some StringProtocol) {
			forms = [.default: String(value)]
		}

		public init(stringLiteral value: String) {
			self = Forms(value)
		}

		public func exactly(_ types: FormType) -> String? {
			forms[types]
		}

		public func all(where types: FormType) -> [String] {
			forms.filter { $0.key.contains(types) }.map { $0.value }
		}

		public func all() -> [FormType: String] {
			forms
		}

		public static func + (_ lhs: Forms, _ rhs: Forms) -> Forms {
			Forms(Swift.Dictionary(Array(lhs.forms) + Array(rhs.forms), uniquingKeysWith: +))
		}

		public static func + (_ lhs: Forms, _ rhs: some StringProtocol) -> Forms {
			Forms(lhs.forms.mapValues { $0 + rhs })
		}

		public static func + (_ lhs: some StringProtocol, _ rhs: Forms) -> Forms {
			Forms(rhs.forms.mapValues { lhs + $0 })
		}
	}
}
