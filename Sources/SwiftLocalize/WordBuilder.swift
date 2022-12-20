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
