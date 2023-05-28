import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
	[
		testCase(SwiftLocalizeTests.allTests),
	]
}
#endif
