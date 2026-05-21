// Microbenchmark for the generated LocaleData tables.
// Run a SINGLE test per process so the cold measurement is real:
//   swift test -c release --filter LocaleDataBenchmark/testLikelySubtagsCold
//   swift test -c release --filter LocaleDataBenchmark/testLikelySubtagsWarm
//   swift test -c release --filter LocaleDataBenchmark/testAliasesCold
//   swift test -c release --filter LocaleDataBenchmark/testAliasesWarm

@testable import SwiftLocalize
import XCTest

final class LocaleDataBenchmark: XCTestCase {

	// MARK: - likelySubtags (rare table: ~7,700 entries)

	func testLikelySubtagsCold() {
		// First call into likelySubtag(for:) triggers lazy init of both
		// likelySubtagsCommon (tiny) and likelySubtagsRare (~7,700 tuples).
		// Use a rare key so we exercise the full path including the array.
		let t0 = DispatchTime.now().uptimeNanoseconds
		let hit = LocaleData.likelySubtag(for: "aa")
		let t1 = DispatchTime.now().uptimeNanoseconds
		XCTAssertNotNil(hit)
		report("likelySubtags COLD (first lookup, includes lazy init)", ns: t1 - t0, iters: 1)
	}

	func testLikelySubtagsWarm() {
		// Pre-warm
		_ = LocaleData.likelySubtag(for: "aa")

		// Mix of rare keys (forces the binary search) and common keys (hot dict).
		let rare: [String] = ["aa", "bb", "ccc", "zh-Hant", "es-419", "und-Latn", "fr-CA", "kkk", "wuu", "nan"]
		let common: [String] = ["en", "fr", "de", "ja", "zh", "ru", "es", "pt", "ar", "und"]
		let keys = rare + common
		let n = 1_000_000
		var sink = 0
		let t0 = DispatchTime.now().uptimeNanoseconds
		for i in 0..<n {
			if LocaleData.likelySubtag(for: keys[i % keys.count]) != nil { sink &+= 1 }
		}
		let t1 = DispatchTime.now().uptimeNanoseconds
		XCTAssertGreaterThan(sink, 0)
		report("likelySubtags WARM (1M mixed lookups)", ns: t1 - t0, iters: n)
	}

	// MARK: - regionAliases (~641 entries)

	func testRegionAliasesCold() {
		let t0 = DispatchTime.now().uptimeNanoseconds
		let hit = LocaleData.regionAliases["BU"]
		let t1 = DispatchTime.now().uptimeNanoseconds
		XCTAssertEqual(hit, "MM")
		report("regionAliases COLD (first lookup)", ns: t1 - t0, iters: 1)
	}

	func testRegionAliasesWarm() {
		_ = LocaleData.regionAliases["BU"]
		let keys = ["BU", "SU", "YU", "ZR", "CS", "DD", "FX", "AN", "TP", "ZZ"]
		let n = 1_000_000
		var sink = 0
		let t0 = DispatchTime.now().uptimeNanoseconds
		for i in 0..<n {
			if LocaleData.regionAliases[keys[i % keys.count]] != nil { sink &+= 1 }
		}
		let t1 = DispatchTime.now().uptimeNanoseconds
		XCTAssertGreaterThan(sink, 0)
		report("regionAliases WARM (1M lookups)", ns: t1 - t0, iters: n)
	}

	// MARK: - languageAliases (~503 entries)

	func testLanguageAliasesCold() {
		let t0 = DispatchTime.now().uptimeNanoseconds
		let hit = LocaleData.languageAliases["iw"]
		let t1 = DispatchTime.now().uptimeNanoseconds
		XCTAssertEqual(hit, "he")
		report("languageAliases COLD (first lookup)", ns: t1 - t0, iters: 1)
	}

	func testLanguageAliasesWarm() {
		_ = LocaleData.languageAliases["iw"]
		let keys = ["iw", "in", "sh", "ji", "mo", "scc", "scr", "tl", "no", "und"]
		let n = 1_000_000
		var sink = 0
		let t0 = DispatchTime.now().uptimeNanoseconds
		for i in 0..<n {
			if LocaleData.languageAliases[keys[i % keys.count]] != nil { sink &+= 1 }
		}
		let t1 = DispatchTime.now().uptimeNanoseconds
		XCTAssertGreaterThan(sink, 0)
		report("languageAliases WARM (1M lookups)", ns: t1 - t0, iters: n)
	}

	// MARK: - helpers

	private func report(_ label: String, ns: UInt64, iters: Int) {
		let totalMs = Double(ns) / 1_000_000.0
		let perCallNs = Double(ns) / Double(iters)
		print(String(format: "BENCH | %@ | total=%.3f ms | per-call=%.1f ns | iters=%d", label, totalMs, perCallNs, iters))
	}
}
