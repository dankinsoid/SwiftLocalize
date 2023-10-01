import Foundation

public extension Localized {
	
	struct Forms: ExpressibleByDictionaryLiteral {

		fileprivate var forms: [GrammaticalSet: T]

        public var count: Int { forms.count }
        
		public var word: T? {
            get { self[.any] }
			set { self[.any] = newValue }
		}

		public subscript(_ form: GrammaticalSet) -> T? {
			get {
				forms[form] ??
                    forms.lazy
                        .filter { form.contains($0.key) }
                        .sorted { $0.key.count < $1.key.count }
                        .first?.value
			}
			set {
				forms[form] = newValue
			}
		}

		public init(dictionaryLiteral elements: (GrammaticalSet, Forms)...) {
			forms = [:]
			elements.forEach {
				let type = $0.0
				$0.1.forms.forEach {
					forms[[type, $0.0]] = $0.1
				}
			}
		}

		public init(_ elements: [GrammaticalSet: T]) {
			forms = elements
		}

		public init(_ element: T) {
			self.init([.any: element])
		}
		
		public func exactly(_ types: GrammaticalSet) -> T? {
			forms[types]
		}

		public func all(where types: GrammaticalSet) -> [T] {
			forms.filter { $0.key.contains(types) }.map { $0.value }
		}

		public func all() -> [GrammaticalSet: T] {
			forms
		}
	}
}

extension Localized.Forms: ExpressibleByUnicodeScalarLiteral where T: ExpressibleByUnicodeScalarLiteral {
	
	public init(unicodeScalarLiteral value: T.UnicodeScalarLiteralType) {
		self = Localized.Forms(T(unicodeScalarLiteral: value))
	}
}

extension Localized.Forms: ExpressibleByExtendedGraphemeClusterLiteral where T: ExpressibleByExtendedGraphemeClusterLiteral {
	
	public init(extendedGraphemeClusterLiteral value: T.ExtendedGraphemeClusterLiteralType) {
		self = Localized.Forms(T(extendedGraphemeClusterLiteral: value))
	}
}

extension Localized.Forms: ExpressibleByStringLiteral where T: ExpressibleByStringLiteral {
	
	public init(stringLiteral value: T.StringLiteralType) {
		self = Localized.Forms(T(stringLiteral: value))
	}
}

extension Localized.Forms: ExpressibleByStringInterpolation where T: ExpressibleByStringInterpolation {
	
	public init(stringInterpolation value: T.StringInterpolation) {
		self = Localized.Forms(T(stringInterpolation: value))
	}
}

extension Localized.Forms: Equatable where T: Equatable {
}

extension Localized.Forms: Hashable where T: Hashable {}

extension Localized<String>.Forms {
	
	public static func + (_ lhs: Localized.Forms, _ rhs: Localized.Forms) -> Localized.Forms {
        let rhsForms = rhs.forms.sorted(by: { $0.key.count < $1.key.count })
        return Localized.Forms(
            Swift.Dictionary(
                lhs.forms.compactMap { lKey, lValue in
                    if let rValue = rhs.forms[lKey] {
                        return (lKey, lValue + rValue)
                    }
                    for (rKey, rValue) in rhsForms {
                        if rKey.contains(lKey) || lKey.contains(rKey) {
                            return (lKey.union(rKey), lValue + rValue)
                        }
                    }
                    return nil
                },
                uniquingKeysWith: +
            )
        )
	}
	
	public static func + (_ lhs: Localized.Forms, _ rhs: some StringProtocol) -> Localized.Forms {
		Localized.Forms(lhs.forms.mapValues { $0 + rhs })
	}
	
	public static func + (_ lhs: some StringProtocol, _ rhs: Localized.Forms) -> Localized.Forms {
		Localized.Forms(rhs.forms.mapValues { lhs + $0 })
	}
}

extension Localized.Forms: CustomStringConvertible {
    
    public var description: String {
        forms.description
    }
}
