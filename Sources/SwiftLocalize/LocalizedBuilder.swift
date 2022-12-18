import Foundation

@resultBuilder
public enum LocalizedBuilder {
    @inlinable
    public static func buildBlock(_ components: Word...) -> Word {
        buildArray(components)
    }

    @inlinable
    public static func buildOptional(_ component: Word?) -> Word {
        component ?? ""
    }

    @inlinable
    public static func buildEither(first component: Word) -> Word {
        component
    }

    @inlinable
    public static func buildEither(second component: Word) -> Word {
        component
    }

    @inlinable
    public static func buildArray(_ components: [Word]) -> Word {
        components.reduce(into: "", +=)
    }

    @inlinable
    public static func buildLimitedAvailability(_ component: Word) -> Word {
        component
    }

    @inlinable
    public static func buildExpression(_ expression: Word) -> Word {
        expression
    }

    @inlinable
    public static func buildExpression(_ expression: Any) -> Word {
        "\(expression)"
    }

    @inlinable
    public static func buildExpression(_ expression: some StringProtocol) -> Word {
        Word(expression)
    }

    @inlinable
    public static func buildFinalResult(_ component: Word) -> String {
        component.localized
    }
}
