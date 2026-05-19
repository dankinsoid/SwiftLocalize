// @ai-generated(solo)
import Foundation

public extension Fluent {

	/// Numeric value with optional formatting metadata.
	/// Mirrors Fluent's NUMBER() function options (a subset of ECMA-402 Intl.NumberFormat).
	struct Number: Hashable, Codable, Sendable {

		public var value: Double
		public var options: Options

		public init(_ value: Double, options: Options = Options()) {
			self.value = value
			self.options = options
		}

		public init(_ value: Int, options: Options = Options()) {
			self.value = Double(value)
			self.options = options
		}

		public struct Options: Hashable, Codable, Sendable {

			public var style: Style
			public var currency: String?
			public var currencyDisplay: CurrencyDisplay
			public var useGrouping: Bool
			public var minimumIntegerDigits: Int?
			public var minimumFractionDigits: Int?
			public var maximumFractionDigits: Int?
			public var minimumSignificantDigits: Int?
			public var maximumSignificantDigits: Int?

			public init(
				style: Style = .decimal,
				currency: String? = nil,
				currencyDisplay: CurrencyDisplay = .symbol,
				useGrouping: Bool = true,
				minimumIntegerDigits: Int? = nil,
				minimumFractionDigits: Int? = nil,
				maximumFractionDigits: Int? = nil,
				minimumSignificantDigits: Int? = nil,
				maximumSignificantDigits: Int? = nil
			) {
				self.style = style
				self.currency = currency
				self.currencyDisplay = currencyDisplay
				self.useGrouping = useGrouping
				self.minimumIntegerDigits = minimumIntegerDigits
				self.minimumFractionDigits = minimumFractionDigits
				self.maximumFractionDigits = maximumFractionDigits
				self.minimumSignificantDigits = minimumSignificantDigits
				self.maximumSignificantDigits = maximumSignificantDigits
			}

			public enum Style: String, Hashable, Codable, Sendable {
				case decimal, currency, percent
			}

			public enum CurrencyDisplay: String, Hashable, Codable, Sendable {
				case symbol, code, name
			}
		}

		/// Locale-aware formatting via Foundation's NumberFormatter.
		public func formatted(locale: Fluent.Tag) -> String {
			let f = NumberFormatter()
			f.locale = Locale(identifier: locale.rawValue)
			f.usesGroupingSeparator = options.useGrouping
			switch options.style {
			case .decimal: f.numberStyle = .decimal
			case .currency:
				f.numberStyle = .currency
				if let c = options.currency { f.currencyCode = c }
			case .percent: f.numberStyle = .percent
			}
			if let v = options.minimumIntegerDigits { f.minimumIntegerDigits = v }
			if let v = options.minimumFractionDigits { f.minimumFractionDigits = v }
			if let v = options.maximumFractionDigits { f.maximumFractionDigits = v }
			if let v = options.minimumSignificantDigits {
				f.usesSignificantDigits = true
				f.minimumSignificantDigits = v
			}
			if let v = options.maximumSignificantDigits {
				f.usesSignificantDigits = true
				f.maximumSignificantDigits = v
			}
			return f.string(from: NSNumber(value: value)) ?? String(value)
		}
	}
}
