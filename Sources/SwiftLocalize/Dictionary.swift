//
//  Dictionary.swift
//  SwiftLocalize
//
//  Created by Данил Войдилов on 05.08.2019.
//  Copyright © 2019 voidilov. All rights reserved.
//

import Foundation

extension Localize {
    
    public struct Dictionary: ExpressibleByDictionaryLiteral, Codable {
        private var words: [String: Word] = [:]
        
        public subscript(_ word: String) -> Word {
            return words[word] ?? Word(word, [:])
        }
        
        public init(dictionaryLiteral elements: (String, [Language: Forms])...) {
            elements.forEach {
                self.words[$0.0] = Word($0.0, $0.1)
            }
        }
        
        public init(_ words: Word...) {
            self = Dictionary(words: words)
        }
        
        public init(words: [Word]) {
            words.forEach {
                self.words[$0.key] = $0
            }
        }
        
        public init(dict: [String: Word]) {
            words = dict
        }
        
        public init(from decoder: Decoder) throws {
            words = try decoder.singleValueContainer().decode([String: Word].self)
        }
        
        public func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            try container.encode(words)
        }
        
    }
    
}
