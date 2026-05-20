// swift-tools-version:5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
	name: "SwiftLocalize",
	products: [
		// Products define the executables and libraries produced by a package, and make them visible to other packages.
		.library(
			name: "SwiftLocalize",
			targets: ["SwiftLocalize"]
		),
	],
	dependencies: [
		// Dependencies declare other packages that this package depends on.
		// .package(url: /* package url */, from: "1.0.0"),
	],
	targets: [
		// Targets are the basic building blocks of a package. A target can define a module or a test suite.
		// Targets can depend on other targets in this package, and on products in packages which this package depends on.
		.target(
			name: "SwiftLocalize",
			dependencies: []
		),
		.testTarget(
			name: "SwiftLocalizeTests",
			dependencies: ["SwiftLocalize"]
		),
		// Dev-only generators. Not exposed as products — consumers of the library never build them.
		// Each defaults to fetching CLDR data live from https://github.com/unicode-org/cldr-json
		// (branch `main`, override via `CLDR_BRANCH`); pass paths/URLs to use a pinned snapshot.
		//
		// Run: `swift run GeneratePluralRules [<plurals.json|URL> [<ordinals.json|URL>]] [<output.swift>]`.
		.executableTarget(
			name: "GeneratePluralRules",
			path: "Scripts/GeneratePluralRules"
		),
		// Dev-only generator for locale-negotiation tables (likely subtags, parent locales, aliases).
		// Run: `swift run GenerateLocaleData [<likelySubtags.json|URL> <parentLocales.json|URL> <aliases.json|URL>] [<output.swift>]`.
		.executableTarget(
			name: "GenerateLocaleData",
			path: "Scripts/GenerateLocaleData"
		),
		// Dev-only generator for `Language` static constants (one per ISO 639-1 code).
		// Run: `swift run GenerateLanguageConstants [<likelySubtags.json|URL>] [<output.swift>]`.
		.executableTarget(
			name: "GenerateLanguageConstants",
			path: "Scripts/GenerateLanguageConstants"
		),
		// Dev-only generator for per-locale quotation marks (primary + alternate).
		// Run: `swift run GenerateDelimiters [<cldr-misc-main-dir>] [<output.swift>]`.
		.executableTarget(
			name: "GenerateDelimiters",
			path: "Scripts/GenerateDelimiters"
		),
		// Dev-only generator for per-locale numeric range patterns ("{0}–{1}" etc).
		// Run: `swift run GenerateRangePatterns [<cldr-numbers-main-dir>] [<output.swift>]`.
		.executableTarget(
			name: "GenerateRangePatterns",
			path: "Scripts/GenerateRangePatterns"
		),
		// Dev-only generator for per-language grammatical gender sets (masculine/feminine/…).
		// Run: `swift run GenerateGrammaticalGender [<grammaticalFeatures.json|URL>] [<output.swift>]`.
		.executableTarget(
			name: "GenerateGrammaticalGender",
			path: "Scripts/GenerateGrammaticalGender"
		),
		// Dev-only generator for per-language plural-range result tables
		// ((start_cat, end_cat) → result_cat, e.g. ru: one+many → many).
		// Run: `swift run GeneratePluralRanges [<pluralRanges.json|URL>] [<output.swift>]`.
		.executableTarget(
			name: "GeneratePluralRanges",
			path: "Scripts/GeneratePluralRanges"
		),
	]
)
