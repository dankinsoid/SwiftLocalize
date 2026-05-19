// @ai-generated(solo)
import Foundation

public extension Fluent {

	/// Runtime value produced while resolving an expression. Equivalent to Fluent's
	/// `FluentType` (string, number, none). Custom values can be carried via `.custom`.
	enum Value: Hashable, Sendable {

		case string(String)
		case number(Number)
		case none
		case custom(AnyHashableSendable)

		public func formatted(locale: Fluent.Tag) -> String {
			switch self {
			case let .string(s): return s
			case let .number(n): return n.formatted(locale: locale)
			case .none: return ""
			case let .custom(box): return box.description
			}
		}
	}

	/// Caller-supplied argument. Restricted to types Fluent can interpolate or select on.
	enum Argument: Hashable, Sendable {

		case string(String)
		case number(Number)
		case custom(AnyHashableSendable)

		public init(_ v: String) { self = .string(v) }
		public init(_ v: Int) { self = .number(Number(v)) }
		public init(_ v: Double) { self = .number(Number(v)) }
		public init(_ v: Number) { self = .number(v) }

		public var value: Value {
			switch self {
			case let .string(s): return .string(s)
			case let .number(n): return .number(n)
			case let .custom(c): return .custom(c)
			}
		}
	}

	typealias Arguments = [String: Argument]

	/// Type-erased Hashable+Sendable+Stringly-described box for custom values.
	struct AnyHashableSendable: Hashable, @unchecked Sendable, CustomStringConvertible {

		public let base: AnyHashable
		public let description: String

		public init<T: Hashable & Sendable & CustomStringConvertible>(_ value: T) {
			base = AnyHashable(value)
			description = value.description
		}

		public init<T: Hashable & Sendable>(_ value: T, description: String) {
			base = AnyHashable(value)
			self.description = description
		}

		public static func == (lhs: Self, rhs: Self) -> Bool { lhs.base == rhs.base }
		public func hash(into hasher: inout Hasher) { hasher.combine(base) }
	}
}

extension Fluent.Argument: ExpressibleByStringLiteral, ExpressibleByIntegerLiteral, ExpressibleByFloatLiteral {
	public init(stringLiteral value: String) { self = .string(value) }
	public init(integerLiteral value: Int) { self = .number(Fluent.Number(value)) }
	public init(floatLiteral value: Double) { self = .number(Fluent.Number(value)) }
}
