import Foundation

/// A russian grammatical case.
public enum RussianCase: GrammaticalFeature {
    
    /// Именительный падеж
    case nominative
    /// Родительный падеж
    case genitive
    /// Дательный падеж
    case dative
    /// Винительный падеж
    case accusative
    /// Творительный падеж
    case instrumental
    /// Предложный падеж
    case prepositional
}

extension GrammaticalSet {
    
    /// Russian grammatical case of the word.
    public var russianCase: RussianCase? {
        get { self[RussianCase.self] }
        set { self[RussianCase.self] = newValue }
    }
    
    /// Returns a new grammatical set with the given russian grammatical case.
    public func russianCase(_ russianCase: RussianCase) -> GrammaticalSet {
        with(russianCase)
    }
    
    /// Returns a new grammatical set for a russian word representing a unit in a quantitative expression.
    public func russianUnitFor(number: Int) -> GrammaticalSet {
        let twenty = number % 100
        if twenty > 10, twenty < 20 {
            return russianCase(.genitive).number(.plural)
        }
        let last = number % 10
        switch last {
        case 1: return russianCase(.nominative).number(.singular)
        case 2 ... 4: return russianCase(.accusative).number(.plural)
        default: return russianCase(.genitive).number(.plural)
        }
    }
}
