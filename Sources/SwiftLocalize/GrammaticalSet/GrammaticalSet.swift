import Foundation

/// A grammatical set/profile of a word.
public struct GrammaticalSet: Hashable, SetAlgebra {
    
    public typealias ArrayLiteralElement = GrammaticalSet
    public typealias Element = GrammaticalSet

    private var features: [ObjectIdentifier: AnyHashable]
    
    public var count: Int { features.count }

    public init() {
        features = [:]
    }
    
    public subscript<F: GrammaticalFeature>(category: F.Type) -> F? {
        get {
            features[ObjectIdentifier(category)] as? F
        }
        set {
            features[ObjectIdentifier(category)] = newValue
        }
    }
    
    public func union(_ other: __owned GrammaticalSet) -> GrammaticalSet {
        var result = self
        result.formUnion(other)
        return result
    }
    
    public func intersection(_ other: GrammaticalSet) -> GrammaticalSet {
        var result = self
        result.formIntersection(other)
        return result
    }
    
    public func symmetricDifference(_ other: __owned GrammaticalSet) -> GrammaticalSet {
        var result = self
        result.formSymmetricDifference(other)
        return result
    }
    
    public mutating func formUnion(_ other: __owned GrammaticalSet) {
        features.merge(other.features) { $1 }
    }
    
    public mutating func formIntersection(_ other: GrammaticalSet) {
        features = features.filter { other.features.keys.contains($0.key) }
    }
    
    public mutating func formSymmetricDifference(_ other: __owned GrammaticalSet) {
        features = features.filter { !other.features.keys.contains($0.key) }
    }
    
    public func contains(_ member: GrammaticalSet) -> Bool {
        member.features.allSatisfy { features[$0.key] == $0.value }
    }
    
    public mutating func insert(_ newMember: __owned GrammaticalSet) -> (inserted: Bool, memberAfterInsert: GrammaticalSet) {
        let inserted = !contains(newMember)
        if inserted {
            formUnion(newMember)
        }
        return (inserted, self)
    }
    
    public mutating func remove(_ member: GrammaticalSet) -> GrammaticalSet? {
        guard contains(member) else { return nil }
        formSymmetricDifference(member)
        return member
    }
    
    public mutating func update(with newMember: __owned GrammaticalSet) -> GrammaticalSet? {
        let old = contains(newMember) ? newMember : nil
        formUnion(newMember)
        return old
    }
}

extension GrammaticalSet {
    
    /// Returns a new grammatical set with the given grammatical feature.
    public func with<F: GrammaticalFeature>(_ feature: F) -> GrammaticalSet {
        var copy = self
        copy[F.self] = feature
        return copy
    }
}

extension GrammaticalSet {
    
    public static var `any`: GrammaticalSet {
        GrammaticalSet()
    }
}

extension GrammaticalSet: CustomStringConvertible {
    
    public var description: String {
        let array = features.lazy.map { ".\($0.value.base)" }.sorted()
        if array.count == 1 {
            return array[0]
        }
        return "[\(array.joined(separator: ", "))]"
    }
}
