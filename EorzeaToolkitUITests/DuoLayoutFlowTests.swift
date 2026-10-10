import XCTest
import UIKit

/// Runtime smoke + screenshot evidence, not pixel comparison or live-fold automation.
@MainActor
final class DuoLayoutFlowTests: XCTestCase {
    func testTraditionalChineseDefault() {
        runFlow(language: "zh-Hant", accessibility: false)
    }

    func testEnglishDefault() {
        runFlow(language: "en", accessibility: false)
    }

    func testTraditionalChineseAccessibility() {
        runFlow(language: "zh-Hant", accessibility: true)
    }

    func testEnglishAccessibility() {
        runFlow(language: "en", accessibility: true)
    }

    private func runFlow(language: String, accessibility: Bool) {
        continueAfterFailure = false
        let app = XCUIApplication()
        defer { app.terminate() }
        launch(app, language: language, accessibility: false)
        let firstCard = app.buttons["home.feature.itemSearch"]
        XCTAssertTrue(firstCard.waitForExistence(timeout: 10))
        let normalHeight = firstCard.frame.height

        if accessibility {
            app.terminate()
            launch(app, language: language, accessibility: true)
            XCTAssertTrue(firstCard.waitForExistence(timeout: 10))
            // This fails if the runtime ignores the Dynamic Type override.
            XCTAssertGreaterThan(firstCard.frame.height, normalHeight)
        }

        let context = "\(language)-\(accessibility ? "AX5" : "large")"
        let homeScroll = app.scrollViews.firstMatch
        capture(app, "\(context)-home-top")
        for feature in ["itemSearch", "treasureMap", "relicWeapon", "miniCactpot", "skillRotation"] {
            let card = app.buttons["home.feature.\(feature)"]
            reveal(card, scrolling: homeScroll)
            XCTAssertTrue(card.isHittable)
            XCTAssertGreaterThan(card.frame.width, 0)
            // Compare with the containing view, not XCUIApplication's global frame:
            // multi-display runtimes can report that frame in a different orientation.
            XCTAssertGreaterThanOrEqual(card.frame.minX, homeScroll.frame.minX - 1)
            XCTAssertLessThanOrEqual(card.frame.maxX, homeScroll.frame.maxX + 1)
            capture(app, "\(context)-home-\(feature)")
            card.tap()
            // Each destination owns a distinct Home control; a wrong/no-op card
            // action cannot satisfy another feature's identifier.
            let returnHome = app.buttons["navigation.home.\(feature)"]
            XCTAssertTrue(returnHome.waitForExistence(timeout: 10))
            XCTAssertTrue(returnHome.isHittable)
            XCTAssertFalse(card.exists)
            capture(app, "\(context)-destination-\(feature)")
            returnHome.tap()
            XCTAssertTrue(firstCard.waitForExistence(timeout: 5))
        }

        // Return to the top by scrolling, without resetting app or persistent data.
        let maps = app.buttons["home.feature.treasureMap"]
        reveal(maps, scrolling: app.scrollViews.firstMatch, upwards: false)
        maps.tap()
        let openFilter = app.buttons["treasureMap.filter.open"]
        XCTAssertTrue(openFilter.waitForExistence(timeout: 10))
        XCTAssertTrue(openFilter.isHittable)
        capture(app, "\(context)-map-list")
        openFilter.tap()

        assertFilterTitle(app, language: language)
        capture(app, "\(context)-filter-title-opened")

        let version = app.buttons["treasureMap.filter.version.2"]
        let level = app.buttons["treasureMap.filter.level.40"]
        let form = app.descendants(matching: .any)["treasureMap.filter.form"].firstMatch
        let done = app.buttons["treasureMap.filter.done"]
        let selected = language == "en" ? "Selected" : "已選取"
        let notSelected = language == "en" ? "Not selected" : "未選取"
        reveal(version, scrolling: form)
        XCTAssertEqual(version.value as? String, notSelected)
        version.tap()
        XCTAssertEqual(version.value as? String, selected)
        reveal(level, scrolling: form)
        level.tap()
        XCTAssertEqual(level.value as? String, selected)
        capture(app, "\(context)-filter-selected")
        XCTAssertTrue(done.isHittable)
        done.tap()

        XCTAssertTrue(openFilter.waitForExistence(timeout: 5))
        let activeFilterValue = openFilter.value as? String
        XCTAssertNotNil(activeFilterValue)
        openFilter.tap()
        assertFilterTitle(app, language: language)
        capture(app, "\(context)-filter-title-reopened")
        reveal(version, scrolling: form)
        XCTAssertEqual(version.value as? String, selected)
        reveal(level, scrolling: form)
        XCTAssertEqual(level.value as? String, selected)
        capture(app, "\(context)-filter-reopened")
        done.tap()

        let row = app.buttons["treasureMap.row.timeworn_leather_map"]
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        XCTAssertTrue(row.isHittable)
        // The row contains a separate gathering button at its center. Tap its grade,
        // which belongs to the NavigationLink, rather than that nested action.
        let grade = row.staticTexts["treasureMap.grade.timeworn_leather_map"]
        XCTAssertTrue(grade.isHittable)
        grade.tap()
        let detail = app.descendants(matching: .any)["treasureMap.detail.timeworn_leather_map"].firstMatch
        XCTAssertTrue(detail.waitForExistence(timeout: 5))
        XCTAssertTrue(app.navigationBars["G1"].exists)
        capture(app, "\(context)-G1-detail")

        let home = app.buttons["navigation.home.treasureMap"]
        // Regression expectations for the compact (402pt) / expanded (951pt)
        // fixtures, not a new production breakpoint. Never accept either mode
        // just because one happened to render: wide must keep sidebar + detail.
        if app.windows.firstMatch.frame.width >= 700 {
            XCTAssertTrue(home.isHittable)
            XCTAssertTrue(openFilter.isHittable)
            XCTAssertTrue(detail.exists)
            // Duo exposes both List and navigation-bar accessibility frames
            // across the window. Check detail presence with an operable sidebar;
            // visual placement is covered by the separate manual acceptance.
        } else {
            XCTAssertFalse(home.exists && home.isHittable)
            let back = app.navigationBars["G1"].buttons.firstMatch
            XCTAssertTrue(back.isHittable)
            back.tap()
        }
        XCTAssertTrue(openFilter.waitForExistence(timeout: 5))
        XCTAssertTrue(openFilter.isHittable)
        XCTAssertEqual(openFilter.value as? String, activeFilterValue)
        openFilter.tap()
        reveal(version, scrolling: form)
        XCTAssertEqual(version.value as? String, selected)
        reveal(level, scrolling: form)
        XCTAssertEqual(level.value as? String, selected)
        let clear = app.buttons["treasureMap.filter.clear"]
        XCTAssertTrue(clear.isEnabled)
        clear.tap()
        XCTAssertFalse(clear.isEnabled)
        done.tap()
        XCTAssertTrue(home.isHittable)
        home.tap()
        XCTAssertTrue(firstCard.waitForExistence(timeout: 5))
    }

    private func assertFilterTitle(_ app: XCUIApplication, language: String) {
        let title = app.staticTexts["treasureMap.filter.title"]
        XCTAssertTrue(title.waitForExistence(timeout: 5))
        XCTAssertTrue(title.isHittable)
        XCTAssertEqual(title.label, language == "en" ? "Filter Treasure Maps" : "篩選藏寶圖")
        XCTAssertTrue(app.buttons["treasureMap.filter.done"].isHittable)
        XCTAssertTrue(app.buttons["treasureMap.filter.clear"].exists)
        // Accessibility labels remain complete even when glyphs truncate.
        // The accompanying screenshots require a separate visual review.
    }

    private func launch(_ app: XCUIApplication, language: String, accessibility: Bool) {
        app.launchArguments = [
            "-AppleLanguages", "(\(language))",
            "-AppleLocale", language == "en" ? "en_US" : "zh_TW",
            "-UIPreferredContentSizeCategoryName",
            accessibility
                ? UIContentSizeCategory.accessibilityExtraExtraExtraLarge.rawValue
                : UIContentSizeCategory.large.rawValue
        ]
        app.launch()
    }

    private func reveal(_ element: XCUIElement, scrolling container: XCUIElement, upwards: Bool = true) {
        XCTAssertTrue(container.waitForExistence(timeout: 5))
        for _ in 0..<20 {
            var scrollUp = upwards
            if element.exists {
                let viewport = container.frame
                let center = CGPoint(x: element.frame.midX, y: element.frame.midY)
                // Do not ask the runtime to hit-test an offscreen cell. Some Duo
                // snapshots throw instead of returning false for those cells.
                let lowerLimit = viewport.minY + viewport.height * 0.15
                let upperLimit = viewport.maxY - viewport.height * 0.05
                if center.y >= lowerLimit && center.y <= upperLimit && element.isHittable {
                    return
                }
                scrollUp = center.y > viewport.midY
            }
            // Short, container-relative drags avoid jumping over a row in a popover.
            let start = container.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: scrollUp ? 0.7 : 0.4))
            let end = container.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: scrollUp ? 0.4 : 0.7))
            start.press(forDuration: 0.05, thenDragTo: end)
        }
        XCTFail("Could not reveal \(element.identifier)")
    }

    private func capture(_ app: XCUIApplication, _ name: String) {
        let window = app.windows.firstMatch
        let size = "\(Int(window.frame.width))x\(Int(window.frame.height))"
        let attachment = XCTAttachment(screenshot: window.screenshot())
        attachment.name = "\(name)-\(size)"
        attachment.lifetime = .keepAlways
        add(attachment)
        if name.hasSuffix("home-top") {
            let hierarchy = XCTAttachment(string: app.debugDescription)
            hierarchy.name = "\(name)-hierarchy"
            hierarchy.lifetime = .keepAlways
            add(hierarchy)
        }
    }
}
