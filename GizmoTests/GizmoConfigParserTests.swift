import XCTest
@testable import Gizmo

final class GizmoConfigParserTests: XCTestCase {
  private let parser = GizmoConfigParser()

  func testParseCustomMenubarWithValidValues() throws {
    let result = parser.parse(
      """
      config-version = 1

      [custom_menubar]
      enabled = true
      display_scope = "active"
      height = 32
      widgets = ["clock", "front_app"]
      background_opacity = 0.6
      horizontal_padding = 12
      clock_24h = false
      """
    )

    XCTAssertNotNil(result.config)
    XCTAssertTrue(result.errors.isEmpty)

    let config = try XCTUnwrap(result.config)
    XCTAssertTrue(config.customMenubar.enabled)
    XCTAssertEqual(config.customMenubar.displayScope, .active)
    XCTAssertEqual(config.customMenubar.height, 32)
    XCTAssertEqual(config.customMenubar.widgets, [.clock, .frontApp])
    XCTAssertEqual(config.customMenubar.backgroundOpacity, 0.6)
    XCTAssertEqual(config.customMenubar.horizontalPadding, 12)
    XCTAssertFalse(config.customMenubar.clock24h)
  }

  func testInvalidDisplayScopeReturnsError() {
    let result = parser.parse(
      """
      config-version = 1

      [custom_menubar]
      display_scope = "invalid"
      """
    )

    XCTAssertNil(result.config)
    XCTAssertTrue(result.errors.contains { $0.contains("custom_menubar.display_scope") })
  }

  func testInvalidWidgetsReturnsError() {
    let result = parser.parse(
      """
      config-version = 1

      [custom_menubar]
      widgets = ["clock", "nope"]
      """
    )

    XCTAssertNil(result.config)
    XCTAssertTrue(result.errors.contains { $0.contains("custom_menubar.widgets") })
  }

  func testOutOfRangeOpacityReturnsError() {
    let result = parser.parse(
      """
      config-version = 1

      [custom_menubar]
      background_opacity = 1.4
      """
    )

    XCTAssertNil(result.config)
    XCTAssertTrue(result.errors.contains { $0.contains("custom_menubar.background_opacity") })
  }

  func testUnknownCustomMenubarKeyReturnsError() {
    let result = parser.parse(
      """
      config-version = 1

      [custom_menubar]
      mystery = true
      """
    )

    XCTAssertNil(result.config)
    XCTAssertTrue(result.errors.contains { $0.contains("custom_menubar.mystery") })
  }

  func testCustomMenubarDefaultsWhenSectionMissing() {
    let result = parser.parse(
      """
      config-version = 1
      """
    )

    XCTAssertNotNil(result.config)
    XCTAssertTrue(result.errors.isEmpty)

    let config = try? XCTUnwrap(result.config)
    XCTAssertEqual(config?.customMenubar, .default)
  }
}
