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
		components.joined()
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

#if canImport(UIKit)
import UIKit
#endif
#if canImport(AppKit)
import AppKit
#endif

extension Localized where Value == NSAttributedString {

	@inlinable
	static func buildExpression(_ expression: Localized<String>) -> Localized {
		expression.map { NSAttributedString(string: $0) }
	}

	@inlinable
	static func buildExpression(_ expression: String) -> Localized {
		Localized(nil, NSAttributedString(string: expression))
	}
	
	#if canImport(UIKit)
	@available(iOS 13.0, *)
	@inlinable
	static func buildExpression(_ expression: Localized<UIImage>) -> Localized {
		expression.map { NSAttributedString(attachment: NSTextAttachment(image: $0)) }
	}
	
	@available(iOS 13.0, *)
	@inlinable
	static func buildExpression(_ expression: UIImage) -> Localized {
		Localized(nil, NSAttributedString(attachment: NSTextAttachment(image: expression)))
	}
	#endif

	#if os(macOS)
	@inlinable
	static func buildExpression(_ expression: Localized<NSImage>) -> Localized {
		expression.map { image in
			let attachment = NSTextAttachment()
			attachment.image = image
			return NSAttributedString(attachment: attachment)
		}
	}

	@inlinable
	static func buildExpression(_ expression: NSImage) -> Localized {
		let attachment = NSTextAttachment()
		attachment.image = expression
		return Localized(nil, NSAttributedString(attachment: attachment))
	}
	#endif

	// AttributedString <-> NSAttributedString bridging inits are Darwin-only,
	// swift-corelibs-foundation on Linux doesn't provide them
	#if canImport(ObjectiveC)
	@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
	@inlinable
	static func buildExpression(_ expression: Localized<AttributedString>) -> Localized {
		expression.map { NSAttributedString($0) }
	}

	@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
	@inlinable
	static func buildExpression(_ expression: AttributedString) -> Localized {
		Localized(nil, NSAttributedString(expression))
	}
	#endif
}

@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
extension Localized where Value == AttributedString {

	@inlinable
	static func buildExpression(_ expression: Localized<String>) -> Localized {
		expression.map { AttributedString($0) }
	}

	@inlinable
	static func buildExpression(_ expression: String) -> Localized {
		Localized(nil, AttributedString(expression))
	}

	// AttributedString <-> NSAttributedString bridging inits are Darwin-only,
	// swift-corelibs-foundation on Linux doesn't provide them
	#if canImport(ObjectiveC)
	@inlinable
	static func buildExpression(_ expression: Localized<NSAttributedString>) -> Localized {
		expression.map { AttributedString($0) }
	}

	@inlinable
	static func buildExpression(_ expression: NSAttributedString) -> Localized {
		Localized(nil, AttributedString(expression))
	}
	#endif
}
