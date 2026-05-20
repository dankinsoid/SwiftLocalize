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
		// Dev-only generator. Not exposed as a product — consumers of the library never build it.
		// Run: `swift run GeneratePluralRules <plurals.json> [<ordinals.json>] [<output.swift>]`.
		.executableTarget(
			name: "GeneratePluralRules",
			path: "Scripts/GeneratePluralRules"
		),
		// Dev-only generator for locale-negotiation tables (likely subtags, parent locales, aliases).
		// Run: `swift run GenerateLocaleData <likelySubtags.json> <parentLocales.json> <aliases.json> [<output.swift>]`.
		.executableTarget(
			name: "GenerateLocaleData",
			path: "Scripts/GenerateLocaleData"
		),
		// Dev-only generator for `Language` static constants (one per ISO 639-1 code).
		// Run: `swift run GenerateLanguageConstants <likelySubtags.json> [<output.swift>]`.
		.executableTarget(
			name: "GenerateLanguageConstants",
			path: "Scripts/GenerateLanguageConstants"
		),
	]
)
