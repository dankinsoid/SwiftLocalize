import Foundation

public extension Language {

	/// CLDR range-format pattern with `{0}`/`{1}` placeholders, e.g. `"{0}–{1}"` (en, ru, de),
	/// `"{0}～{1}"` (ja), `"{0}-{1}"` (zh). Use this when you want to interpolate yourself
	/// — `rangeSeparator` and `String.rangeJoined(to:in:)` cover the common path.
	///
	/// Lookup canonicalizes the tag (`iw` → `he`) and walks the CLDR parent chain
	/// (`en-AU` → `en-001` → `en`); falls back to `und`'s pattern (`"{0}–{1}"`) when
	/// no ancestor matches.
	var rangePattern: String {
		resolvedRangePattern()
	}

	/// The visual separator between range bounds — the pattern minus its `{0}` and `{1}`
	/// placeholders. Pretty much always a single character (`–`, `—`, `～`, `-`), but in
	/// principle could be a multi-char run if CLDR ever ships one.
	var rangeSeparator: String {
		let pattern = resolvedRangePattern()
		return pattern
			.replacingOccurrences(of: "{0}", with: "")
			.replacingOccurrences(of: "{1}", with: "")
	}

	private func resolvedRangePattern() -> String {
		var current = canonical
		while true {
			if let pattern = RangePatternData.patterns[current.rawValue] { return pattern }
			guard let next = current.parent else { break }
			current = next
		}
		// `und` is CLDR's universal-default locale and always emitted by the generator;
		// asserting makes a future regeneration that drops it loud.
		guard let fallback = RangePatternData.patterns["und"] else {
			assertionFailure("RangePatternData.patterns is missing the 'und' fallback entry.")
			return "{0}\u{2013}{1}"
		}
		return fallback
	}
}

public extension String {

	/// Join `self`–`upper` into a localized range string using the language's CLDR
	/// range pattern.
	///
	/// ```swift
	/// "2020".rangeJoined(to: "2025", in: .en)  // "2020–2025"
	/// "2020".rangeJoined(to: "2025", in: .ja)  // "2020～2025"
	/// "2020".rangeJoined(to: "2025", in: .zh)  // "2020-2025"
	/// ```
	///
	/// Both bounds are inserted verbatim — format numbers/dates yourself before
	/// joining (e.g. `n.formatted(.number.language(.fr))`) so the digits themselves
	/// respect the locale.
	func rangeJoined(to upper: String, in language: Language = .current) -> String {
		language.rangePattern
			.replacingOccurrences(of: "{0}", with: self)
			.replacingOccurrences(of: "{1}", with: upper)
	}
}

