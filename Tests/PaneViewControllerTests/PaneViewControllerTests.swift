//
// Copyright (c) 2021 GreenJell0
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
import PaneViewController
@testable import PaneViewControllerDemo

class PaneViewControllerTests: XCTestCase {
    
    func testAddingPrimaryViewControllerInInit() {
        let demoPrimaryViewController = DemoPrimaryViewController()
        let demoSecondaryViewController = DemoSecondaryViewController()
        let paneViewController = PaneViewController(primaryViewController: demoPrimaryViewController, secondaryViewController: demoSecondaryViewController)
        XCTAssertEqual(paneViewController.primaryViewController, demoPrimaryViewController)
        XCTAssertEqual(paneViewController.secondaryViewController, demoSecondaryViewController)
    }
    
    func testGettingPaneViewControllerFromPaneViewController() {
        let paneViewController = PaneViewController(primaryViewController: DemoPrimaryViewController(), secondaryViewController: DemoSecondaryViewController())
        XCTAssertEqual(paneViewController.paneViewController, paneViewController)
    }
    
    func testGettingPaneViewControllerFromPrimary() {
        let demoPrimaryViewController = DemoPrimaryViewController()
        let paneViewController = PaneViewController(primaryViewController: demoPrimaryViewController, secondaryViewController: DemoSecondaryViewController())
        XCTAssertEqual(demoPrimaryViewController.paneViewController, paneViewController)
    }
    
    func testGettingCurrentPaneViewControllerFromNavStackViewControllerInPrimary() {
        let primaryNavigationViewController = UINavigationController(rootViewController: DemoPrimaryViewController())
        let pushedOnViewController = UIViewController()
        primaryNavigationViewController.pushViewController(pushedOnViewController, animated: false)
        let paneViewController = PaneViewController(primaryViewController: primaryNavigationViewController, secondaryViewController: DemoSecondaryViewController())
        XCTAssertEqual(pushedOnViewController.paneViewController, paneViewController)
    }
    
}
