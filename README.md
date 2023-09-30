# SwiftLocalize
[![CI Status](https://img.shields.io/travis/Voidilov/SwiftLocalize.svg?style=flat)](https://travis-ci.org/Voidilov/SwiftLocalize)
[![Version](https://img.shields.io/cocoapods/v/SwiftLocalize.svg?style=flat)](https://cocoapods.org/pods/SwiftLocalize)
[![License](https://img.shields.io/cocoapods/l/SwiftLocalize.svg?style=flat)](https://cocoapods.org/pods/SwiftLocalize)
## Description
Library for native Swift localization of your projects. 
	
## Example
```swift
import Foundation
import SwiftLocalize

public extension String {

	@Localized<String> public var ok: String {
		[.ru: "Да",
		 .en: "Ok"]
	}
	@Localized<String> public var cancel: String {
		[.ru: "Отмена",
		 .en: "Cancel"]
	}
	@Localized<String> public var never: String {
		[.ru: "Никогда",
		 .en: "Never"]
	}
	@Localized<String> public var later: String {
		[.ru: "Позже",
		 .en: "Later"]
	}

	public static func coins(for count: Int) -> String {
		 Localized<String>([
			.ru: [
				.cases(NumberCase.accusative): "монеты",
				.cases(NumberCase.singular): "монета",
				.cases(NumberCase.genitive): "монет"
			]
		]).string(.cases(NumberCase(for: count)))
	}
	
	public static let errors: Localized<String>.Dictionary = [
		"unknown": [.ru: "Неизвестная ошибка", .en: "Unknown error"],
		"server": [.ru: "Ошибка сервера", .en: "Server error"]
	]
}
```
## Usage
To get a localized string create `Localized` object:
```swift 
let word = Localized(formsDictionary)
```
where
	`string: String` - default value,
	`formsDictionary: [Language: Localized.Forms]` - dictionary of forms

To get a string for current language use `word.localized`
To get for a custom language or form call
```swift
word.string(language, form)
```
where
	`language: Language` - language, default value is Language.current,
	`form: FormType` - word form (`OptionSet`)
	
Supported forms: none, singular, plural, masculine, feminine, neuter, common and any combination of them.

You can create your own form type (for language cases as example) via `LanguageCaseProtocol` and use it:
```swift
let formType = Localized.FormType.cases(customFormEnum)
```
The repo contains one custom `LanguageCaseProtocol` type `NumberCase` for Russian language as example of usage.

Examples of word with several forms:
```swift
let manWord = Localized<String>([
	.ru: [.singular: "человек", .plural: "люди"],
	.en: [
		[.singular, .masculine]: "man", 
		[.plural, .masculine]: "men",
		[.singular, .feminine]: "woman", 
		[.plural, .feminine]: "women"
	     ],
	 .ja: "人"
])
```
You can combine words to get phrases:
```swift
let tree = Localized<String>([
    .ru: [
        [.neuter, .singular]: "дерево",
        .plural: "деревья"
    ]
])
       
let beautiful = Localized<String>([
    .ru: [
        .plural: "красивые",
        .singular: [.masculine: "красивый", .feminine: "красивая", .neuter: "красивое"]
    ]
])
       
let phrase = beautiful + " " + tree

print(phrase.string(language: .ru, .plural))
    //prints "красивые деревья"
print(phrase.string(language: .ru, .singular))
    //prints "красивое дерево"
```

## Installation

1. [Swift Package Manager](https://github.com/apple/swift-package-manager)

Create a `Package.swift` file.

```swift
// swift-tools-version:5.0
import PackageDescription

let package = Package(
  name: "SomeProject",
  dependencies: [
    .package(url: "https://github.com/dankinsoid/SwiftLocalize.git", from: "1.9.0")
  ],
  targets: [
    .target(name: "SomeProject", dependencies: ["SwiftLocalize"])
  ]
)
```
	
```ruby
$ swift build
```

2.  [CocoaPods](https://cocoapods.org)

Add the following line to your Podfile:
```ruby
pod 'SwiftLocalize'
```
and run `pod update` from the podfile directory first.
	
## Author

Voidilov, voidilov@gmail.com

## License

SwiftLocalize is available under the MIT license. See the LICENSE file for more info.
