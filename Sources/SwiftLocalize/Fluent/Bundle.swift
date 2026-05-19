// @ai-generated(solo)
import Foundation

public extension Fluent {

	/// Single-locale runtime that formats `Message` objects with caller-supplied arguments.
	///
	/// Mirrors Fluent's `FluentBundle`. Holds messages, terms, and functions; resolves placeables,
	/// references, and selectors per the Fluent spec. One bundle = one locale; for multi-locale apps
	/// wrap with `Fluent.LocalizedBundle`.
	final class Bundle: @unchecked Sendable {

		public let locale: Tag
		public private(set) var messages: [Identifier: Message] = [:]
		public private(set) var terms: [Identifier: Term] = [:]
		public private(set) var functions: [Identifier: Function]

		/// Maximum allowed resolution depth before bailing out — prevents runaway cycles
		/// even when the user has constructed terms that reference each other.
		public var maxResolutionDepth: Int = 32

		/// Wrap each placeable's resolved value in Unicode FSI (`U+2068`) / PDI (`U+2069`)
		/// isolates so the Bidi algorithm can't reorder placeable content with surrounding text.
		/// Default matches fluent.js / fluent-rs (`true`). Disable in tests where invisible
		/// isolate marks make string comparisons unreadable.
		public var useIsolating: Bool

		public init(
			locale: Tag,
			useIsolating: Bool = true,
			functions: [Identifier: Function] = BuiltinFunctions.all
		) {
			self.locale = locale
			self.useIsolating = useIsolating
			self.functions = functions
		}

		// MARK: Registration

		public func add(_ entry: Entry) {
			switch entry {
			case let .message(m): messages[m.id] = m
			case let .term(t): terms[t.id] = t
			case .comment: break
			}
		}

		public func add(_ resource: Resource) {
			resource.entries.forEach(add)
		}

		public func add(_ message: Message) { messages[message.id] = message }
		public func add(_ term: Term) { terms[term.id] = term }
		public func add(function: @escaping Function, name: Identifier) { functions[name] = function }

		// MARK: Formatting

		/// Formats a message (or one of its attributes) for the bundle's locale.
		/// On missing message/attribute the returned string is `{message-id}` or `{message-id.attr}`
		/// — Fluent convention for keeping problems visible without crashing.
		public func format(
			_ id: Identifier,
			attribute: Identifier? = nil,
			args: Arguments = [:]
		) -> String {
			guard let message = messages[id] else {
				return "{" + id.rawValue + (attribute.map { "." + $0.rawValue } ?? "") + "}"
			}
			let pattern: Pattern?
			if let attribute = attribute {
				pattern = message.attributes.first { $0.id == attribute }?.value
			} else {
				pattern = message.value
			}
			guard let pattern = pattern else {
				return "{" + id.rawValue + (attribute.map { "." + $0.rawValue } ?? "") + "}"
			}
			var scope = Scope(bundle: self, args: args)
			return scope.format(pattern: pattern)
		}
	}
}

// MARK: - Internal Resolver / Scope

internal extension Fluent {

	/// One resolution invocation. Carries the args, locale, and per-call mutable state
	/// (depth counter, term-call args). Reset per `Bundle.format` call.
	struct Scope {

		let bundle: Fluent.Bundle
		var args: Fluent.Arguments
		var depth: Int = 0
		/// Stack of term arguments — terms can pass their own args, isolated from outer scope.
		var termArgsStack: [Fluent.Arguments] = []

		var locale: Fluent.Tag { bundle.locale }

		mutating func format(pattern: Fluent.Pattern) -> String {
			var out = ""
			for element in pattern.elements {
				switch element {
				case let .text(s):
					out += s
				case let .placeable(expr):
					let formatted = resolve(expr).formatted(locale: locale)
					if bundle.useIsolating && !formatted.isEmpty {
						out += "\u{2068}"
						out += formatted
						out += "\u{2069}"
					} else {
						out += formatted
					}
				}
			}
			return out
		}

		mutating func resolve(_ expr: Fluent.Expression) -> Fluent.Value {
			guard depth < bundle.maxResolutionDepth else { return .none }
			depth += 1
			defer { depth -= 1 }

			switch expr {
			case let .stringLiteral(s):
				return .string(s)

			case let .numberLiteral(n):
				return .number(n)

			case let .variableReference(id):
				let pool = termArgsStack.last ?? args
				if let a = pool[id.rawValue] { return a.value }
				return .string("{$" + id.rawValue + "}")

			case let .messageReference(id, attribute):
				guard let msg = bundle.messages[id] else {
					return .string("{" + id.rawValue + (attribute.map { "." + $0.rawValue } ?? "") + "}")
				}
				let pattern: Fluent.Pattern?
				if let attribute = attribute {
					pattern = msg.attributes.first { $0.id == attribute }?.value
				} else {
					pattern = msg.value
				}
				guard let p = pattern else {
					return .string("{" + id.rawValue + (attribute.map { "." + $0.rawValue } ?? "") + "}")
				}
				return .string(format(pattern: p))

			case let .termReference(id, attribute, callArgs):
				guard let term = bundle.terms[id] else {
					return .string("{-" + id.rawValue + (attribute.map { "." + $0.rawValue } ?? "") + "}")
				}
				let pattern: Fluent.Pattern
				if let attribute = attribute {
					guard let attr = term.attributes.first(where: { $0.id == attribute }) else {
						return .string("{-" + id.rawValue + "." + attribute.rawValue + "}")
					}
					pattern = attr.value
				} else {
					pattern = term.value
				}
				let termArgs = resolveCallArguments(callArgs)
				termArgsStack.append(termArgs)
				defer { termArgsStack.removeLast() }
				return .string(format(pattern: pattern))

			case let .functionReference(id, callArgs):
				guard let fn = bundle.functions[id] else {
					return .string("{" + id.rawValue + "()}")
				}
				let positional = callArgs.positional.map { resolve($0) }
				let named = Dictionary(uniqueKeysWithValues: callArgs.named.map { ($0.key.rawValue, resolve($0.value)) })
				return fn(positional, named, locale)

			case let .select(sel):
				let selectorValue = resolve(sel.selector)
				let variant = pickVariant(selectorValue, in: sel)
				return .string(format(pattern: variant.value))
			}
		}

		private mutating func resolveCallArguments(_ args: Fluent.CallArguments?) -> Fluent.Arguments {
			guard let args = args else { return [:] }
			var out: Fluent.Arguments = [:]
			for (id, expr) in args.named {
				switch resolve(expr) {
				case let .string(s): out[id.rawValue] = .string(s)
				case let .number(n): out[id.rawValue] = .number(n)
				case let .custom(c): out[id.rawValue] = .custom(c)
				case .none: break
				}
			}
			return out
		}

		private func pickVariant(_ value: Fluent.Value, in select: Fluent.SelectExpression) -> Fluent.Variant {
			for variant in select.variants {
				if matches(key: variant.key, value: value) { return variant }
			}
			return select.defaultVariant
		}

		private func matches(key: Fluent.VariantKey, value: Fluent.Value) -> Bool {
			switch (key, value) {
			case let (.identifier(id), .string(s)):
				return id.rawValue == s
			case let (.identifier(id), .number(n)):
				// Number → plural-category match. `n.options.type` selects cardinal vs ordinal rule set.
				guard let cat = Fluent.PluralCategory(rawValue: id.rawValue) else { return false }
				return Fluent.PluralCategory.of(n.value, locale: locale, type: n.options.type) == cat
			case let (.number(a), .number(b)):
				return a.value == b.value
			case let (.number(a), .string(s)):
				return Double(s).map { $0 == a.value } ?? false
			default:
				return false
			}
		}
	}
}
