// @ai-generated(solo)
import Foundation

public extension Fluent {

	/// User-installable function callable from placeables: `{ FUNC($x, opt: 1) }`.
	/// Mirrors Fluent's built-in `NUMBER` / `DATETIME` extension point.
	typealias Function = @Sendable (_ positional: [Value], _ named: [String: Value], _ locale: Tag) -> Value

	enum BuiltinFunctions {

		/// `NUMBER($n, ...options)` — wraps a number with formatting options.
		public static let number: Function = { positional, named, _ in
			guard let first = positional.first else { return .none }
			let value: Double
			switch first {
			case let .number(n): value = n.value
			case let .string(s): value = Double(s) ?? .nan
			case .none, .custom: return .none
			}
			var options = Number.Options()
			if case let .string(style) = named["style"], let s = Number.Options.Style(rawValue: style) { options.style = s }
			if case let .string(c) = named["currency"] { options.currency = c }
			if case let .number(min) = named["minimumFractionDigits"] { options.minimumFractionDigits = Int(min.value) }
			if case let .number(max) = named["maximumFractionDigits"] { options.maximumFractionDigits = Int(max.value) }
			return .number(Number(value, options: options))
		}

		/// Minimal stub for `DATETIME` — accepts a Unix timestamp (seconds) and formats with locale.
		public static let datetime: Function = { positional, _, locale in
			guard let first = positional.first, case let .number(n) = first else { return .none }
			let date = Date(timeIntervalSince1970: n.value)
			let f = DateFormatter()
			f.locale = Locale(identifier: locale.rawValue)
			f.dateStyle = .medium
			f.timeStyle = .short
			return .string(f.string(from: date))
		}

		public static var all: [Identifier: Function] {
			[
				"NUMBER": number,
				"DATETIME": datetime,
			]
		}
	}
}
