// @ai-generated(solo)
import Foundation

public extension Fluent {

	/// BCP-47 language tag. Open: any string is accepted, named constants are convenience.
	///
	/// Replaces the legacy closed `Language` enum so that bn/ta/sw/cy/fa or regional
	/// variants (en-GB, pt-BR, zh-Hans) can be expressed without modifying the library.
	struct Tag: Hashable, Codable, Sendable, RawRepresentable, ExpressibleByStringLiteral, CustomStringConvertible, LosslessStringConvertible {

		public let rawValue: String

		public init(rawValue: String) {
			self.rawValue = Self.normalize(rawValue)
		}

		public init(_ raw: String) {
			self.rawValue = Self.normalize(raw)
		}

		public init(stringLiteral value: String) {
			self.init(rawValue: value)
		}

		public var description: String { rawValue }

		public init(from decoder: Decoder) throws {
			try self.init(rawValue: String(from: decoder))
		}

		public func encode(to encoder: Encoder) throws {
			try rawValue.encode(to: encoder)
		}

		/// Primary subtag, lower-cased (e.g. "en" from "en-US").
		public var language: String {
			rawValue.split(separator: "-", maxSplits: 1).first.map(String.init) ?? rawValue
		}

		/// Region subtag if present (e.g. "US" from "en-US").
		public var region: String? {
			let parts = rawValue.split(separator: "-")
			guard parts.count > 1 else { return nil }
			let candidate = String(parts[1])
			return candidate.count == 2 ? candidate.uppercased() : nil
		}

		/// Returns `self` minus region/script — useful for plural-rules lookup.
		public var languageOnly: Tag { Tag(rawValue: language) }

		private static func normalize(_ raw: String) -> String {
			let parts = raw.split(separator: "-", omittingEmptySubsequences: true)
			guard let first = parts.first else { return "" }
			var out = first.lowercased()
			for sub in parts.dropFirst() {
				if sub.count == 2 {
					out += "-" + sub.uppercased()
				} else if sub.count == 4 {
					out += "-" + sub.prefix(1).uppercased() + sub.dropFirst().lowercased()
				} else {
					out += "-" + sub.lowercased()
				}
			}
			return out
		}
	}
}

@available(macOS 12.3, iOS 15.4, tvOS 15.4, watchOS 8.5, *)
extension Fluent.Tag: CodingKeyRepresentable {

	public var codingKey: CodingKey { rawValue.codingKey }

	public init<T: CodingKey>(codingKey: T) {
		self.init(rawValue: codingKey.stringValue)
	}
}

public extension Fluent.Tag {
	static let en: Self = "en"
	static let ru: Self = "ru"
	static let it: Self = "it"
	static let fr: Self = "fr"
	static let es: Self = "es"
	static let pt: Self = "pt"
	static let de: Self = "de"
	static let zh: Self = "zh"
	static let nl: Self = "nl"
	static let ja: Self = "ja"
	static let ko: Self = "ko"
	static let vi: Self = "vi"
	static let sv: Self = "sv"
	static let da: Self = "da"
	static let fi: Self = "fi"
	static let nb: Self = "nb"
	static let tr: Self = "tr"
	static let el: Self = "el"
	static let id: Self = "id"
	static let ms: Self = "ms"
	static let th: Self = "th"
	static let hi: Self = "hi"
	static let hu: Self = "hu"
	static let pl: Self = "pl"
	static let cs: Self = "cs"
	static let sk: Self = "sk"
	static let uk: Self = "uk"
	static let ca: Self = "ca"
	static let ro: Self = "ro"
	static let hr: Self = "hr"
	static let he: Self = "he"
	static let ar: Self = "ar"
	static let cy: Self = "cy"
	static let sl: Self = "sl"
	static let bn: Self = "bn"
	static let ta: Self = "ta"
	static let sw: Self = "sw"
	static let fa: Self = "fa"

	/// Best-effort current locale from the user's preferred languages.
	static var current: Self {
		let raw = Locale.preferredLanguages.first ?? Locale.current.identifier
		return Self(rawValue: raw)
	}
}
