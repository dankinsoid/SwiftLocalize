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

public enum Strings {

	public static let ok = Word("Ok", [.ru: "Да"]).localized
	public static let never = Word("Never", [.ru: "Никогда"]).localized
	public static let later = Word("Later", [.ru: "Позже"]).localized
	public static let error = Word("Error",  [.ru: "Ошибка"]).localized

	public static let coins = Word(
	"coins", [
	.ru: [
		.cases(NumberCase.accusative): "монеты",
		.cases(NumberCase.singular): "монета",
		.cases(NumberCase.genitive): "монет"
		]
	])
	//Strings.coins.string(.cases(NumberCase(for: someInt)))
	
	public static let errors: Word.Dictionary = [
		"unknown": [.ru: "Неизвестная ошибка", .en: "Unknown error"],
		"server": [.ru: "Ошибка сервера", .en: "Server error"]
	]

}
```
## Usage
To get a localized string create `Word` object:
```swift 
let word = Word(string, formsDictionary)
```
where
	`string: String` - default value,
	`formsDictionary: [Language: Word.Forms]` - dictionary of forms

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
let formType = Word.FormType.cases(customFormEnum)
```
The repo contains one custom `LanguageCaseProtocol` type `NumberCase` for Russian language as example of usage.

Examples of word with several forms:
```swift
let manWord = Word("man", [
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
let tree = Word("tree", [
    .ru: [
        [.neuter, .singular]: "дерево",
        .plural: "деревья"
    ]
])
       
let beautiful = Word("beautiful", [
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

1.  [CocoaPods](https://cocoapods.org)

Add the following line to your Podfile:
```ruby
pod 'SwiftLocalize'
```
and run `pod update` from the podfile directory first.
	
2. [Swift Package Manager](https://github.com/apple/swift-package-manager)

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
## Author

Voidilov, voidilov@gmail.com

## License

SwiftLocalize is available under the MIT license. See the LICENSE file for more info.
