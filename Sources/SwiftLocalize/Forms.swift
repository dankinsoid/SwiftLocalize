import Foundation

public enum CountForm {
	
	case plural, singular
}

public enum Gender {
	
	case masculine, feminine, neuter, common
}

public struct FormType: OptionSet, Hashable, ExpressibleByIntegerLiteral, Codable {
	
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
	
	public mutating func formUnion(_ other: __owned FormType) {
		rawValue = rawValue | other.rawValue
	}
	
	public mutating func formIntersection(_ other: FormType) {
		rawValue = rawValue & other.rawValue
	}
	
	public mutating func formSymmetricDifference(_ other: __owned FormType) {
		rawValue = rawValue ^ other.rawValue
	}
}

public extension Localized {
	
	struct Forms: ExpressibleByDictionaryLiteral {

		fileprivate var forms: [FormType: T]

		public var word: T? {
			get { forms[.default] ?? forms.first?.value }
			set { forms[.default] = newValue }
		}

		public subscript(_ form: FormType) -> T? {
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

		public init(_ elements: [FormType: T]) {
			forms = elements
		}

		public init(_ element: T) {
			self.init([.default: element])
		}
		
		public func exactly(_ types: FormType) -> T? {
			forms[types]
		}

		public func all(where types: FormType) -> [T] {
			forms.filter { $0.key.contains(types) }.map { $0.value }
		}

		public func all() -> [FormType: T] {
			forms
		}
	}
}

extension Localized.Forms: ExpressibleByUnicodeScalarLiteral where T: ExpressibleByUnicodeScalarLiteral {
	
	public init(unicodeScalarLiteral value: T.UnicodeScalarLiteralType) {
		self = Localized.Forms(T(unicodeScalarLiteral: value))
	}
}

extension Localized.Forms: ExpressibleByExtendedGraphemeClusterLiteral where T: ExpressibleByExtendedGraphemeClusterLiteral {
	
	public init(extendedGraphemeClusterLiteral value: T.ExtendedGraphemeClusterLiteralType) {
		self = Localized.Forms(T(extendedGraphemeClusterLiteral: value))
	}
}

extension Localized.Forms: ExpressibleByStringLiteral where T: ExpressibleByStringLiteral {
	
	public init(stringLiteral value: T.StringLiteralType) {
		self = Localized.Forms(T(stringLiteral: value))
	}
}

extension Localized.Forms: ExpressibleByStringInterpolation where T: ExpressibleByStringInterpolation {
	
	public init(stringInterpolation value: T.StringInterpolation) {
		self = Localized.Forms(T(stringInterpolation: value))
	}
}

extension Localized.Forms: Equatable where T: Equatable {
}

extension Localized.Forms: Hashable where T: Hashable {}

extension Localized.Forms: Encodable where T: Encodable {}
extension Localized.Forms: Decodable where T: Decodable {}

extension Localized<String>.Forms {
	
	public static func + (_ lhs: Localized.Forms, _ rhs: Localized.Forms) -> Localized.Forms {
		Localized.Forms(Swift.Dictionary(Array(lhs.forms) + Array(rhs.forms), uniquingKeysWith: +))
	}
	
	public static func + (_ lhs: Localized.Forms, _ rhs: some StringProtocol) -> Localized.Forms {
		Localized.Forms(lhs.forms.mapValues { $0 + rhs })
	}
	
	public static func + (_ lhs: some StringProtocol, _ rhs: Localized.Forms) -> Localized.Forms {
		Localized.Forms(rhs.forms.mapValues { lhs + $0 })
	}
}
