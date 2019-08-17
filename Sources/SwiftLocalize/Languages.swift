//
//  Languages.swift
//  SwiftLocalize
//
//  Created by Данил Войдилов on 05.08.2019.
//  Copyright © 2019 voidilov. All rights reserved.
//

import Foundation

public enum Language: String, Codable {
    case en, ru, it, fr, es, pt, de, zh, nl, ja, ko, vi, sv, da, fi, nb, tr, el, id, ms, th, hi, hu, pl, cs, sk, uk, ca, ro, hr, he, ar
    
    public static var current: Language {
        return Language(rawValue: (Locale.preferredLanguages.first ?? Locale.current.languageCode)?.components(separatedBy: "-").first ?? "") ?? .en
    }
    
}
