//
//  HandleView.swift
//  PaneViewController
//
//  Created by Branden Russell on 3/29/16.
//  Copyright © 2016 Intellectual Reserve, Inc. All rights reserved.
//

import UIKit

protocol HandleViewDelegate: class {
    
    func hitTest(point: CGPoint, withEvent event: UIEvent?, inView: UIView) -> UIView?
    
}

class HandleView: UIView {
    
    weak var delegate: HandleViewDelegate?
    
    override func hitTest(point: CGPoint, withEvent event: UIEvent?) -> UIView? {
        guard userInteractionEnabled else { return nil }
        
        return delegate?.hitTest(point, withEvent: event, inView: self) ?? super.hitTest(point, withEvent: event)
    }
    
}
