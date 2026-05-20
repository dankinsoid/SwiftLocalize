import Foundation

public extension Language {

	/// Locale-aware quotation marks per CLDR `delimiters.json`.
	///
	/// Returns the **primary** pair at even nesting levels (`«…»` in ru, `"…"` in en),
	/// the **alternate** pair at odd levels (`„…"` in ru, `'…'` in en). Levels alternate —
	/// pass the depth of the surrounding quote, so the outermost call uses `level: 0`.
	///
	/// Lookup canonicalizes the tag (`iw` → `he`) and walks the CLDR parent chain
	/// (`en-AU` → `en-001` → `en`), so any sub-locale resolves even if it lacks its
	/// own entry. If no ancestor matches, falls back to CLDR's `und` defaults
	/// (`"…"` / `'…'`).
	func quotationMarks(level: Int = 0) -> (start: String, end: String) {
		let entry = resolvedDelimiters()
		return level.isMultiple(of: 2)
			? (entry.start, entry.end)
			: (entry.altStart, entry.altEnd)
	}

	/// Tuple of all four delimiters (primary + alternate) — useful when emitting
	/// both pairs at once (e.g. building a renderer that pre-resolves marks once
	/// per language). Same lookup rules as `quotationMarks(level:)`.
	var quotationDelimiters: (start: String, end: String, altStart: String, altEnd: String) {
		resolvedDelimiters()
	}

	/// Walks `canonical` then parents until a `DelimiterData.quotes` entry matches.
	/// Falls back to `und` — guaranteed present in the generated table.
	private func resolvedDelimiters() -> (start: String, end: String, altStart: String, altEnd: String) {
		var current = canonical
		while true {
			if let entry = DelimiterData.quotes[current.rawValue] { return entry }
			guard let next = current.parent else { break }
			current = next
		}
		// `und` is CLDR's "undetermined" locale and the universal default — generated
		// from the same `delimiters.json` table, so this force-unwrap is safe by
		// construction. Asserting makes a future regeneration that drops `und` loud.
		guard let fallback = DelimiterData.quotes["und"] else {
			assertionFailure("DelimiterData.quotes is missing the 'und' fallback entry.")
			return ("\u{201C}", "\u{201D}", "\u{2018}", "\u{2019}")
		}
		return fallback
	}
}

public extension String {

	/// Wrap `self` in `language`'s quotation marks.
	///
	/// ```swift
	/// "Привет".quoted(in: .ru)         // «Привет»
	/// "world".quoted(in: .en)          // "world"
	/// "innen".quoted(in: .de, level: 1) // ‚innen' (alternate for nesting)
	/// ```
	///
	/// `level` controls nesting depth — see `Language.quotationMarks(level:)`.
	func quoted(in language: Language = .current, level: Int = 0) -> String {
		let (s, e) = language.quotationMarks(level: level)
		return s + self + e
	}
}
