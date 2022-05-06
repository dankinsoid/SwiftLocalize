//
//  Word.swift
//  SwiftLocalize
//
//  Created by Данил Войдилов on 05.08.2019.
//  Copyright © 2019 voidilov. All rights reserved.
//

import Foundation

public struct Word: ExpressibleByDictionaryLiteral, Hashable, Codable, ExpressibleByStringInterpolation {
    internal var key: String
    private var words: [Language: Forms] = [:]

    public var localized: String {
        get { string() }
        set {
            words[.current, default: .init(newValue)][.default] = newValue
        }
    }

    public init(_ word: String, _ variants: [Language: Forms] = [:]) {
        key = word
        words = variants
    }

    public subscript(_ language: Language) -> Forms? {
        get { words[language] }
        set { words[language] = newValue }
    }

    public init(dictionaryLiteral elements: (Language, Forms)...) {
        guard !elements.isEmpty else {
            self = Word("")
            return
        }
        var _elements: [Language: Forms] = [:]
        elements.forEach {
            _elements[$0.0] = $0.1
        }
        let _key = (_elements[.default] ?? _elements[.current] ?? elements.first?.1)?.word ?? ""
        self = Word(_key, _elements)
    }

    public init(stringInterpolation: DefaultStringInterpolation) {
        self = Word(String(stringInterpolation: stringInterpolation))
    }

    public init(stringLiteral value: String.StringLiteralType) {
        self = Word(value)
    }

    public func string(language: Language = .current, _ form: FormType = .default) -> String {
        if form == .none, let forms = words[language] ?? words[.default] {
            return forms.word ?? key
        }
        return (words[language] ?? words[.default])?[form] ?? key
    }

    public static func +(_ lhs: Word, _ rhs: Word) -> Word {
        return Word(lhs.key + rhs.key, Swift.Dictionary(Array(lhs.words) + Array(rhs.words), uniquingKeysWith: +))
    }

    public static func +(_ lhs: Word, _ rhs: String) -> Word {
        return Word(lhs.key + rhs, lhs.words.mapValues { $0 + rhs })
    }

    public static func +(_ lhs: String, _ rhs: Word) -> Word {
        return Word(lhs + rhs.key, rhs.words.mapValues { lhs + $0 })
    }

    public static func == (lhs: Word, rhs: Word) -> Bool {
        return lhs.words == rhs.words
    }
}
