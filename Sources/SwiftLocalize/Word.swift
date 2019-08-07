//
//  Word.swift
//  SwiftLocalize
//
//  Created by Данил Войдилов on 05.08.2019.
//  Copyright © 2019 voidilov. All rights reserved.
//

import Foundation

extension Localize {
    
    public struct Word: ExpressibleByDictionaryLiteral, ExpressibleByStringLiteral {
        internal let key: String
        private var words: [Language: Forms] = [:]
        
        init(_ word: String, _ variants: [Language: Forms] = [:]) {
            key = word
            words = variants
            if words[.current] == nil {
                words[.current] = Forms(key)
            }
            if words[.current]?[.default] == nil {
                words[.current]?[.default] = key
            }
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
        
        func string(language: Language = .current, _ form: FormType = .default) -> String {
            return words[language]?[form] ?? key
        }
        
    }
    
    
}
