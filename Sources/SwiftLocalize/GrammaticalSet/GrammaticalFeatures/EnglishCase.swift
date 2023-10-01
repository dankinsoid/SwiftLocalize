import Foundation

/// An english grammatical case.
public enum EnglishCase: GrammaticalFeature {
    
    /// Nominative or Subjective Case
    case nominative
    /// Objective or Accusative Case/
    case objective
    /// Possessive or Genitive Case/
    case possessive
}

extension GrammaticalSet {
    
    /// English grammatical case of the word.
    public var englishCase: EnglishCase? {
        get { self[EnglishCase.self] }
        set { self[EnglishCase.self] = newValue }
    }
    
    /// Returns a new grammatical set with the given english grammatical case.
    public func englishCase(_ englishCase: EnglishCase) -> GrammaticalSet {
        with(englishCase)
    }
}
