//
//  Word.swift
//  SwiftLocalize
//
//  Created by Данил Войдилов on 05.08.2019.
//  Copyright © 2019 voidilov. All rights reserved.
//

import Foundation

extension Localize {
    
    public struct Word: ExpressibleByDictionaryLiteral, ExpressibleByStringLiteral, Hashable {
        internal let key: String
        private var words: [Language: Forms] = [:]
        public var localized: String {
            return string()
        }
        
        public init(_ word: String, _ variants: [Language: Forms] = [:]) {
            key = word
            words = variants
        }
        
        public subscript(_ language: Language) -> Forms? {
            return words[language]
        }
        
        public init(stringLiteral value: String) {
            self = Word(value)
        }
        
        public init(dictionaryLiteral elements: (Language, Forms)...) {
            guard !elements.isEmpty else {
                self = Word("")
                return
            }
           let _key = elements.first(where: { $0.0 == Language.current })?.1.word ?? elements.first(where: { $0.0 == .en })?.1.word ?? elements.first?.1.word ?? ""
            var _elements: [Language: Forms] = [:]
            elements.forEach {
                _elements[$0.0] = $0.1
            }
            self = Word(_key, _elements)
        }
        
        public func string(language: Language = .current, _ form: FormType = .default) -> String {
            return words[language]?[form] ?? key
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
        
        public static func == (lhs: Localize.Word, rhs: Localize.Word) -> Bool {
            return lhs.words == rhs.words
        }
    }
    
    
}
