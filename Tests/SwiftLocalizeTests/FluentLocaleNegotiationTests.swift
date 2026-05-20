// @ai-generated(solo)
@testable import SwiftLocalize
import XCTest

/// Tests for CLDR-driven locale negotiation: canonicalization (aliases),
/// maximization (likely subtags), parent chains (parentLocales + region trimming),
/// and the high-level `LocaleNegotiation.matching` algorithm wired into
/// `LocalizedBundle`.
final class FluentLocaleNegotiationTests: XCTestCase {

	// MARK: Tag subtag parsing

	func test_tag_parses_language_script_region_from_three_subtag_tag() {
		let t: Fluent.Tag = "zh-Hant-TW"
		XCTAssertEqual(t.language, "zh")
		XCTAssertEqual(t.script, "Hant")
		XCTAssertEqual(t.region, "TW")
	}

	func test_tag_handles_numeric_region() {
		let t: Fluent.Tag = "es-419"
		XCTAssertEqual(t.language, "es")
		XCTAssertNil(t.script)
		XCTAssertEqual(t.region, "419")
	}

	// MARK: Canonicalization

	func test_canonical_replaces_deprecated_language_subtag() {
		// `iw` is the deprecated code for Hebrew.
		XCTAssertEqual(Fluent.Tag("iw").canonical, Fluent.Tag("he"))
		// `in` is the deprecated code for Indonesian.
		XCTAssertEqual(Fluent.Tag("in").canonical, Fluent.Tag("id"))
	}

	func test_canonical_replaces_deprecated_region_subtag() {
		// `BU` is the deprecated code for Myanmar (now `MM`).
		XCTAssertEqual(Fluent.Tag("my-BU").canonical, Fluent.Tag("my-MM"))
	}

	func test_canonical_preserves_already_canonical_tag() {
		XCTAssertEqual(Fluent.Tag("en-US").canonical, Fluent.Tag("en-US"))
		XCTAssertEqual(Fluent.Tag("zh-Hant-TW").canonical, Fluent.Tag("zh-Hant-TW"))
	}

	// MARK: Maximization (likely subtags)

	func test_maximize_fills_in_script_for_zh_TW() {
		// CLDR likely subtags: zh-TW → zh-Hant-TW. This is the core kase
		// the whole feature exists for.
		XCTAssertEqual(Fluent.Tag("zh-TW").maximized, Fluent.Tag("zh-Hant-TW"))
	}

	func test_maximize_fills_in_script_and_region_for_bare_language() {
		// CLDR likely subtags: zh → zh-Hans-CN.
		XCTAssertEqual(Fluent.Tag("zh").maximized, Fluent.Tag("zh-Hans-CN"))
		// en → en-Latn-US.
		XCTAssertEqual(Fluent.Tag("en").maximized, Fluent.Tag("en-Latn-US"))
	}

	func test_maximize_preserves_explicit_subtags() {
		// en-GB has likely "en-Latn-GB"; we keep GB and gain Latn.
		XCTAssertEqual(Fluent.Tag("en-GB").maximized, Fluent.Tag("en-Latn-GB"))
	}

	// MARK: Parent chains

	func test_parent_uses_parentLocales_for_english_world_variants() {
		// CLDR parentLocales: en-AU → en-001 → en.
		XCTAssertEqual(Fluent.Tag("en-AU").parent, Fluent.Tag("en-001"))
		XCTAssertEqual(Fluent.Tag("en-001").parent, Fluent.Tag("en"))
	}

	func test_parent_uses_parentLocales_for_spanish_latam() {
		// CLDR parentLocales: es-AR → es-419 → es.
		XCTAssertEqual(Fluent.Tag("es-AR").parent, Fluent.Tag("es-419"))
		XCTAssertEqual(Fluent.Tag("es-419").parent, Fluent.Tag("es"))
	}

	func test_parent_drops_region_when_not_in_parentLocales() {
		XCTAssertEqual(Fluent.Tag("ru-RU").parent, Fluent.Tag("ru"))
		XCTAssertEqual(Fluent.Tag("fr-CA").parent, Fluent.Tag("fr"))
	}

	func test_parent_at_bare_language_returns_nil() {
		XCTAssertNil(Fluent.Tag("en").parent)
		XCTAssertNil(Fluent.Tag("ru").parent)
	}

	func test_parent_drops_default_script_only() {
		// Cyrl is sr's default script → sr-Cyrl strips to sr.
		XCTAssertEqual(Fluent.Tag("sr-Cyrl").parent, Fluent.Tag("sr"))
		// Latn is NOT sr's default → sr-Latn has no parent (stripping changes meaning).
		XCTAssertNil(Fluent.Tag("sr-Latn").parent)
	}

	// MARK: Negotiation — matching strategy

	func test_matching_finds_zh_Hant_for_requested_zh_TW() {
		let chain = LocaleNegotiation.matching(
			requested: ["zh-TW"],
			available: ["en", "zh-Hans", "zh-Hant"],
			default: "en"
		)
		XCTAssertEqual(chain.first, Fluent.Tag("zh-Hant"))
		XCTAssertEqual(chain.last, Fluent.Tag("en"))
	}

	func test_matching_finds_zh_Hans_for_requested_zh_CN() {
		let chain = LocaleNegotiation.matching(
			requested: ["zh-CN"],
			available: ["en", "zh-Hans", "zh-Hant"],
			default: "en"
		)
		XCTAssertEqual(chain.first, Fluent.Tag("zh-Hans"))
	}

	func test_matching_walks_parent_chain_for_es_AR() {
		// es-AR has no direct match; parent is es-419, then es. Available has only `es`.
		let chain = LocaleNegotiation.matching(
			requested: ["es-AR"],
			available: ["en", "es"]
		)
		XCTAssertEqual(chain.first, Fluent.Tag("es"))
	}

	func test_matching_resolves_deprecated_alias() {
		// `iw` is the deprecated tag for Hebrew. Available has `he`.
		let chain = LocaleNegotiation.matching(
			requested: ["iw"],
			available: ["en", "he"],
			default: "en"
		)
		XCTAssertEqual(chain.first, Fluent.Tag("he"))
	}

	func test_matching_default_appended_only_when_missing() {
		let chain = LocaleNegotiation.matching(
			requested: ["fr"],
			available: ["en", "ru"],
			default: "en"
		)
		// fr has no match → only the default ends up in the chain.
		XCTAssertEqual(chain, [Fluent.Tag("en")])
	}

	func test_matching_default_not_duplicated_when_already_matched() {
		let chain = LocaleNegotiation.matching(
			requested: ["en-US"],
			available: ["en", "ru"],
			default: "en"
		)
		XCTAssertEqual(chain, [Fluent.Tag("en")])
	}

	func test_matching_preserves_request_priority_order() {
		let chain = LocaleNegotiation.matching(
			requested: ["fr", "de", "ru"],
			available: ["en", "ru", "de", "fr"],
			default: "en"
		)
		XCTAssertEqual(chain, [Fluent.Tag("fr"), Fluent.Tag("de"), Fluent.Tag("ru"), Fluent.Tag("en")])
	}

	// MARK: LocalizedBundle integration

	func test_localizedBundle_falls_back_through_negotiation() {
		var lb = Fluent.LocalizedBundle(fallbackChain: ["en"])

		var en = Fluent.Bundle(locale: "en", useIsolating: false)
		en.add(Fluent.Message(id: "hi", value: Fluent.Pattern([.text("Hello")])))
		lb.add(bundle: en)

		var zhHant = Fluent.Bundle(locale: "zh-Hant", useIsolating: false)
		zhHant.add(Fluent.Message(id: "hi", value: Fluent.Pattern([.text("你好")])))
		lb.add(bundle: zhHant)

		// User requests `zh-TW` → CLDR maps to `zh-Hant`.
		XCTAssertEqual(lb.format("hi", language: "zh-TW"), "你好")
		// User requests `zh-CN` → no `zh-Hans` available → falls through to `en`.
		XCTAssertEqual(lb.format("hi", language: "zh-CN"), "Hello")
	}

	func test_localizedValue_resolves_via_negotiation() {
		let flag: Fluent.Localized<String> = [
			"en": "🇬🇧",
			"zh-Hant": "🇹🇼",
			"zh-Hans": "🇨🇳",
		]
		XCTAssertEqual(flag(language: "zh-TW"), "🇹🇼")
		XCTAssertEqual(flag(language: "zh-CN"), "🇨🇳")
		// `iw` → canonicalizes to `he` → not in variants → falls through to first match priority
		// (default is empty, so first variant wins as a last resort).
		XCTAssertNotNil(flag(language: "iw"))
	}
}
