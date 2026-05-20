import Foundation

public extension Localized {

	/// A language-bound scope handed to closures in `Localized.with(_:_:)` and the
	/// closure-form `Localized.init(_:_:)`. Exposes language-aware helpers
	/// (`plural`, `ordinal`) without making the call site repeat the language.
	///
	/// All helpers are conveniences over the underlying `FixedWidthInteger.plural`
	/// / `ordinal` methods — same semantics, just the language is already bound.
	struct Helper {
		public let language: Language

		public init(language: Language) {
			self.language = language
		}
	}

	/// Add (or replace) a translation for `language`, building its value through
	/// a closure that receives a `Helper` bound to that language. Returns a new
	/// `Localized` with the same base and the merged translations.
	///
	/// Chain `.with(_:_:)` calls when each translation depends on the language
	/// — typically plural/ordinal forms — so you don't repeat `in: .ru` etc.:
	///
	/// ```swift
	/// Localized<String>(.en) { $0.plural(for: n) {
	///     switch $0 {
	///     case .one: "\(n) song"
	///     default:   "\(n) songs"
	///     }
	/// }}
	/// .with(.ru) { $0.plural(for: n) {
	///     switch $0 {
	///     case .one: "\(n) песня"
	///     case .few: "\(n) песни"
	///     default:   "\(n) песен"
	///     }
	/// }}
	/// ```
	func with(_ language: Language, _ build: (Helper) -> Value) -> Localized {
		var merged = translations
		merged[language] = build(Helper(language: language))
		return Localized(base.language, base.value, merged)
	}

	/// Direct-value overload of `with(_:_:)` for translations that don't need
	/// the helper. Equivalent to merging `[language: value]` into translations.
	func with(_ language: Language, _ value: Value) -> Localized {
		var merged = translations
		merged[language] = value
		return Localized(base.language, base.value, merged)
	}

	/// Closure-form base initializer — the counterpart to `.with(_:_:)` so the
	/// base language can also use the helper. Without this, `plural`/`ordinal`
	/// on the base value would have to be spelled `n.plural(in: lang) { … }`
	/// while every other branch could use `$0.plural(for: n) { … }` — asymmetric.
	init(_ baseLanguage: Language, _ build: (Helper) -> Value) {
		self.init(baseLanguage, build(Helper(language: baseLanguage)))
	}
}

public extension Localized.Helper {

	/// Cardinal plural form for `value` in this scope's language. Same as
	/// `value.plural(in: language) { … }` — the helper just removes the
	/// language argument because it's already in scope.
	func plural<T, I: FixedWidthInteger>(
		for value: I,
		_ body: (PluralCategorized<I>) -> T
	) -> T {
		value.plural(in: language, body)
	}

	/// Ordinal plural form for `value` in this scope's language. Same as
	/// `value.ordinal(in: language) { … }` — the helper just removes the
	/// language argument because it's already in scope.
	func ordinal<T, I: FixedWidthInteger>(
		for value: I,
		_ body: (PluralCategorized<I>) -> T
	) -> T {
		value.ordinal(in: language, body)
	}
}
