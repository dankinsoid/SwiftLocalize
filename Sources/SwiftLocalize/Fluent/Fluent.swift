// @ai-generated(solo)
import Foundation

/// Namespace for the Fluent-compatible localization model.
///
/// Mirrors the data model of Mozilla Fluent (https://projectfluent.org).
/// The eventual goal is a full FTL parser + runtime; this sketch defines the
/// AST and a programmatic builder API. FTL parsing will be layered on top.
public enum Fluent {}

public extension Fluent {

	enum Error: Swift.Error, Hashable, Sendable {
		case unknownMessage(Identifier)
		case unknownAttribute(message: Identifier, attribute: Identifier)
		case unknownTerm(Identifier)
		case unknownFunction(Identifier)
		case unknownVariable(Identifier)
		case cyclicReference(Identifier)
		case unsupported(String)
	}
}
