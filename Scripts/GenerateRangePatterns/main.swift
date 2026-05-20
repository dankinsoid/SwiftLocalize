// @ai-generated(guided)
//
// Generate Sources/SwiftLocalize/RangePatterns+Generated.swift from CLDR JSON.
//
// Usage:
//   swift run GenerateRangePatterns [<cldr-numbers-main-dir>] [<output.swift>]
//
// Source data: https://github.com/unicode-org/cldr-json
//   cldr-numbers-full/main/<locale>/numbers.json
//     → main.<locale>.numbers["miscPatterns-numberSystem-<sys>"].range
//
// `<cldr-numbers-main-dir>` is the `main/` directory of `cldr-numbers-full` —
// one subdirectory per locale, each containing `numbers.json`.
//
// With no source directory, the script enumerates locales from
// `cldr-core/availableLocales.json` and fetches each `numbers.json` live from
// the CLDR JSON repo (branch defaults to `main`; override via `CLDR_BRANCH`).
// Locales without a `numbers.json` (HTTP 404) are skipped.
//
// We extract the `range` pattern under `miscPatterns-numberSystem-latn` —
// the visual separator is a property of the locale's typography, identical
// across numbering systems within a locale (verified empirically in CLDR
// 44/45). If `latn` is absent, falls back to whichever `miscPatterns-…`
// block is present.

import Foundation

// MARK: - CLDR source

let cldrBranch = ProcessInfo.processInfo.environment["CLDR_BRANCH"] ?? "main"
let cldrBase = "https://raw.githubusercontent.com/unicode-org/cldr-json/\(cldrBranch)/cldr-json"

// MARK: - Args

let argv = CommandLine.arguments
let positional = Array(argv.dropFirst()).filter { !$0.hasPrefix("-") }

let mainDir: String? = positional.count >= 1 ? positional[0] : nil
let outputPath: String = positional.count >= 2
	? positional[1]
	: "Sources/SwiftLocalize/RangePatterns+Generated.swift"

// MARK: - JSON helpers

func loadJSON(from data: Data, hint: String) throws -> [String: Any] {
	guard let obj = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
		throw NSError(domain: "GenerateRangePatterns", code: 1, userInfo: [
			NSLocalizedDescriptionKey: "Not a JSON object: \(hint)",
		])
	}
	return obj
}

func dict(_ any: Any?) -> [String: Any] { (any as? [String: Any]) ?? [:] }
func str(_ any: Any?) -> String? { any as? String }

func bcp47(_ tag: String) -> String { tag.replacingOccurrences(of: "_", with: "-") }

// MARK: - Source iteration

func collectFromFilesystem(_ dir: String) -> [(locale: String, data: Data)] {
	let fm = FileManager.default
	let mainURL = URL(fileURLWithPath: dir)
	let localeDirs: [URL]
	do {
		localeDirs = try fm.contentsOfDirectory(
			at: mainURL,
			includingPropertiesForKeys: [.isDirectoryKey],
			options: [.skipsHiddenFiles]
		)
	} catch {
		FileHandle.standardError.write(Data(
			"failed to list \(dir): \(error.localizedDescription)\n".utf8
		))
		exit(1)
	}
	var out: [(String, Data)] = []
	for entry in localeDirs {
		var isDir: ObjCBool = false
		guard fm.fileExists(atPath: entry.path, isDirectory: &isDir), isDir.boolValue else { continue }
		let numbersPath = entry.appendingPathComponent("numbers.json").path
		guard fm.fileExists(atPath: numbersPath) else { continue }
		do {
			let data = try Data(contentsOf: URL(fileURLWithPath: numbersPath))
			out.append((entry.lastPathComponent, data))
		} catch {
			FileHandle.standardError.write(Data(
				"skipping \(numbersPath): \(error.localizedDescription)\n".utf8
			))
		}
	}
	return out
}

func collectFromRemote() -> [(locale: String, data: Data)] {
	let availableURL = URL(string: "\(cldrBase)/cldr-core/availableLocales.json")!
	FileHandle.standardError.write(Data("fetching \(availableURL.absoluteString)\n".utf8))
	let availableData: Data
	do {
		availableData = try Data(contentsOf: availableURL)
	} catch {
		FileHandle.standardError.write(Data(
			"failed to fetch availableLocales.json: \(error.localizedDescription)\n".utf8
		))
		exit(1)
	}
	let availableJSON = (try? JSONSerialization.jsonObject(with: availableData)) as? [String: Any] ?? [:]
	let avail = dict(availableJSON["availableLocales"])
	let locales = (avail["full"] as? [String]) ?? (avail["modern"] as? [String]) ?? []
	guard !locales.isEmpty else {
		FileHandle.standardError.write(Data("availableLocales.json had no locale list\n".utf8))
		exit(1)
	}

	FileHandle.standardError.write(Data(
		"fetching numbers.json for \(locales.count) locales from \(cldrBase)/cldr-numbers-full/main/<locale>/numbers.json\n".utf8
	))

	let lock = NSLock()
	var results: [(String, Data)] = []
	var notFound = 0
	var failed = 0
	DispatchQueue.concurrentPerform(iterations: locales.count) { idx in
		let locale = locales[idx]
		let url = URL(string: "\(cldrBase)/cldr-numbers-full/main/\(locale)/numbers.json")!
		do {
			let data = try Data(contentsOf: url)
			lock.lock(); results.append((locale, data)); lock.unlock()
		} catch {
			let nsErr = error as NSError
			let is404 = (nsErr.domain == NSURLErrorDomain && nsErr.code == NSURLErrorFileDoesNotExist)
				|| (nsErr.domain == NSCocoaErrorDomain && nsErr.code == NSFileReadNoSuchFileError)
			lock.lock()
			if is404 { notFound += 1 } else {
				failed += 1
				FileHandle.standardError.write(Data(
					"warn: fetching \(locale): \(error.localizedDescription)\n".utf8
				))
			}
			lock.unlock()
		}
	}
	FileHandle.standardError.write(Data(
		"fetched=\(results.count) no-numbers=\(notFound) failed=\(failed)\n".utf8
	))
	return results
}

let payloads = mainDir.map(collectFromFilesystem) ?? collectFromRemote()

// MARK: - Extract range patterns

/// Pull the `range` value out of a `numbers` block. Prefers `latn` since every
/// locale that has miscPatterns at all has them under `latn`; if absent (very
/// rare), takes the first `miscPatterns-numberSystem-*` block.
func extractRangePattern(_ numbers: [String: Any]) -> String? {
	if let r = str(dict(numbers["miscPatterns-numberSystem-latn"])["range"]) {
		return r
	}
	for (key, value) in numbers where key.hasPrefix("miscPatterns-numberSystem-") {
		if let r = str(dict(value)["range"]) { return r }
	}
	return nil
}

var rows: [(tag: String, pattern: String)] = []

for (localeHint, data) in payloads {
	let root: [String: Any]
	do {
		root = try loadJSON(from: data, hint: localeHint)
	} catch {
		FileHandle.standardError.write(Data(
			"skipping \(localeHint): \(error.localizedDescription)\n".utf8
		))
		continue
	}
	let main = dict(root["main"])
	guard let (rawTag, body) = main.first else { continue }
	let numbers = dict(dict(body)["numbers"])
	guard let pattern = extractRangePattern(numbers) else { continue }
	rows.append((bcp47(rawTag), pattern))
}

rows.sort { $0.tag < $1.tag }

// MARK: - Emit

/// Escape each unicode scalar as `\u{XXXX}`. Range separators are often a single
/// non-ASCII codepoint (`–` U+2013, `—` U+2014, `〜` U+301C) — escapes keep the
/// source file ASCII-only and editor-agnostic. The placeholder tokens `{0}`/`{1}`
/// stay as plain ASCII inside the escaped string.
func unicodeEscaped(_ s: String) -> String {
	var out = "\""
	for scalar in s.unicodeScalars {
		if scalar.isASCII, scalar.value >= 0x20, scalar.value < 0x7F, scalar != "\"", scalar != "\\" {
			out += String(scalar)
		} else {
			out += String(format: "\\u{%04X}", scalar.value)
		}
	}
	out += "\""
	return out
}

var output = ""
output += "// @ai-generated(guided) — DO NOT EDIT BY HAND.\n"
output += "// Generated by Scripts/GenerateRangePatterns from CLDR data.\n"
output += "// Regenerate after CLDR updates:\n"
output += "//   swift run GenerateRangePatterns [<cldr-numbers-main-dir>] [<output.swift>]\n"
output += "//\n"
output += "// Source: https://github.com/unicode-org/cldr-json (cldr-numbers-full/main/<locale>/numbers.json)\n"
output += "import Foundation\n\n"

output += "internal enum RangePatternData {\n\n"
output += "\t/// CLDR range-format pattern per locale, e.g. `\"{0}\\u{2013}{1}\"` for en\n"
output += "\t/// (\"2020–2025\") or `\"{0}\\u{2014}{1}\"` for ru (\"2020—2025\"). Lookup falls\n"
output += "\t/// back via `LocaleNegotiation` parent chain to `und`.\n"
output += "\tstatic let patterns: [String: String] = [\n"
for (tag, pattern) in rows {
	output += "\t\t\"\(tag)\": \(unicodeEscaped(pattern)), // \(pattern)\n"
}
output += "\t]\n"
output += "}\n"

try output.write(to: URL(fileURLWithPath: outputPath), atomically: true, encoding: .utf8)
print("wrote \(outputPath): patterns=\(rows.count)")
