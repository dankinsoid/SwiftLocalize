import Foundation

public extension Localized {

	@inlinable
	static func buildBlock(_ components: Localized...) -> Localized where Value: RangeReplaceableCollection {
		buildArray(components)
	}

	@inlinable
	static func buildOptional(_ component: Localized?) -> Localized where Value: RangeReplaceableCollection {
		component ?? Localized(nil, Value.init())
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
	static func buildArray(_ components: [Localized]) -> Localized where Value: RangeReplaceableCollection {
		Localized.joined(components)
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
	static func buildExpression(_ expression: Value) -> Localized {
		Localized(nil, expression)
	}

	@inlinable
	static func buildFinalResult(_ component: Localized) -> Value {
		component.resolved()
	}

	@inlinable
	static func buildFinalResult(_ component: Localized) -> Localized {
		component
	}
}
