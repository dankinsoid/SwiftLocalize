// @ai-generated(guided)
//
// Generate Sources/SwiftLocalize/Delimiters+Generated.swift from CLDR JSON.
//
// Usage:
//   swift run GenerateDelimiters [<cldr-misc-main-dir>] [<output.swift>]
//
// Source data: https://github.com/unicode-org/cldr-json
//   cldr-misc-full/main/<locale>/delimiters.json
//
// `<cldr-misc-main-dir>` is the `main/` directory of the `cldr-misc-full`
// package — one subdirectory per locale, each containing `delimiters.json`.
//
// With no source directory, the script enumerates locales from
// `cldr-core/availableLocales.json` and fetches each `delimiters.json` live
// from the CLDR JSON repo (branch defaults to `main`; override via
// `CLDR_BRANCH`). Locales without a `delimiters.json` (HTTP 404) are skipped,
// matching the local-mode behaviour of skipping directories without one.
//
// CLDR ships pre-resolved values per locale (inherited fields are filled in),
// so we emit every locale that has a `delimiters.json`. Runtime lookup is a
// single dictionary hit; missing tags fall back through the existing CLDR
// parent chain via `LocaleNegotiation` and ultimately to `root`.

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
	: "Sources/SwiftLocalize/Delimiters+Generated.swift"

// MARK: - JSON helpers

func loadJSON(from data: Data, hint: String) throws -> [String: Any] {
	guard let obj = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
		throw NSError(domain: "GenerateDelimiters", code: 1, userInfo: [
			NSLocalizedDescriptionKey: "Not a JSON object: \(hint)",
		])
	}
	return obj
}

func dict(_ any: Any?) -> [String: Any] { (any as? [String: Any]) ?? [:] }
func str(_ any: Any?) -> String? { any as? String }

/// `aa_Arab_ET` → `aa-Arab-ET`. CLDR JSON keys are already hyphen-separated for
/// locale directories, but the `identity` subobject sometimes uses underscores
/// — normalize unconditionally to be safe.
func bcp47(_ tag: String) -> String { tag.replacingOccurrences(of: "_", with: "-") }

// MARK: - Source iteration
//
// Each source mode (filesystem dir vs. remote repo) collects raw
// `delimiters.json` payloads keyed by locale. Parsing the CLDR shape and
// extracting the four delimiter strings is shared logic downstream.

struct Delimiters {
	let quotationStart: String
	let quotationEnd: String
	let alternateQuotationStart: String
	let alternateQuotationEnd: String
}

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
		let delimitersPath = entry.appendingPathComponent("delimiters.json").path
		guard fm.fileExists(atPath: delimitersPath) else { continue }
		do {
			let data = try Data(contentsOf: URL(fileURLWithPath: delimitersPath))
			out.append((entry.lastPathComponent, data))
		} catch {
			FileHandle.standardError.write(Data(
				"skipping \(delimitersPath): \(error.localizedDescription)\n".utf8
			))
		}
	}
	return out
}

func collectFromRemote() -> [(locale: String, data: Data)] {
	// Locale catalog: `cldr-core` ships the canonical list; `cldr-misc-full`
	// doesn't expose its own `availableLocales.json`, but is a superset, so
	// any locale in the core list that lacks a `delimiters.json` simply 404s
	// and is skipped — the same fate as a missing file in the local mode.
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
		"fetching delimiters.json for \(locales.count) locales from \(cldrBase)/cldr-misc-full/main/<locale>/delimiters.json\n".utf8
	))

	// Parallel fetch — sequential I/O against 766 locales takes ~2 minutes;
	// `concurrentPerform` saturates the CPU's GCD worker pool which gives
	// ~enough concurrency to bring this down to a handful of seconds without
	// hammering GitHub Raw hard enough to get rate-limited.
	let lock = NSLock()
	var results: [(String, Data)] = []
	var notFound = 0
	var failed = 0
	DispatchQueue.concurrentPerform(iterations: locales.count) { idx in
		let locale = locales[idx]
		let url = URL(string: "\(cldrBase)/cldr-misc-full/main/\(locale)/delimiters.json")!
		do {
			let data = try Data(contentsOf: url)
			lock.lock(); results.append((locale, data)); lock.unlock()
		} catch {
			// `Data(contentsOf:)` reports 404 as an NSURLErrorFileDoesNotExist
			// or as a network error depending on platform; either way the
			// locale just isn't in cldr-misc-full and is skipped.
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
		"fetched=\(results.count) no-delimiters=\(notFound) failed=\(failed)\n".utf8
	))
	return results
}

let payloads = mainDir.map(collectFromFilesystem) ?? collectFromRemote()

// MARK: - Collect

var rows: [(tag: String, delimiters: Delimiters)] = []

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

	// `main.<locale>.delimiters` — there's exactly one locale key under "main",
	// matching the directory name. Reading the JSON key (not the dir name)
	// preserves CLDR's canonical identifier in case the two ever diverge.
	let main = dict(root["main"])
	guard let (rawTag, body) = main.first else { continue }
	let d = dict(dict(body)["delimiters"])
	guard
		let qs = str(d["quotationStart"]),
		let qe = str(d["quotationEnd"]),
		let aqs = str(d["alternateQuotationStart"]),
		let aqe = str(d["alternateQuotationEnd"])
	else { continue }

	rows.append((bcp47(rawTag), Delimiters(
		quotationStart: qs,
		quotationEnd: qe,
		alternateQuotationStart: aqs,
		alternateQuotationEnd: aqe
	)))
}

rows.sort { $0.tag < $1.tag }

// MARK: - Emit

/// Escape each unicode scalar as `\u{XXXX}`. Delimiters are typically a single
/// codepoint (`«` U+00AB, `「` U+300C, …), so escapes stay short. Using escapes
/// keeps the generated file ASCII-only — safer to diff and editor-agnostic.
func unicodeEscaped(_ s: String) -> String {
	var out = "\""
	for scalar in s.unicodeScalars {
		out += String(format: "\\u{%04X}", scalar.value)
	}
	out += "\""
	return out
}

/// Inline comment showing the actual glyphs — escapes alone are hard to eyeball.
func displayChars(_ d: Delimiters) -> String {
	"\(d.quotationStart)…\(d.quotationEnd)  \(d.alternateQuotationStart)…\(d.alternateQuotationEnd)"
}

var output = ""
output += "// @ai-generated(guided) — DO NOT EDIT BY HAND.\n"
output += "// Generated by Scripts/GenerateDelimiters from CLDR data.\n"
output += "// Regenerate after CLDR updates:\n"
output += "//   swift run GenerateDelimiters [<cldr-misc-main-dir>] [<output.swift>]\n"
output += "//\n"
output += "// Source: https://github.com/unicode-org/cldr-json (cldr-misc-full/main/<locale>/delimiters.json)\n"
output += "import Foundation\n\n"

output += "internal enum DelimiterData {\n\n"
output += "\t/// Quotation marks per locale: primary pair (`start`/`end`) and alternate\n"
output += "\t/// pair (`altStart`/`altEnd`) for nesting. Verbatim from CLDR's\n"
output += "\t/// `delimiters.json`. Missing locales fall back via `LocaleNegotiation`\n"
output += "\t/// down to `root`.\n"
output += "\tstatic let quotes: [String: (start: String, end: String, altStart: String, altEnd: String)] = [\n"
for (tag, d) in rows {
	output += "\t\t\"\(tag)\": ("
	output += unicodeEscaped(d.quotationStart) + ", "
	output += unicodeEscaped(d.quotationEnd) + ", "
	output += unicodeEscaped(d.alternateQuotationStart) + ", "
	output += unicodeEscaped(d.alternateQuotationEnd)
	output += "), // \(displayChars(d))\n"
}
output += "\t]\n"
output += "}\n"

try output.write(to: URL(fileURLWithPath: outputPath), atomically: true, encoding: .utf8)
print("wrote \(outputPath): quotes=\(rows.count)")
