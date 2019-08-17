//
//  Localize.swift
//  SwiftLocalize
//
//  Created by Данил Войдилов on 05.08.2019.
//  Copyright © 2019 danil.voidilov. All rights reserved.
//

import Foundation

public enum Localize {
	
	public enum CountForm {
		case plural, singular
	}
	
	public enum Gender {
		 case masculine, feminine, neuter, common
	}
    
    public struct FormType: OptionSet, Hashable, ExpressibleByIntegerLiteral, Codable {
        public typealias IntegerLiteralType = UInt

        public var rawValue: UInt
        
        public static func count(_ count: CountForm) -> FormType {
            switch count {
            case .singular: return .singular
            case .plural:   return .plural
            }
        }
        
        public static func gender(_ gender: Gender) -> FormType {
            switch gender {
            case .masculine: return .masculine
            case .feminine:  return .feminine
            case .neuter:    return .neuter
            case .common:    return .common
            }
        }
        
        public static func cases<C: LanguageCaseProtocol>(_ cases: C...) -> FormType {
            return FormType(rawValue: cases
                .map({ (UInt($0.rawValue) << 6) | $0.forms.rawValue })
                .reduce(0, |))
        }
        
        public static var `default`: FormType { return .none }
        public static var none: FormType { return 0 }
        public static var singular: FormType { return 1 }
        public static var plural: FormType { return 2 }
        public static var masculine: FormType { return 4 }
        public static var feminine: FormType { return 8 }
        public static var neuter: FormType { return 16 }
        public static var common: FormType { return 32 }
        
        public init(rawValue: UInt) {
            self.rawValue = rawValue
        }
        
        public init(integerLiteral value: UInt) {
            rawValue = value
        }
        
        public mutating func formUnion(_ other: __owned Localize.FormType) {
            rawValue = rawValue | other.rawValue
        }
        
        public mutating func formIntersection(_ other: Localize.FormType) {
            rawValue = rawValue & other.rawValue
        }
        
        public mutating func formSymmetricDifference(_ other: __owned Localize.FormType) {
            rawValue = rawValue ^ other.rawValue
        }
        
    }

	public struct Forms: ExpressibleByStringLiteral, ExpressibleByDictionaryLiteral, Hashable, Codable {
		public typealias StringLiteralType = String
		fileprivate var forms: [FormType: String]
        public var word: String? {
            return forms[.default] ?? forms.first?.value
        }
        
		public subscript(_ form: FormType) -> String? {
            get {
            return forms[form] ??
                forms.filter({ form.contains($0.key) }).values.first ??
                forms.filter({ $0.key.intersection(form) != .none }).values.first
            }
            set {
                forms[form] = newValue
            }
		}
		
		public init(dictionaryLiteral elements: (FormType, Forms)...) {
			forms = [:]
			elements.forEach {
                let type = $0.0
                $0.1.forms.forEach {
                    forms[[type, $0.0]] = $0.1
                }
			}
		}
        
        public init(_ elements: [FormType: String]) {
            forms = elements
        }
		
		public init(_ value: String) {
			forms = [.default: value]
		}
		
		public init(stringLiteral value: String) {
			self = Forms(value)
		}
		
        public func exactly(_ types: FormType) -> String? {
            return forms[types]
        }
        
        public func all(where types: FormType) -> [String] {
            return forms.filter({ $0.key.contains(types) }).map { $0.value }
        }
        
        public func all() -> [FormType: String] {
            return forms
        }
        
        public static func +(_ lhs: Forms, _ rhs: Forms) -> Forms {
            return Forms(Swift.Dictionary(Array(lhs.forms) + Array(rhs.forms), uniquingKeysWith: +))
        }
        
        public static func +(_ lhs: Forms, _ rhs: String) -> Forms {
            return Forms(lhs.forms.mapValues({ $0 + rhs }))
        }
        
        public static func +(_ lhs: String, _ rhs: Forms) -> Forms {
            return Forms(rhs.forms.mapValues({ lhs + $0 }))
        }
	}
	
}
