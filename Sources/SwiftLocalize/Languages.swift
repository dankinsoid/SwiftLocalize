import Foundation

	/// BCP-47 language tag. Open: any string is accepted, named constants are convenience.
	///
	/// Replaces the legacy closed `Language` enum so that bn/ta/sw/cy/fa or regional
	/// variants (en-GB, pt-BR, zh-Hans) can be expressed without modifying the library.
public struct Language: Hashable, Codable, Sendable, RawRepresentable, ExpressibleByStringLiteral, CustomStringConvertible, LosslessStringConvertible {
	
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
	public var language: String { components.language }
	
	/// 4-letter script subtag if present, title-cased (e.g. "Hant" from "zh-Hant-TW").
	public var script: String? { components.script }
	
	/// Region subtag if present (e.g. "US" from "en-US", "TW" from "zh-Hant-TW", "419" from "es-419").
	/// Searches all subtag positions — not limited to position 1.
	public var region: String? { components.region }
	
	/// Returns `self` minus region/script — useful for plural-rules lookup.
	public var languageOnly: Language { Language(rawValue: language) }
	
	/// Parsed subtags. Computed on every access — cache at the call site for hot paths.
	internal var components: Components {
		Components(rawValue)
	}
	
	/// Parsed BCP-47 subtags. Internal — public surface is via the named accessors.
	///
	/// Heuristic: first subtag is language; among the rest, 4 letters → script (title-cased),
	/// 2 letters or 3 digits → region, anything else → variant/extension.
	internal struct Components: Hashable {
		
		let language: String
		let script: String?
		let region: String?
		let trailing: [String]
		
		init(_ raw: String) {
			let parts = raw.split(separator: "-", omittingEmptySubsequences: true).map(String.init)
			guard let first = parts.first else {
				language = ""; script = nil; region = nil; trailing = []
				return
			}
			language = first.lowercased()
			var s: String?
			var r: String?
			var rest: [String] = []
			for sub in parts.dropFirst() {
				if s == nil && sub.count == 4 && sub.allSatisfy(\.isLetter) {
					s = sub.prefix(1).uppercased() + sub.dropFirst().lowercased()
				} else if r == nil && (sub.count == 2 && sub.allSatisfy(\.isLetter)) {
					r = sub.uppercased()
				} else if r == nil && (sub.count == 3 && sub.allSatisfy(\.isNumber)) {
					r = sub
				} else {
					rest.append(sub.lowercased())
				}
			}
			script = s; region = r; trailing = rest
		}
		
		/// Re-assemble subtags into a canonical BCP-47 string.
		var bcp47: String {
			var out = language
			if let s = script { out += "-" + s }
			if let r = region { out += "-" + r }
			for v in trailing { out += "-" + v }
			return out
		}
	}
	
	private static func normalize(_ raw: String) -> String {
		// Accept both BCP-47 (`en-US`) and POSIX (`en_US`) separators. Foundation's
		// `Locale.identifier` returns the underscore form on some platforms, so callers
		// can pass either without surprise; output is always BCP-47 with `-`.
		let parts = raw.split(omittingEmptySubsequences: true, whereSeparator: { $0 == "-" || $0 == "_" })
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

@available(macOS 12.3, iOS 15.4, tvOS 15.4, watchOS 8.5, *)
extension Language: CodingKeyRepresentable {

	public var codingKey: CodingKey { rawValue.codingKey }

	public init<T: CodingKey>(codingKey: T) {
		self.init(rawValue: codingKey.stringValue)
	}
}

public extension Language {

	/// Best-effort current locale from the user's preferred languages.
	static var current: Self {
		let raw = Locale.preferredLanguages.first ?? Locale.current.identifier
		return Self(rawValue: raw)
	}
}

@available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
public extension FormatStyle {

	/// Sets the language (and thus locale) for this format style.
	func language(_ language: Language) -> Self {
		locale(Locale(identifier: language.rawValue))
	}
}
