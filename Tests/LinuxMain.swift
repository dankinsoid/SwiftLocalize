import XCTest

import SwiftLocalizeTests

struct EnglishTime: LanguageCaseProtocol {
	let absolute: AbsoluteTime
	let tense: Tense
	var rawValue: UInt16 {
		(UInt16(absolute.rawValue) << 8) & UInt16(tense.rawValue)
	}

	init?(rawValue: UInt16) {
		let timeBits = UInt8(rawValue >> 8)
		let tenseBits = UInt8((rawValue << 8) >> 8)
		guard let time = AbsoluteTime(rawValue: timeBits), let _tense = Tense(rawValue: tenseBits) else {
			return nil
		}
		self = EnglishTime(time, _tense)
	}

	init(_ absolute: AbsoluteTime, _ tense: Tense) {
		self.absolute = absolute
		self.tense = tense
	}

	enum AbsoluteTime: UInt8 {
		case present = 0, past = 1, future = 2, futureInThePast = 4
	}

	enum Tense: UInt8 {
		case simple = 0, perfect = 1, continuous = 2, perfectContinuous = 4
	}
}
