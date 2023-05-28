import Foundation

public extension Localized {

    @inlinable
    static func buildExpression(_ expression: Localized) -> Localized {
        expression
    }

    @inlinable
    static func buildExpression(_ expression: T) -> Localized {
        Localized(expression)
    }

    @inlinable
    static func buildFinalResult(_ component: Localized) -> T {
        component.localized
    }
}

public extension Localized where T: ExpressibleByStringInterpolation, T.StringInterpolation == DefaultStringInterpolation {
    
    @inlinable
    static func buildExpression(_ expression: Any) -> Localized {
        Localized("\(expression)" as T)
    }
}

public extension Localized where T: RangeReplaceableCollection {
    
    @inlinable
    static func buildEither(first component: Localized) -> Localized {
        component
    }
    
    @inlinable
    static func buildEither(second component: Localized) -> Localized {
        component
    }
    
    @inlinable
    static func buildLimitedAvailability(_ component: Localized) -> Localized {
        component
    }
    
    @inlinable
    static func buildBlock(_ components: Localized...) -> Localized {
        buildArray(components)
    }
    
    @inlinable
    static func buildOptional(_ component: Localized?) -> Localized {
        component ?? Localized(T())
    }
    
    @inlinable
    static func buildArray(_ components: [Localized]) -> Localized {
        components.reduce(into: Localized(T()), +=)
    }
}
