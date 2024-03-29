import Foundation

public enum Language: String, Codable, CaseIterable, Hashable {
	case en, ru, it, fr, es, pt, de, zh, nl, ja, ko, vi, sv, da, fi, nb, tr, el, id, ms, th, hi, hu, pl, cs, sk, uk, ca, ro, hr, he, ar, `default`

	public static var current: Language {
		Language(
			rawValue: (Locale.preferredLanguages.first ?? Locale.current.languageCode)?.components(separatedBy: "-").first ?? ""
		) ?? .en
	}
}
