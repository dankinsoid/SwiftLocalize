import Foundation

@resultBuilder
public enum LocalizedBuilder {

	@inlinable
	public static func buildBlock(_ components: Localized...) -> Localized {
		buildArray(components)
	}

	@inlinable
	public static func buildOptional(_ component: Localized?) -> Localized {
		component ?? ""
	}

	@inlinable
	public static func buildEither(first component: Localized) -> Localized {
		component
	}

	@inlinable
	public static func buildEither(second component: Localized) -> Localized {
		component
	}

	@inlinable
	public static func buildArray(_ components: [Localized]) -> Localized {
		guard !components.isEmpty else { return "" }
		return components.dropFirst().reduce(into: components[0], +=)
	}

	@inlinable
	public static func buildLimitedAvailability(_ component: Localized) -> Localized {
		component
	}

	@inlinable
	public static func buildExpression(_ expression: Localized) -> Localized {
		expression
	}

	@inlinable
	public static func buildExpression(_ expression: some StringProtocol) -> Localized {
		Localized(expression)
	}
}

public extension Localized {
	init(@LocalizedBuilder _ builder: () -> Localized) {
		self = builder()
	}
}


public struct Message<Value> {
	
	public typealias Pattern = @Sendable (Language) -> Value
	
	private var words: [Language: Pattern] = [:]
}

extension String {
	
	public enum TransferMusic {
		
		public enum Profile {
			
			public static let title = "Transfer Music"
			
			public static func description(count: Int) -> String {
				"\(count) songs will be transferred."
			}
		}
	}
}

public enum Pattern<Value> {
	
	case value(Value)
	case placeable(Placeable<Value>)
}

public enum Placeable<Value> {
	
	
}

