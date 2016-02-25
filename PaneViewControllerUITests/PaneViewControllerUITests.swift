//
//  PaneViewControllerUITests.swift
//  PaneViewControllerUITests
//
//  Created by Branden Russell on 2/25/16.
//  Copyright © 2016 Intellectual Reserve, Inc. All rights reserved.
//

import XCTest

@available(iOS 9.0, *)
class PaneViewControllerUITests: XCTestCase {
        
    override func setUp() {
        super.setUp()
        
        continueAfterFailure = false
        XCUIApplication().launch()
    }
    
    func testPrimaryAndSecondaryViewsAppearInRegularHorizontal() {
        let app = XCUIApplication()
        if app.windows.elementBoundByIndex(0).horizontalSizeClass == .Regular {
            XCTAssertTrue(app.staticTexts["Primary View"].exists)
            XCTAssertTrue(app.staticTexts["Secondary View"].exists)
        }
    }
    
    func testOnlyPrimaryViewAppearsInCompactHorizontal() {
        let app = XCUIApplication()
        if app.windows.elementBoundByIndex(0).horizontalSizeClass == .Compact {
            XCTAssertTrue(app.staticTexts["Primary View"].exists)
            XCTAssertFalse(app.staticTexts["Secondary View"].exists)
        }
    }
    
    func testShowHideModalInCompact() {
        let app = XCUIApplication()
        if app.windows.elementBoundByIndex(0).horizontalSizeClass == .Compact {
            XCTAssertTrue(app.staticTexts["Primary View"].hittable)
            app.buttons["Show"].tap()
            // Now it should show the Secondary View over the Primary
            XCTAssertFalse(app.staticTexts["Primary View"].hittable)
            XCTAssertTrue(app.staticTexts["Secondary View"].hittable)
            // Now close the drawer
            app.buttons["X"].tap()
            XCTAssertTrue(app.staticTexts["Primary View"].hittable)
        }
    }
    
}
