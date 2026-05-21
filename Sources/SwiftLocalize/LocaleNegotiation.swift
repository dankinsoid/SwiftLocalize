// @ai-generated(solo)
import Foundation

// MARK: - Tag canonicalization & expansion

public extension Language {

	/// Canonicalize deprecated subtags per CLDR aliases.
	///
	/// Examples: `iw` → `he`, `in` → `id`, `BU` (region) → `MM`, `Qaai` (script) → `Zinh`.
	/// Multi-subtag replacements (e.g. `sh` → `sr-Latn`) are applied as a whole: the
	/// replacement's script/region fill in for subtags that the original lacked.
	var canonical: Language {
		var c = components

		// Language alias may carry a script/region that fills in missing ones on `self`.
		if let replacement = LocaleData.languageAliases[c.language] {
			let r = Components(replacement)
			c = Components(
				language: r.language,
				script: c.script ?? r.script,
				region: c.region ?? r.region,
				trailing: c.trailing
			)
		}
		if let s = c.script, let replaced = LocaleData.scriptAliases[s] {
			c = Components(language: c.language, script: replaced, region: c.region, trailing: c.trailing)
		}
		if let r = c.region, let replaced = LocaleData.regionAliases[r] {
			c = Components(language: c.language, script: c.script, region: replaced, trailing: c.trailing)
		}
		return Language(rawValue: c.bcp47)
	}

	/// Expand to maximal form via CLDR likely-subtags.
	///
	/// `zh` → `zh-Hans-CN`, `zh-TW` → `zh-Hant-TW`, `sr` → `sr-Cyrl-RS`. Subtags that
	/// `self` already specifies are preserved; only missing ones are filled in.
	var maximized: Language {
		let c = components
		// Try most specific keys first so an exact `lang-script` / `lang-region` hit wins
		// over the bare-language default (which would discard our script or region).
		let keys: [String] = [
			[c.language, c.script, c.region].compactMap { $0 }.joined(separator: "-"),
			[c.language, c.region].compactMap { $0 }.joined(separator: "-"),
			[c.language, c.script].compactMap { $0 }.joined(separator: "-"),
			c.language,
		]
		for key in keys {
			guard !key.isEmpty, let hit = LocaleData.likelySubtag(for: key) else { continue }
			let h = Components(hit)
			let merged = Components(
				language: h.language,
				script: c.script ?? h.script,
				region: c.region ?? h.region,
				trailing: c.trailing
			)
			return Language(rawValue: merged.bcp47)
		}
		return self
	}

	/// Parent in the CLDR locale hierarchy, or `nil` at the top.
	///
	/// Resolution order:
	///   1. `parentLocales` table for non-trivial chains (`en-AU` → `en-001` → `en`, `es-AR` → `es-419` → `es`).
	///   2. Drop region (`en-US` → `en`, `zh-Hant-TW` → `zh-Hant`).
	///   3. Drop script if it matches the language's default script per likelySubtags
	///      (`sr-Cyrl` → `sr`, but `sr-Latn` stays — Latn isn't sr's default and stripping would change meaning).
	///   4. Otherwise `nil`.
	var parent: Language? {
		if let p = LocaleData.parentLocales[rawValue] {
			// CLDR uses "root" as a sentinel meaning "no further parent". We surface
			// that as nil so callers can stop walking without a string compare.
			return p == "root" ? nil : Language(rawValue: p)
		}
		let c = components
		if c.region != nil {
			return Language(rawValue: Components(
				language: c.language, script: c.script, region: nil, trailing: c.trailing
			).bcp47)
		}
		if let s = c.script {
			// Only strip if it's the language's default script.
			if let likely = LocaleData.likelySubtag(for: c.language) {
				let defaultScript = Components(likely).script
				if defaultScript == s {
					return Language(rawValue: c.language)
				}
			}
			return nil
		}
		return nil
	}
}

// MARK: - Negotiation

/// Locale-negotiation algorithms backed by CLDR data (likely subtags, parent locales, aliases).
///
/// Mirrors `fluent-langneg`'s `negotiateLanguages`. Two strategies are exposed:
///
/// - **matching** (default): one best match per requested locale, in priority order.
/// - **filtering**: every available locale that matches any requested locale, in priority order.
///
/// Both pass through canonicalization (deprecated subtag replacement) and maximization
/// (likely-subtag expansion), so `zh-TW` matches an available `zh-Hant`, `iw` matches `he`, etc.
public enum LocaleNegotiation {

	/// One best match per requested locale, in requested order.
	///
	/// For each requested locale, walks its parent chain (CLDR `parentLocales` + region/script trimming)
	/// looking for any available locale whose maximized form matches. The optional `default` is
	/// appended at the tail if not already in the result.
	public static func matching(
		requested: [Language],
		available: [Language],
		default fallback: Language? = nil
	) -> [Language] {
		// Cache canonical + maximized form per available, preserving original order for ties.
		let availableEntries: [(tag: Language, canonical: Language, maximized: Language)] = available.map {
			let c = $0.canonical
			return ($0, c, c.maximized)
		}
		var pool = Array(availableEntries.indices)
		var result: [Language] = []

		for req in requested {
			var current = req.canonical
			while true {
				let currentMax = current.maximized
				if let poolIdx = pool.firstIndex(where: { idx in
					let e = availableEntries[idx]
					return e.canonical == current || e.maximized == currentMax || e.tag == current
				}) {
					result.append(availableEntries[pool[poolIdx]].tag)
					pool.remove(at: poolIdx)
					break
				}
				guard let next = current.parent else { break }
				current = next
			}
		}

		if let fallback = fallback {
			let fb = fallback.canonical
			if !result.contains(where: { $0.canonical == fb }) {
				result.append(fallback)
			}
		}
		return result
	}

	/// Every available locale that matches any requested locale, in priority order.
	///
	/// Useful for prefetching: load all bundles that could service the user's
	/// requested locales, in best-first order.
	public static func filtering(
		requested: [Language],
		available: [Language],
		default fallback: Language? = nil
	) -> [Language] {
		let availableEntries: [(tag: Language, canonical: Language, maximized: Language)] = available.map {
			let c = $0.canonical
			return ($0, c, c.maximized)
		}
		var pool = Array(availableEntries.indices)
		var result: [Language] = []

		for req in requested {
			var current = req.canonical
			while !pool.isEmpty {
				let currentMax = current.maximized
				let matches = pool.filter { idx in
					let e = availableEntries[idx]
					return e.canonical == current || e.maximized == currentMax || e.tag == current
				}
				if !matches.isEmpty {
					for idx in matches {
						result.append(availableEntries[idx].tag)
					}
					pool.removeAll(where: matches.contains)
				}
				guard let next = current.parent else { break }
				current = next
			}
		}

		if let fallback = fallback {
			let fb = fallback.canonical
			if !result.contains(where: { $0.canonical == fb }) {
				result.append(fallback)
			}
		}
		return result
	}
}

// MARK: - Components init shim

internal extension Language.Components {

	init(language: String, script: String?, region: String?, trailing: [String]) {
		self.language = language
		self.script = script
		self.region = region
		self.trailing = trailing
	}
}
