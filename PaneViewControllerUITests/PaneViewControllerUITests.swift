//
// Copyright (c) 2019 GreenJell0
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//

import XCTest

@available(iOS 9.0, *)
class PaneViewControllerUITests: XCTestCase {
        
    override func setUp() {
        super.setUp()
        
        continueAfterFailure = false
        XCUIApplication().launch()
    }
    
    // TODO: Xcode is currently having several problems with this test and I can't get it to run locally to work it out
    /* func testShowHideSide() {
        let app = XCUIApplication()
        XCTAssertTrue(app.staticTexts["Primary View"].hittable)
        app.buttons["Show"].tap()
        // The primary view should be covered in Compact, but not in Regular
        if app.windows.elementBoundByIndex(0).horizontalSizeClass == .Compact {
            XCTAssertFalse(app.staticTexts["Primary View"].hittable)
        } else {
            XCTAssertTrue(app.staticTexts["Primary View"].hittable)
        }
        XCTAssertTrue(app.staticTexts["Secondary View"].hittable)
        // Now close the drawer
        app.buttons["X"].tap()
        XCTAssertTrue(app.staticTexts["Primary View"].hittable)
    } */
    
}
