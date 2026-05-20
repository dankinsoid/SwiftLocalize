import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
	[
		testCase(AppStringsExampleTests.allTests),
	]
}
#endif
