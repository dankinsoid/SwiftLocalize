import Foundation

public protocol LanguageCaseProtocol: RawRepresentable where RawValue == UInt16 {
	
	var forms: FormType { get }
}

public extension LanguageCaseProtocol {
	
	var forms: FormType { .none }
}

public enum NumberCase: UInt16, LanguageCaseProtocol {
	
	case singular, genitive, accusative

	public init(for number: Int) {
		let twenty = number % 100
		if twenty > 10, twenty < 20 {
			self = .genitive
			return
		}
		let last = number % 10
		switch last {
		case 1: self = .singular
		case 2 ... 4: self = .accusative
		default: self = .genitive
		}
	}

	public var forms: FormType {
		switch self {
		case .singular: return .singular
		case .genitive: return .plural
		case .accusative: return .plural
		}
	}
}
