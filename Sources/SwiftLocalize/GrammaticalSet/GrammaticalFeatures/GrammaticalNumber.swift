import Foundation

/// A grammatical number.
public enum GrammaticalNumber: GrammaticalFeature {
    
    case singular, plural
}

extension GrammaticalSet {
    
    /// Grammar number of the word.
    public var number: GrammaticalNumber? {
        get { self[GrammaticalNumber.self] }
        set { self[GrammaticalNumber.self] = newValue }
    }
    
    /// Returns a new grammatical set with the given grammatical number.
    public func number(_ number: GrammaticalNumber) -> GrammaticalSet {
        with(number)
    }
    
    /// A grammatical set representing a plural word.
    public static var plural: GrammaticalSet {
        GrammaticalSet().number(.plural)
    }
    
    /// A grammatical set for a singular word.
    public static var singular: GrammaticalSet {
        GrammaticalSet().number(.singular)
    }
}
