import Foundation

@resultBuilder
public enum LocalizedBuilder<T> {

	@inlinable
	public static func buildOptional(_ component: Localized<T>?) -> Localized<T> {
		component ?? [:]
	}

	@inlinable
	public static func buildEither(first component: Localized<T>) -> Localized<T> {
		component
	}

	@inlinable
	public static func buildEither(second component: Localized<T>) -> Localized<T> {
		component
	}

	@inlinable
	public static func buildLimitedAvailability(_ component: Localized<T>) -> Localized<T> {
		component
	}

	@inlinable
	public static func buildExpression(_ expression: Localized<T>) -> Localized<T> {
		expression
	}
}

public extension Localized {
	
	init(@LocalizedBuilder<T> _ builder: () -> Localized<T>) {
		self = builder()
	}
}

extension LocalizedBuilder<String> {
	
	@inlinable
	public static func buildBlock(_ components: Localized<T>...) -> Localized<T> {
		buildArray(components)
	}

	@inlinable
	public static func buildArray(_ components: [Localized<T>]) -> Localized<T> {
		guard !components.isEmpty else { return "" }
		return components.dropFirst().reduce(into: components[0], +=)
	}
	
	@inlinable
	public static func buildExpression(_ expression: some StringProtocol) -> Localized<T> {
		Localized(String(expression))
	}
}
