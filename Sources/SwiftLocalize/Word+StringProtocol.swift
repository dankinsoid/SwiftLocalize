import Foundation

// `Localized` used to conform to `StringProtocol` / `LosslessStringConvertible`
// to act as a drop-in `String` replacement. Removed because it enabled silent
// `.current` resolution via `"\(localized)"` and friends. Use:
//   - `localized.localized` — current locale, explicit.
//   - `localized(.en)` — specific language.
//   - `localized.callAsFunction(.en)` — same, spelled out.
