// @ai-generated(solo)
import Foundation

// MARK: - Identifier

public extension Fluent {

	/// Identifier for messages, terms, attributes, variables, and functions.
	/// Term identifiers in FTL source carry a leading `-`; we strip it and use `isTerm` instead at lookup time.
	struct Identifier: Hashable, Codable, Sendable, ExpressibleByStringLiteral, LosslessStringConvertible, RawRepresentable {

		public let rawValue: String

		public init(rawValue: String) { self.rawValue = rawValue }
		public init(_ name: String) { rawValue = name }
		public init(stringLiteral value: String) { rawValue = value }
		public var description: String { rawValue }
		public init(from decoder: Decoder) throws {
			try self.init(String(from: decoder))
		}
		public func encode(to encoder: Encoder) throws {
			try rawValue.encode(to: encoder)
		}
	}
}

@available(macOS 12.3, iOS 15.4, tvOS 15.4, watchOS 8.5, *)
extension Fluent.Identifier: CodingKeyRepresentable {

	public var codingKey: CodingKey { rawValue.codingKey }

	public init<T: CodingKey>(codingKey: T) {
		self.init(codingKey.stringValue)
	}
}

// MARK: - Pattern

public extension Fluent {

	/// A pattern is a sequence of literal text and placeables. Equivalent to Fluent's `Pattern`.
	struct Pattern: Hashable, Sendable {

		public var elements: [Element]
		public init(_ elements: [Element]) { self.elements = elements }

		public enum Element: Hashable, Sendable {
			case text(String)
			case placeable(Expression)
		}
	}
}

public extension Fluent.Pattern {

	/// Convenience: pattern containing one literal string with no placeables.
	static func text(_ s: String) -> Self { Self([.text(s)]) }
}

// MARK: - Expression

public extension Fluent {

	/// All expression kinds Fluent supports inside placeables.
	indirect enum Expression: Hashable, Sendable {
		case stringLiteral(String)
		case numberLiteral(Number)
		case variableReference(Identifier)
		case messageReference(Identifier, attribute: Identifier?)
		case termReference(Identifier, attribute: Identifier?, arguments: CallArguments?)
		case functionReference(Identifier, arguments: CallArguments)
		case select(SelectExpression)
	}

	/// Positional + named arguments passed to function or term references.
	struct CallArguments: Hashable, Sendable {

		public var positional: [Expression]
		public var named: [Identifier: Expression]

		public init(positional: [Expression] = [], named: [Identifier: Expression] = [:]) {
			self.positional = positional
			self.named = named
		}
	}

	/// `selector -> [key1] pattern1, [key2] pattern2, *[default] pattern_d`.
	struct SelectExpression: Hashable, Sendable {

		public var selector: Expression
		public var variants: [Variant]

		/// Index of the default variant in `variants`. Spec requires exactly one default.
		public var defaultIndex: Int

		public init(selector: Expression, variants: [Variant], defaultIndex: Int) {
			self.selector = selector
			self.variants = variants
			self.defaultIndex = defaultIndex
		}

		public var defaultVariant: Variant { variants[defaultIndex] }
	}

	struct Variant: Hashable, Sendable {
		public var key: VariantKey
		public var value: Pattern
		public init(key: VariantKey, value: Pattern) {
			self.key = key
			self.value = value
		}
	}

	enum VariantKey: Hashable, Sendable {
		case identifier(Identifier)
		case number(Number)
	}
}

// MARK: - Message / Term / Resource

public extension Fluent {

	/// Top-level localizable entry. `value` may be nil if the message exists only for its attributes.
	struct Message: Hashable, Sendable {

		public let id: Identifier
		public var value: Pattern?
		public var attributes: [Attribute]
		public var comment: String?

		public init(
			id: Identifier,
			value: Pattern? = nil,
			attributes: [Attribute] = [],
			comment: String? = nil
		) {
			self.id = id
			self.value = value
			self.attributes = attributes
			self.comment = comment
		}
	}

	/// Private/internal building block referenced from other messages via `-term-name`.
	struct Term: Hashable, Sendable {

		public let id: Identifier
		public var value: Pattern
		public var attributes: [Attribute]
		public var comment: String?

		public init(
			id: Identifier,
			value: Pattern,
			attributes: [Attribute] = [],
			comment: String? = nil
		) {
			self.id = id
			self.value = value
			self.attributes = attributes
			self.comment = comment
		}
	}

	struct Attribute: Hashable, Sendable {

		public let id: Identifier
		public var value: Pattern

		public init(id: Identifier, value: Pattern) {
			self.id = id
			self.value = value
		}
	}

	/// A parsed FTL file = a collection of entries.
	struct Resource: Hashable, Sendable {

		public var entries: [Entry]
		public init(_ entries: [Entry] = []) { self.entries = entries }
	}

	enum Entry: Hashable, Sendable {
		case message(Message)
		case term(Term)
		case comment(String)
	}
}
