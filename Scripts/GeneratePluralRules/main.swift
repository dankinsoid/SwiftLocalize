// @ai-generated(guided)
//
// Generate Sources/SwiftLocalize/Fluent/PluralRule+Generated.swift from CLDR JSON.
//
// Usage:
//   swift run GeneratePluralRules <plurals.json> [<ordinals.json>] [<output.swift>]
//
// Source data: https://github.com/unicode-org/cldr-json
//   cldr-core/supplemental/plurals.json
//   cldr-core/supplemental/ordinals.json
//
// The CLDR rule grammar we accept is a subset sufficient for the supplemental data:
//   condition  := and_cond ("or" and_cond)*
//   and_cond   := relation ("and" relation)*
//   relation   := operand ("%" int)? ("=" | "!=") range_list
//   range_list := range ("," range)*
//   range      := int (".." int)?
//   operand    := "n" | "i" | "v" | "w" | "f" | "t" | "e" | "c"
//
// The `@integer …` / `@decimal …` sample sections at the end of each rule are stripped
// before parsing. Operands we can't represent in a Double-only API (v/w/f/t/e/c) are
// treated as 0, except for the very common `v = 0` / `v != 0` idiom which is emitted as
// the `isInteger` flag.

import Foundation

// MARK: - Args

let argv = CommandLine.arguments

guard argv.count >= 2 else {
	FileHandle.standardError.write(Data(
		"usage: swift run GeneratePluralRules <plurals.json> [<ordinals.json>] [<output.swift>]\n".utf8
	))
	exit(2)
}

let pluralsPath = argv[1]
let ordinalsPath: String? = argv.count >= 3 ? argv[2] : nil
let outputPath = argv.count >= 4 ? argv[3] : "Sources/SwiftLocalize/Fluent/PluralRule+Generated.swift"

// MARK: - JSON loading

func loadCLDR(_ path: String, kind: String) throws -> [String: [String: String]] {
	let data = try Data(contentsOf: URL(fileURLWithPath: path))
	guard let root = try JSONSerialization.jsonObject(with: data) as? [String: Any],
	      let supp = root["supplemental"] as? [String: Any],
	      let table = supp["plurals-type-\(kind)"] as? [String: [String: String]]
	else {
		throw NSError(domain: "GeneratePluralRules", code: 1, userInfo: [
			NSLocalizedDescriptionKey: "Not a CLDR plurals-type-\(kind) file: \(path)",
		])
	}
	return table
}

let cardinalTable = try loadCLDR(pluralsPath, kind: "cardinal")
let ordinalTable: [String: [String: String]] = try ordinalsPath.map { try loadCLDR($0, kind: "ordinal") } ?? [:]

// MARK: - AST

enum Operand: String, Hashable { case n, i, v, w, f, t, e, c }

indirect enum Cond {
	case or([Cond])
	case and([Cond])
	case rel(operand: Operand, mod: Int?, equal: Bool, ranges: [(Int, Int)])
}

enum Token: Equatable {
	case word(String), num(Int), op(String)
}

// MARK: - Tokenizer

func stripSamples(_ s: String) -> String {
	let body = s.firstIndex(of: "@").map { String(s[..<$0]) } ?? s
	return body.trimmingCharacters(in: .whitespaces)
}

func tokenize(_ src: String) -> [Token] {
	var tokens: [Token] = []
	let chars = Array(src)
	var i = 0
	while i < chars.count {
		let c = chars[i]
		if c.isWhitespace { i += 1; continue }
		if c.isLetter {
			var j = i
			while j < chars.count, chars[j].isLetter { j += 1 }
			tokens.append(.word(String(chars[i ..< j])))
			i = j; continue
		}
		if c.isNumber {
			var j = i
			while j < chars.count, chars[j].isNumber { j += 1 }
			tokens.append(.num(Int(String(chars[i ..< j]))!))
			i = j; continue
		}
		if c == "!", i + 1 < chars.count, chars[i + 1] == "=" { tokens.append(.op("!=")); i += 2; continue }
		if c == "=" { tokens.append(.op("=")); i += 1; continue }
		if c == "%" { tokens.append(.op("%")); i += 1; continue }
		if c == ".", i + 1 < chars.count, chars[i + 1] == "." { tokens.append(.op("..")); i += 2; continue }
		if c == "," { tokens.append(.op(",")); i += 1; continue }
		fatalError("unexpected character '\(c)' in rule: \(src)")
	}
	return tokens
}

// MARK: - Parser

final class Parser {
	let tokens: [Token]
	var pos: Int = 0
	init(_ tokens: [Token]) { self.tokens = tokens }

	func peek() -> Token? { pos < tokens.count ? tokens[pos] : nil }
	@discardableResult func advance() -> Token? { let t = peek(); pos += 1; return t }

	func parseInt() -> Int {
		guard case let .num(n) = advance() else { fatalError("expected number") }
		return n
	}

	func parseRange() -> (Int, Int) {
		let a = parseInt()
		if peek() == .op("..") { advance(); let b = parseInt(); return (a, b) }
		return (a, a)
	}

	func parseRanges() -> [(Int, Int)] {
		var rs = [parseRange()]
		while peek() == .op(",") { advance(); rs.append(parseRange()) }
		return rs
	}

	func parseRelation() -> Cond {
		guard case let .word(name) = advance() else { fatalError("expected operand") }
		guard let op = Operand(rawValue: name) else { fatalError("unknown operand: \(name)") }
		var mod: Int? = nil
		if peek() == .op("%") { advance(); mod = parseInt() }
		let eq: Bool
		switch advance() {
		case .op("=")?: eq = true
		case .op("!=")?: eq = false
		default: fatalError("expected = or !=")
		}
		return .rel(operand: op, mod: mod, equal: eq, ranges: parseRanges())
	}

	func parseAnd() -> Cond {
		var parts = [parseRelation()]
		while peek() == .word("and") { advance(); parts.append(parseRelation()) }
		return parts.count == 1 ? parts[0] : .and(parts)
	}

	func parseOr() -> Cond {
		var parts = [parseAnd()]
		while peek() == .word("or") { advance(); parts.append(parseAnd()) }
		return parts.count == 1 ? parts[0] : .or(parts)
	}
}

func parseRule(_ raw: String) -> Cond? {
	let body = stripSamples(raw)
	guard !body.isEmpty else { return nil }
	return Parser(tokenize(body)).parseOr()
}

// MARK: - Emitter
//
// Emission yields a `BoolExpr` so that constant-foldable comparisons (operands we can't
// represent in a Double-only API — w/f/t/e/c, and v outside the `v = 0` idiom) collapse
// to literal true/false. Then AND/OR prune their literal operands, dead branches drop,
// and unreferenced bindings (absN/i/isInteger) are omitted in the final closure.

enum BoolExpr {
	case lit(Bool)
	case dyn(String)
}

func emitRelation(_ op: Operand, mod: Int?, equal: Bool, ranges: [(Int, Int)]) -> BoolExpr {
	// Idiom: `v = 0` / `v != 0` means "n is integer" / "n is not integer".
	if op == .v, mod == nil, ranges.count == 1, ranges[0] == (0, 0) {
		return .dyn(equal ? "isInteger" : "!isInteger")
	}

	// w/f/t/e/c (and v outside the idiom) — we don't preserve formatting context,
	// so treat as 0 and constant-fold. 0 mod m is also 0, so mod doesn't change the answer.
	if op != .n, op != .i {
		let zeroInRanges = ranges.contains { $0.0 <= 0 && 0 <= $0.1 }
		return .lit(equal ? zeroInRanges : !zeroInRanges)
	}

	// Dynamic operand: `n` (Double via absN) or `i` (Int).
	let isDouble = (op == .n)
	let base = isDouble ? "absN" : "i"
	let lhs: String
	let lhsIsDouble: Bool
	if let m = mod {
		if isDouble {
			lhs = "\(base).truncatingRemainder(dividingBy: \(m))"
			lhsIsDouble = true
		} else {
			lhs = "(\(base) % \(m))"
			lhsIsDouble = false
		}
	} else {
		lhs = base
		lhsIsDouble = isDouble
	}

	func single(_ a: Int, _ b: Int) -> String {
		if a == b { return "\(lhs) == \(a)" }
		return lhsIsDouble
			? "(\(Double(a)) ... \(Double(b))).contains(\(lhs))"
			: "(\(a) ... \(b)).contains(\(lhs))"
	}

	if equal {
		let parts = ranges.map { single($0.0, $0.1) }
		return parts.count == 1 ? .dyn(parts[0]) : .dyn("(" + parts.joined(separator: " || ") + ")")
	}
	if ranges.count == 1 {
		let (a, b) = ranges[0]
		if a == b { return .dyn("\(lhs) != \(a)") }
		return lhsIsDouble
			? .dyn("!(\(Double(a)) ... \(Double(b))).contains(\(lhs))")
			: .dyn("!(\(a) ... \(b)).contains(\(lhs))")
	}
	let parts = ranges.map { single($0.0, $0.1) }
	return .dyn("!(" + parts.joined(separator: " || ") + ")")
}

func emit(_ c: Cond) -> BoolExpr {
	switch c {
	case let .rel(op, mod, eq, r):
		return emitRelation(op, mod: mod, equal: eq, ranges: r)

	case let .and(cs):
		var dyn: [String] = []
		for sub in cs {
			switch emit(sub) {
			case .lit(false): return .lit(false)
			case .lit(true): continue
			case let .dyn(s): dyn.append(s)
			}
		}
		if dyn.isEmpty { return .lit(true) }
		if dyn.count == 1 { return .dyn(dyn[0]) }
		return .dyn(dyn.map { "(\($0))" }.joined(separator: " && "))

	case let .or(cs):
		var dyn: [String] = []
		for sub in cs {
			switch emit(sub) {
			case .lit(true): return .lit(true)
			case .lit(false): continue
			case let .dyn(s): dyn.append(s)
			}
		}
		if dyn.isEmpty { return .lit(false) }
		if dyn.count == 1 { return .dyn(dyn[0]) }
		return .dyn(dyn.map { "(\($0))" }.joined(separator: " || "))
	}
}

let categories = ["zero", "one", "two", "few", "many"]

/// Whole-word identifier match — distinguishes `i` from `if`, `isInteger`, etc.
func mentions(_ body: String, _ ident: String) -> Bool {
	let pattern = "\\b" + NSRegularExpression.escapedPattern(for: ident) + "\\b"
	let regex = try! NSRegularExpression(pattern: pattern)
	return regex.firstMatch(in: body, range: NSRange(body.startIndex..., in: body)) != nil
}

func emitClosure(_ rules: [String: String], indent: String) -> String {
	var parsed: [(String, Cond)] = []
	for cat in categories {
		guard let raw = rules["pluralRule-count-\(cat)"], let ast = parseRule(raw) else { continue }
		parsed.append((cat, ast))
	}
	if parsed.isEmpty { return "{ _ in .other }" }

	// Emit branches after folding. Skip dead ones; stop after an unconditional return.
	var branchLines: [String] = []
	var unconditional = false
	for (cat, ast) in parsed {
		if unconditional { break }
		switch emit(ast) {
		case .lit(false): continue
		case .lit(true):
			branchLines.append("return .\(cat)")
			unconditional = true
		case let .dyn(s):
			branchLines.append("if \(s) { return .\(cat) }")
		}
	}
	if !unconditional { branchLines.append("return .other") }

	// If every branch folded away, the closure is trivial.
	let body = branchLines.joined(separator: "\n")
	if branchLines == ["return .other"] { return "{ _ in .other }" }

	// Declare only the bindings actually referenced by the emitted body.
	let usesIsInteger = mentions(body, "isInteger")
	let usesI = mentions(body, "i") || usesIsInteger
	let usesAbsN = mentions(body, "absN") || usesI
	let paramName = usesAbsN ? "n" : "_"

	var lines: [String] = ["{ \(paramName) in"]
	if usesAbsN { lines.append("\tlet absN = abs(n)") }
	if usesI { lines.append("\tlet i = Int(absN.rounded(.down))") }
	if usesIsInteger { lines.append("\tlet isInteger = absN == Double(i)") }
	for line in branchLines { lines.append("\t\(line)") }
	lines.append("}")
	return lines.joined(separator: "\n" + indent)
}

// MARK: - Output assembly

func swiftIdent(_ tag: String) -> String { "_" + tag.replacingOccurrences(of: "-", with: "_") }
func bcp47(_ tag: String) -> String { tag.replacingOccurrences(of: "_", with: "-") }

let langs = Set(cardinalTable.keys).union(ordinalTable.keys).sorted()

var header = ""
header += "// @ai-generated(guided) — DO NOT EDIT BY HAND.\n"
header += "// Generated by Scripts/GeneratePluralRules from CLDR data.\n"
header += "// Regenerate after CLDR updates:\n"
header += "//   swift run GeneratePluralRules <plurals.json>"
if ordinalsPath != nil { header += " <ordinals.json>" }
header += " [<output.swift>]\n"
header += "//\n"
header += "// Source: https://github.com/unicode-org/cldr-json (cldr-core/supplemental/)\n"
header += "import Foundation\n\n"

var body = "public extension Fluent.PluralRule {\n\n"

// Per-language `static let` — declared individually so the type-checker handles them in
// isolation. A single 200+ entry dictionary literal with inline closures stresses the
// expression-type-checker.
for lang in langs {
	let card = cardinalTable[lang] ?? [:]
	let ord = ordinalTable[lang] ?? [:]
	body += "\tfileprivate static let \(swiftIdent(lang)): Self = .init(\n"
	body += "\t\tcardinal: \(emitClosure(card, indent: "\t\t")),\n"
	body += "\t\tordinal:  \(emitClosure(ord, indent: "\t\t"))\n"
	body += "\t)\n\n"
}

// Dictionary of references — no closures here, just lookups.
body += "\t/// CLDR plural rule mapping by BCP-47 language tag.\n"
body += "\t/// Keys cover both primary subtags (e.g. \"en\") and region variants (e.g. \"pt-PT\")\n"
body += "\t/// when CLDR distinguishes them; `Bundle` looks up by primary subtag via `default(for:)`.\n"
body += "\tstatic let defaults: [String: Self] = [\n"
for lang in langs {
	body += "\t\t\"\(bcp47(lang))\": \(swiftIdent(lang)),\n"
}
body += "\t]\n"
body += "}\n"

try (header + body).write(to: URL(fileURLWithPath: outputPath), atomically: true, encoding: .utf8)
print("wrote \(outputPath): \(langs.count) language entries " +
      "(cardinal: \(cardinalTable.count), ordinal: \(ordinalTable.count))")
