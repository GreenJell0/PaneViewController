//
//  UIViewControllerPaneViewExtension.swift
//  PaneViewController
//
//  Created by Branden Russell on 2/25/16.
//  Copyright © 2016 Intellectual Reserve, Inc. All rights reserved.
//

import UIKit

public protocol PaneViewControllerProtocol {
    
    func showSecondaryViewAnimated(animated: Bool)
    func dismissSecondaryViewAnimated(animated: Bool)
    
}

extension UIViewController: PaneViewControllerProtocol {
    
    public func paneViewController() -> PaneViewController? {
        return self as? PaneViewController ?? parentViewController?.paneViewController()
    }
    
    public func showSecondaryViewAnimated(animated: Bool) {
        parentViewController?.showSecondaryViewAnimated(animated)
    }
    
    public func dismissSecondaryViewAnimated(animated: Bool) {
        parentViewController?.dismissSecondaryViewAnimated(animated)
    }
    
}
