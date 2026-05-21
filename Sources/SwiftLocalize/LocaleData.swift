// @ai-generated(guided)
import Foundation

internal extension LocaleData {

	/// Resolves a tag against the CLDR likely-subtags table.
	///
	/// The data is split across two storages — a small dictionary for the most-used
	/// bare language subtags (`likelySubtagsCommon`, O(1)) and a sorted array of
	/// tuples for the long tail (`likelySubtagsRare`, O(log n) via binary search).
	/// The split exists purely so the generated file's dictionary literal stays
	/// small enough for the Swift compiler to type-check quickly — semantically
	/// this method is equivalent to a single combined dictionary lookup.
	static func likelySubtag(for key: String) -> String? {
		if let hit = likelySubtagsCommon[key] { return hit }
		return likelySubtagsRareLookup(key)
	}

	private static func likelySubtagsRareLookup(_ key: String) -> String? {
		let pairs = likelySubtagsRare
		var lo = 0
		var hi = pairs.count
		while lo < hi {
			let mid = (lo &+ hi) >> 1
			if pairs[mid].0 < key {
				lo = mid &+ 1
			} else {
				hi = mid
			}
		}
		return lo < pairs.count && pairs[lo].0 == key ? pairs[lo].1 : nil
	}

	// MARK: - Packed-literal parsers
	//
	// The large generated tables are emitted as `key\tvalue\n…` string literals
	// rather than as `[String: String]` / `[(String, String)]` literals — Swift's
	// type-checker handles a single long string literal in milliseconds, but
	// stalls for tens of seconds on dictionary literals with thousands of
	// entries. We pay back the saved compile time with a one-shot parse on first
	// access (sub-millisecond per table; `static let` caches the result).
	//
	// Tags are pure ASCII (`[A-Za-z0-9-]`), so `\t` and `\n` are unambiguous
	// separators — no escaping needed. Empty/malformed lines are skipped
	// defensively but should never appear in generator output.

	static func parseDict(_ raw: String) -> [String: String] {
		var out: [String: String] = [:]
		out.reserveCapacity(raw.utf8.count / 16)
		for line in raw.split(separator: "\n", omittingEmptySubsequences: true) {
			guard let tab = line.firstIndex(of: "\t") else { continue }
			let key = String(line[..<tab])
			let value = String(line[line.index(after: tab)...])
			out[key] = value
		}
		return out
	}

	static func parsePairs(_ raw: String) -> [(String, String)] {
		var out: [(String, String)] = []
		out.reserveCapacity(raw.utf8.count / 16)
		for line in raw.split(separator: "\n", omittingEmptySubsequences: true) {
			guard let tab = line.firstIndex(of: "\t") else { continue }
			let key = String(line[..<tab])
			let value = String(line[line.index(after: tab)...])
			out.append((key, value))
		}
		return out
	}
}
