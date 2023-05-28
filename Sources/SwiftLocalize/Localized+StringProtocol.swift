import Foundation

extension Localized: ExpressibleByUnicodeScalarLiteral where T: ExpressibleByUnicodeScalarLiteral {
    
    public init(unicodeScalarLiteral value: T.UnicodeScalarLiteralType) {
        self.init(T(unicodeScalarLiteral: value))
    }
}

extension Localized: ExpressibleByExtendedGraphemeClusterLiteral where T: ExpressibleByExtendedGraphemeClusterLiteral {
 
    public init(extendedGraphemeClusterLiteral value: T.ExtendedGraphemeClusterLiteralType) {
        self.init(T(extendedGraphemeClusterLiteral: value))
    }
}

extension Localized: Sequence where T: Sequence {
    
    public func makeIterator() -> T.Iterator {
        localized.makeIterator()
    }
}

extension Localized: Collection where T: Collection {
    
    public typealias Index = T.Index
    public typealias Indices = T.Indices
    public typealias Element = T.Element
    public typealias SubSequence = T.SubSequence
    
    public var startIndex: T.Index { localized.startIndex }
    public var endIndex: T.Index { localized.endIndex }
    
    public var indices: T.Indices {
        localized.indices
    }
    
    public subscript(bounds: Range<T.Index>) -> T.SubSequence {
        localized[bounds]
    }
    
    public subscript(position: T.Index) -> T.Element {
        localized[position]
    }
    
    public func index(after i: T.Index) -> T.Index {
        localized.index(after: i)
    }
}

extension Localized: BidirectionalCollection where T: BidirectionalCollection {
    
    public func index(before i: T.Index) -> T.Index {
        localized.index(before: i)
    }
}

extension Localized: TextOutputStreamable where T: TextOutputStreamable {

    
    public func write<Target>(to target: inout Target) where Target: TextOutputStream {
        localized.write(to: &target)
    }
}


extension Localized: TextOutputStream where T: TextOutputStream {
    
    public mutating func write(_ string: String) {
        localized.write(string)
    }
}

extension Localized: LosslessStringConvertible where T: LosslessStringConvertible {
    
    public init?(_ description: String) {
        guard let value = T(description) else { return nil }
        self.init(value)
    }
}

extension Localized: CustomStringConvertible where T: CustomStringConvertible {
    
    public var description: String { localized.description }
}

extension Localized: ExpressibleByStringLiteral where T: ExpressibleByStringLiteral {
    
    public init(stringLiteral value: T.StringLiteralType) {
        self = Localized(T(stringLiteral: value))
    }
}

extension Localized: ExpressibleByStringInterpolation where T: ExpressibleByStringInterpolation {
    
    public init(stringInterpolation: T.StringInterpolation) {
        self = Localized(T(stringInterpolation: stringInterpolation))
    }
}

extension Localized: Comparable where T: Comparable {
    
    public static func < (lhs: Localized<T>, rhs: Localized<T>) -> Bool {
        lhs.localized < rhs.localized
    }
}

extension Localized: StringProtocol where T: StringProtocol {
    
    public typealias UTF8View = T.UTF8View
    public typealias UTF16View = T.UTF16View
    public typealias UnicodeScalarView = T.UnicodeScalarView
    public var utf8: T.UTF8View { localized.utf8 }
    public var utf16: T.UTF16View { localized.utf16 }
    public var unicodeScalars: T.UnicodeScalarView { localized.unicodeScalars }
    
    public init<C, Encoding>(decoding codeUnits: C, as sourceEncoding: Encoding.Type) where C: Collection, Encoding: _UnicodeEncoding, C.Element == Encoding.CodeUnit {
        self = Localized(T(decoding: codeUnits, as: sourceEncoding))
    }

    public init(cString nullTerminatedUTF8: UnsafePointer<CChar>) {
        self = Localized(T(cString: nullTerminatedUTF8))
    }

    public init<Encoding>(decodingCString nullTerminatedCodeUnits: UnsafePointer<Encoding.CodeUnit>, as sourceEncoding: Encoding.Type) where Encoding: _UnicodeEncoding {
        self = Localized(T(decodingCString: nullTerminatedCodeUnits, as: sourceEncoding))
    }

    public func lowercased() -> String { localized.lowercased() }
    public func uppercased() -> String { localized.uppercased() }

    public func withCString<Result>(_ body: (UnsafePointer<CChar>) throws -> Result) rethrows -> Result {
        try localized.withCString(body)
    }

    public func withCString<Result, Encoding>(encodedAs targetEncoding: Encoding.Type, _ body: (UnsafePointer<Encoding.CodeUnit>) throws -> Result) rethrows -> Result where Encoding: _UnicodeEncoding {
        try localized.withCString(encodedAs: targetEncoding, body)
    }
}
