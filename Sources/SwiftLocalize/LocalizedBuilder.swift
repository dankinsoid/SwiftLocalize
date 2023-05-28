import Foundation

public extension Localized {

	@inlinable
	static func buildBlock(_ components: Localized...) -> Localized {
		buildArray(components)
	}

	@inlinable
	static func buildOptional(_ component: Localized?) -> Localized {
		component ?? ""
	}

	@inlinable
	static func buildEither(first component: Localized) -> Localized {
		component
	}

	@inlinable
	static func buildEither(second component: Localized) -> Localized {
		component
	}

	@inlinable
	static func buildArray(_ components: [Localized]) -> Localized {
		guard !components.isEmpty else { return "" }
		return components.dropFirst().reduce(into: components[0], +=)
	}

	@inlinable
	static func buildLimitedAvailability(_ component: Localized) -> Localized {
		component
	}

	@inlinable
	static func buildExpression(_ expression: Localized) -> Localized {
		expression
	}

	@inlinable
	static func buildExpression(_ expression: some StringProtocol) -> Localized {
		Localized(expression)
	}

	@inlinable
	static func buildFinalResult(_ component: Localized) -> String {
		component.localized
	}
}
