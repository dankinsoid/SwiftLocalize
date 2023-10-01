import Foundation

/// A grammatical gender.
public enum GrammaticalGender: GrammaticalFeature {
    
    case masculine, feminine, neuter, common
}

extension GrammaticalSet {
    
    /// Grammatical gender of the word.
    public var gender: GrammaticalGender? {
        get { self[GrammaticalGender.self] }
        set { self[GrammaticalGender.self] = newValue }
    }
    
    /// Returns a new grammatical set with the given grammatical gender.
    public func gender(_ gender: GrammaticalGender) -> GrammaticalSet {
        with(gender)
    }
    
    /// A grammatical set for a masculine word.
    public static var masculine: GrammaticalSet {
        GrammaticalSet().gender(.masculine)
    }
    
    /// A grammatical set for a feminine word.
    public static var feminine: GrammaticalSet {
        GrammaticalSet().gender(.feminine)
    }
    
    /// A grammatical set for a neuter word.
    public static var neuter: GrammaticalSet {
        GrammaticalSet().gender(.neuter)
    }
}
