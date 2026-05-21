// @ai-generated(solo)
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
}
