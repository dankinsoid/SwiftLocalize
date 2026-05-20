// @ai-generated(guided)
//
// Generate Sources/SwiftLocalize/PluralRange+Generated.swift from CLDR JSON.
//
// Usage:
//   swift run GeneratePluralRanges [<pluralRanges.json|URL>] [<output.swift>]
//
// Source data: https://github.com/unicode-org/cldr-json
//   cldr-core/supplemental/pluralRanges.json
//
// With no source path, fetches `pluralRanges.json` live from the CLDR JSON repo
// (branch defaults to `main`; override via `CLDR_BRANCH`). Pass a local file
// path or HTTP URL to pin a specific snapshot.
//
// The CLDR file is keyed by primary language only (`ru`, `de`, …) — no
// region/script variants — so the generated table uses the primary subtag as
// its key and lookup at runtime is a single dictionary hit on `language.language`.

import Foundation

// MARK: - CLDR source

let cldrBranch = ProcessInfo.processInfo.environment["CLDR_BRANCH"] ?? "main"
let cldrBase = "https://raw.githubusercontent.com/unicode-org/cldr-json/\(cldrBranch)/cldr-json"

// MARK: - Args

let argv = CommandLine.arguments
let positional = Array(argv.dropFirst()).filter { !$0.hasPrefix("-") }

let inputArg: String? = positional.count >= 1 ? positional[0] : nil
let outputPath: String = positional.count >= 2
	? positional[1]
	: "Sources/SwiftLocalize/PluralRange+Generated.swift"

// MARK: - JSON helpers

func loadJSON(from data: Data, hint: String) throws -> [String: Any] {
	guard let obj = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
		throw NSError(domain: "GeneratePluralRanges", code: 1, userInfo: [
			NSLocalizedDescriptionKey: "Not a JSON object: \(hint)",
		])
	}
	return obj
}

func dict(_ any: Any?) -> [String: Any] { (any as? [String: Any]) ?? [:] }

// MARK: - Load

func loadData(from arg: String?) -> Data {
	if let arg {
		if let url = URL(string: arg), url.scheme == "http" || url.scheme == "https" {
			FileHandle.standardError.write(Data("fetching \(url.absoluteString)\n".utf8))
			do { return try Data(contentsOf: url) } catch {
				FileHandle.standardError.write(Data("failed to fetch \(url): \(error.localizedDescription)\n".utf8))
				exit(1)
			}
		}
		do {
			return try Data(contentsOf: URL(fileURLWithPath: arg))
		} catch {
			FileHandle.standardError.write(Data("failed to read \(arg): \(error.localizedDescription)\n".utf8))
			exit(1)
		}
	}
	let url = URL(string: "\(cldrBase)/cldr-core/supplemental/pluralRanges.json")!
	FileHandle.standardError.write(Data("fetching \(url.absoluteString)\n".utf8))
	do { return try Data(contentsOf: url) } catch {
		FileHandle.standardError.write(Data("failed to fetch pluralRanges.json: \(error.localizedDescription)\n".utf8))
		exit(1)
	}
}

let data = loadData(from: inputArg)

let root: [String: Any]
do {
	root = try loadJSON(from: data, hint: "pluralRanges.json")
} catch {
	FileHandle.standardError.write(Data("parse failed: \(error.localizedDescription)\n".utf8))
	exit(1)
}

// MARK: - Collect
//
// CLDR shape:
//   supplemental.plurals.<lang>["pluralRange-start-<X>-end-<Y>"] = "<result>"
//
// where X, Y, result ∈ { zero, one, two, few, many, other }. We collapse each
// language's flat key/value map into a nested (start → end → result) table so
// that the emitted Swift literal reads close to the conceptual 2D function.

let supplemental = dict(root["supplemental"])
let plurals = dict(supplemental["plurals"])

/// Mirror of `PluralCategory` raw values. Future CLDR additions are flagged here
/// so the generator fails loud rather than silently emitting a category that
/// won't compile against the current `PluralCategory` enum.
let known: Set<String> = ["zero", "one", "two", "few", "many", "other"]

/// Parse a key of the form `pluralRange-start-X-end-Y` into `(X, Y)`. Returns
/// `nil` for unrelated keys so the caller can skip them.
func parseKey(_ k: String) -> (start: String, end: String)? {
	let prefix = "pluralRange-start-"
	let infix = "-end-"
	guard k.hasPrefix(prefix) else { return nil }
	let rest = k.dropFirst(prefix.count)
	guard let r = rest.range(of: infix) else { return nil }
	return (String(rest[..<r.lowerBound]), String(rest[r.upperBound...]))
}

struct Row {
	let language: String
	// start → (end → result), sorted at emit time.
	var entries: [String: [String: String]]
}

var rows: [Row] = []

for (lang, value) in plurals {
	let table = (value as? [String: String]) ?? [:]
	var entries: [String: [String: String]] = [:]
	for (key, result) in table {
		guard let (start, end) = parseKey(key) else { continue }
		let cats = [start, end, result]
		let unknown = Set(cats).subtracting(known)
		if !unknown.isEmpty {
			FileHandle.standardError.write(Data(
				"error: \(lang).\(key) uses unknown category(ies) \(unknown.sorted()); update PluralCategory enum first\n".utf8
			))
			exit(1)
		}
		entries[start, default: [:]][end] = result
	}
	guard !entries.isEmpty else { continue }
	rows.append(Row(language: lang, entries: entries))
}

rows.sort { $0.language < $1.language }

// MARK: - Emit
//
// Stable category ordering for both outer and inner keys — alphabetic matches
// the order the CLDR JSON happens to iterate in, and keeps diffs readable when
// only one (start, end) pair changes between regenerations.
let order = ["zero", "one", "two", "few", "many", "other"]

var output = ""
output += "// @ai-generated(guided) — DO NOT EDIT BY HAND.\n"
output += "// Generated by Scripts/GeneratePluralRanges from CLDR data.\n"
output += "// Regenerate after CLDR updates:\n"
output += "//   swift run GeneratePluralRanges [<pluralRanges.json|URL>] [<output.swift>]\n"
output += "//\n"
output += "// Source: https://github.com/unicode-org/cldr-json (cldr-core/supplemental/pluralRanges.json)\n"
output += "import Foundation\n\n"

output += "internal enum PluralRangeData {\n\n"
output += "\t/// Category-of-range table per CLDR `pluralRanges.json`. Indexed by primary\n"
output += "\t/// BCP-47 subtag, then by the start endpoint's category, then by the end\n"
output += "\t/// endpoint's category. The result is the plural category to use for the\n"
output += "\t/// whole range — e.g. `ranges[\"ru\"]?[.one]?[.many] == .many` (\"1\\u{2013}5 яблок\").\n"
output += "\t///\n"
output += "\t/// Languages absent from this map have no CLDR range data; callers fall\n"
output += "\t/// back to the end endpoint's own plural category (UTS \\#35).\n"
output += "\tstatic let ranges: [String: [PluralCategory: [PluralCategory: PluralCategory]]] = [\n"
for row in rows {
	output += "\t\t\"\(row.language)\": [\n"
	for start in order where row.entries[start] != nil {
		let inner = row.entries[start]!
		let items = order.compactMap { end -> String? in
			guard let res = inner[end] else { return nil }
			return ".\(end): .\(res)"
		}.joined(separator: ", ")
		output += "\t\t\t.\(start): [\(items)],\n"
	}
	output += "\t\t],\n"
}
output += "\t]\n"
output += "}\n"

try output.write(to: URL(fileURLWithPath: outputPath), atomically: true, encoding: .utf8)
print("wrote \(outputPath): languages=\(rows.count)")
