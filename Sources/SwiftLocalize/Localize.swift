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
		 case male, female, neuter, indefinite
	}
    
    public struct FormType: OptionSet, Hashable, ExpressibleByIntegerLiteral {
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
            case .male:         return .male
            case .female:       return .female
            case .neuter:       return .neuter
            case .indefinite:   return .indefinite
            }
        }
        
        public static func cases<C: LanguageCaseProtocol>(_ cases: C...) -> FormType {
            return FormType(rawValue: cases
                .map({ (UInt($0.rawValue) << 6) | $0.forms.rawValue })
                .reduce(0, |))
        }
        
        public static var `default`: FormType { return [.singular, .neuter] }
        public static var none: FormType { return 0 }
        public static var singular: FormType { return 1 }
        public static var plural: FormType { return 2 }
        public static var male: FormType { return 4 }
        public static var female: FormType { return 8 }
        public static var neuter: FormType { return 16 }
        public static var indefinite: FormType { return 32 }
        
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

	public struct Forms: ExpressibleByStringLiteral, ExpressibleByDictionaryLiteral {
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
		
		public init(dictionaryLiteral elements: (FormType, String)...) {
			forms = [:]
			elements.forEach {
				forms[$0.0] = $0.1
			}
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
	}
	
}