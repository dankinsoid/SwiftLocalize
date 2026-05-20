// @ai-generated(guided)
//
// Generate Sources/SwiftLocalize/LocaleData+Generated.swift from CLDR JSON.
//
// Usage:
//   swift run GenerateLocaleData [<likelySubtags.json|URL> <parentLocales.json|URL> <aliases.json|URL>] [<output.swift>]
//
// Source data: https://github.com/unicode-org/cldr-json
//   cldr-core/supplemental/likelySubtags.json
//   cldr-core/supplemental/parentLocales.json
//   cldr-core/supplemental/aliases.json
//
// With no source paths, the three files are fetched live from the CLDR JSON
// repo (branch defaults to `main`; override via `CLDR_BRANCH`). Either supply
// all three sources or none — partial overrides are rejected.
//
// Output tables drive locale negotiation (see LocaleNegotiation):
//   - likelySubtags: maximal-form expansion, so `zh` matches `zh-Hans-CN` and `zh-TW` matches `zh-Hant`.
//   - parentLocales: non-trivial fallback chains (`en-AU → en-001 → en`, `es-AR → es-419 → es`).
//   - languageAliases / scriptAliases / regionAliases: replace deprecated subtags during canonicalization.
//
// CLDR uses `_` between subtags; we emit BCP-47 `-`. Multi-value alias replacements
// (e.g. `SU → "RU AM AZ ..."`) are reduced to the first token — that's what fluent-langneg does.

import Foundation

// MARK: - CLDR source

let cldrBranch = ProcessInfo.processInfo.environment["CLDR_BRANCH"] ?? "main"
let cldrBase = "https://raw.githubusercontent.com/unicode-org/cldr-json/\(cldrBranch)/cldr-json"

/// Read a JSON source as `Data`. Accepts either a local filesystem path or
/// an `http(s)://` URL.
func loadData(_ source: String) throws -> Data {
	if source.hasPrefix("http://") || source.hasPrefix("https://") {
		guard let url = URL(string: source) else {
			throw NSError(domain: "load", code: 1, userInfo: [NSLocalizedDescriptionKey: "bad URL: \(source)"])
		}
		FileHandle.standardError.write(Data("fetching \(source)\n".utf8))
		return try Data(contentsOf: url)
	}
	return try Data(contentsOf: URL(fileURLWithPath: source))
}

// MARK: - Args

let argv = CommandLine.arguments
let positional = Array(argv.dropFirst()).filter { !$0.hasPrefix("-") }

// All-or-nothing for source paths: mixing local + default-remote would be
// confusing (e.g. local likelySubtags but remote parentLocales pinning
// different CLDR versions). The output path remains independently optional.
let likelySource: String
let parentsSource: String
let aliasesSource: String
let outputPath: String

switch positional.count {
case 0:
	likelySource = "\(cldrBase)/cldr-core/supplemental/likelySubtags.json"
	parentsSource = "\(cldrBase)/cldr-core/supplemental/parentLocales.json"
	aliasesSource = "\(cldrBase)/cldr-core/supplemental/aliases.json"
	outputPath = "Sources/SwiftLocalize/LocaleData+Generated.swift"
case 1:
	likelySource = "\(cldrBase)/cldr-core/supplemental/likelySubtags.json"
	parentsSource = "\(cldrBase)/cldr-core/supplemental/parentLocales.json"
	aliasesSource = "\(cldrBase)/cldr-core/supplemental/aliases.json"
	outputPath = positional[0]
case 3, 4:
	likelySource = positional[0]
	parentsSource = positional[1]
	aliasesSource = positional[2]
	outputPath = positional.count == 4 ? positional[3] : "Sources/SwiftLocalize/LocaleData+Generated.swift"
default:
	FileHandle.standardError.write(Data(
		"usage: swift run GenerateLocaleData [<likelySubtags.json|URL> <parentLocales.json|URL> <aliases.json|URL>] [<output.swift>]\n".utf8
	))
	exit(2)
}

// MARK: - JSON helpers

func loadJSON(_ source: String) throws -> [String: Any] {
	let data = try loadData(source)
	guard let obj = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
		throw NSError(domain: "GenerateLocaleData", code: 1, userInfo: [
			NSLocalizedDescriptionKey: "Not a JSON object: \(source)",
		])
	}
	return obj
}

func dict(_ any: Any?) -> [String: Any] { (any as? [String: Any]) ?? [:] }
func str(_ any: Any?) -> String? { any as? String }

/// `aa_Arab_ET` → `aa-Arab-ET`.
func bcp47(_ tag: String) -> String { tag.replacingOccurrences(of: "_", with: "-") }

/// First whitespace-separated token. CLDR uses space-joined lists for ambiguous
/// territory replacements (`SU → "RU AM AZ ..."`); fluent-langneg picks the first.
func firstToken(_ s: String) -> String {
	s.split(whereSeparator: { $0.isWhitespace }).first.map(String.init) ?? s
}

// MARK: - likelySubtags

let likelyRoot = try loadJSON(likelySource)
let likelyRaw = dict(dict(likelyRoot["supplemental"])["likelySubtags"])
var likelyPairs: [(String, String)] = []
for (k, v) in likelyRaw {
	guard let v = str(v) else { continue }
	likelyPairs.append((bcp47(k), bcp47(v)))
}
likelyPairs.sort { $0.0 < $1.0 }

// MARK: - parentLocales

let parentsRoot = try loadJSON(parentsSource)
let parentsRaw = dict(dict(dict(parentsRoot["supplemental"])["parentLocales"])["parentLocale"])
var parentPairs: [(String, String)] = []
for (k, v) in parentsRaw {
	guard let v = str(v) else { continue }
	parentPairs.append((bcp47(k), bcp47(v)))
}
parentPairs.sort { $0.0 < $1.0 }

// MARK: - aliases

let aliasesRoot = try loadJSON(aliasesSource)
let aliasBlock = dict(dict(dict(aliasesRoot["supplemental"])["metadata"])["alias"])

func collectAliases(_ key: String) -> [(String, String)] {
	let raw = dict(aliasBlock[key])
	var out: [(String, String)] = []
	for (k, v) in raw {
		guard let replacement = str(dict(v)["_replacement"]) else { continue }
		let picked = firstToken(replacement)
		if picked.isEmpty { continue }
		out.append((bcp47(k), bcp47(picked)))
	}
	out.sort { $0.0 < $1.0 }
	return out
}

let languageAliases = collectAliases("languageAlias")
let scriptAliases = collectAliases("scriptAlias")
let regionAliases = collectAliases("territoryAlias")

// MARK: - Emit

func swiftLiteral(_ s: String) -> String {
	// Tags only contain ASCII letters, digits, and `-`. No escaping needed beyond quoting.
	"\"" + s + "\""
}

func emitTable(_ name: String, _ doc: String, _ pairs: [(String, String)]) -> String {
	var s = "\t/// \(doc)\n"
	s += "\tstatic let \(name): [String: String] = [\n"
	for (k, v) in pairs {
		s += "\t\t\(swiftLiteral(k)): \(swiftLiteral(v)),\n"
	}
	s += "\t]\n"
	return s
}

var output = ""
output += "// @ai-generated(guided) — DO NOT EDIT BY HAND.\n"
output += "// Generated by Scripts/GenerateLocaleData from CLDR data.\n"
output += "// Regenerate after CLDR updates:\n"
output += "//   swift run GenerateLocaleData [<likelySubtags.json|URL> <parentLocales.json|URL> <aliases.json|URL>] [<output.swift>]\n"
output += "//\n"
output += "// Source: https://github.com/unicode-org/cldr-json (cldr-core/supplemental/)\n"
output += "import Foundation\n\n"

output += "internal enum LocaleData {\n\n"
output += emitTable(
	"likelySubtags",
	"Maximal-form expansion. \"zh\" → \"zh-Hans-CN\", \"zh-TW\" → \"zh-Hant-TW\".",
	likelyPairs
)
output += "\n"
output += emitTable(
	"parentLocales",
	"Non-trivial parent chains. \"en-AU\" → \"en-001\", \"es-AR\" → \"es-419\". Plain trim-last-subtag covers the rest.",
	parentPairs
)
output += "\n"
output += emitTable(
	"languageAliases",
	"Deprecated language-subtag replacements. \"iw\" → \"he\", \"in\" → \"id\", \"sh\" → \"sr-Latn\".",
	languageAliases
)
output += "\n"
output += emitTable(
	"scriptAliases",
	"Deprecated script-subtag replacements. \"Qaai\" → \"Zinh\".",
	scriptAliases
)
output += "\n"
output += emitTable(
	"regionAliases",
	"Deprecated region-subtag replacements. \"BU\" → \"MM\", \"SU\" → \"RU\" (first of CLDR's ordered list).",
	regionAliases
)
output += "}\n"

try output.write(to: URL(fileURLWithPath: outputPath), atomically: true, encoding: .utf8)
print("wrote \(outputPath): " +
      "likelySubtags=\(likelyPairs.count), " +
      "parentLocales=\(parentPairs.count), " +
      "languageAliases=\(languageAliases.count), " +
      "scriptAliases=\(scriptAliases.count), " +
      "regionAliases=\(regionAliases.count)")
