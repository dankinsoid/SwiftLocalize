import Foundation

extension Localized: StringProtocol, CustomStringConvertible, LosslessStringConvertible {
    
    public typealias UTF8View = String.UTF8View
    public typealias UTF16View = String.UTF16View
    public typealias UnicodeScalarView = String.UnicodeScalarView

    public var startIndex: String.Index { localized.startIndex }
    public var endIndex: String.Index { localized.endIndex }
    public var utf8: String.UTF8View { localized.utf8 }
    public var utf16: String.UTF16View { localized.utf16 }
    public var unicodeScalars: String.UnicodeScalarView { localized.unicodeScalars }
    public var description: String { localized }

    public init<C, Encoding>(decoding codeUnits: C, as sourceEncoding: Encoding.Type) where C: Collection, Encoding: _UnicodeEncoding, C.Element == Encoding.CodeUnit {
        self = Localized(String(decoding: codeUnits, as: sourceEncoding))
    }

    public init(cString nullTerminatedUTF8: UnsafePointer<CChar>) {
        self = Localized(String(cString: nullTerminatedUTF8))
    }

    public init<Encoding>(decodingCString nullTerminatedCodeUnits: UnsafePointer<Encoding.CodeUnit>, as sourceEncoding: Encoding.Type) where Encoding: _UnicodeEncoding {
        self = Localized(String(decodingCString: nullTerminatedCodeUnits, as: sourceEncoding))
    }

    public subscript(bounds: Range<String.Index>) -> String.SubSequence {
        localized[bounds]
    }

    public subscript(position: String.Index) -> Character {
        localized[position]
    }

    public func lowercased() -> String { localized.lowercased() }
    public func uppercased() -> String { localized.uppercased() }

    public func withCString<Result>(_ body: (UnsafePointer<CChar>) throws -> Result) rethrows -> Result {
        try localized.withCString(body)
    }

    public func withCString<Result, Encoding>(encodedAs targetEncoding: Encoding.Type, _ body: (UnsafePointer<Encoding.CodeUnit>) throws -> Result) rethrows -> Result where Encoding: _UnicodeEncoding {
        try localized.withCString(encodedAs: targetEncoding, body)
    }

    public func index(before i: String.Index) -> String.Index {
        localized.index(before: i)
    }

    public func index(after i: String.Index) -> String.Index {
        localized.index(after: i)
    }

    public mutating func write(_ string: String) {
        localized.write(string)
    }

    public func write<Target>(to target: inout Target) where Target: TextOutputStream {
        localized.write(to: &target)
    }
}
