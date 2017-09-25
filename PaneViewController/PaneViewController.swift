//
// Copyright (c) 2016 Hilton Campbell
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

import UIKit
import ObserverSet

@objc public enum PaneViewPinningState: Int {
    case openDefault = 1
    case openHalf = 2
    case closed = 3
    
    func paneViewWidth(forScreenWidth width: CGFloat) -> CGFloat {
        switch self {
        case .openDefault:
            return PaneViewController.minimumWidth
        case .openHalf:
            return width / 2.0
        case .closed:
            return 0
        }
    }
    
    static func all() -> [PaneViewPinningState] {
        return [.openDefault, .openHalf, .closed]
    }
}

open class PaneViewController: UIViewController {
    
    fileprivate static let minimumWidth: CGFloat = 320
    
    public enum PresentationMode {
        case sideBySide
        case modal
    }
    
    public let primaryViewController: UIViewController
    public let secondaryViewController: UIViewController
    public let primaryViewWillChangeWidthObservers = ObserverSet<UIView>()
    public let primaryViewDidChangeWidthObservers = ObserverSet<UIView>()
    public weak var delegate: PaneViewControllerDelegate?
    
    public private(set) var presentationMode = PresentationMode.modal
    public private(set) var isSecondaryViewShowing = false
    public var primaryViewToBlur: UIView?
    public var secondaryViewToBlur: UIView?
    public var shouldBlurWhenSideBySideResizes = true
    public var shouldAllowDragModal = true
    public var handleColor = UIColor(red: 197.0 / 255.0, green: 197.0 / 255.0, blue: 197.0 / 255.0, alpha: 0.5) {
        didSet {
            if isViewLoaded {
                handleView.backgroundColor = handleColor
            }
        }
    }
    public var paneSeparatorColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.16) {
        didSet {
            if isViewLoaded {
                paneSeparatorView.backgroundColor = paneSeparatorColor
            }
        }
    }
    public var modalShadowColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.1) {
        didSet {
            if isViewLoaded {
                modalShadowView.backgroundColor = modalShadowColor
            }
        }
    }
    
    public lazy var panGestureRecognizer: UIPanGestureRecognizer = {
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(panGestureRecognized))
        panGestureRecognizer.delegate = self
        return panGestureRecognizer
    }()
    public lazy var modalShadowCloseTapGestureRecognizer: UITapGestureRecognizer = {
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapGestureRecognized))
        return tapGestureRecognizer
    }()
    public lazy var modalHandleCloseTapGestureRecognizer: UITapGestureRecognizer = {
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapGestureRecognized))
        return tapGestureRecognizer
    }()
    
    public var modalOpenGap = CGFloat(20)
    
    private var touchStartedDownInHandle = false
    private var touchStartedWithSecondaryOpen = false
    
    private var secondaryViewContainerTrailingConstraint: NSLayoutConstraint?
    
    private var secondaryViewSideContainerCurrentWidthConstraint: NSLayoutConstraint?
    private var secondaryViewSideContainerDraggingWidthConstraint: NSLayoutConstraint?
    private var secondaryViewModalContainerHiddenLeadingConstraint: NSLayoutConstraint?
    private var secondaryViewModalContainerShowingLeadingConstraint: NSLayoutConstraint?
    private var secondaryViewModalContainerWidthConstraint: NSLayoutConstraint?
    private var secondaryViewModalContainerOpenLocation = CGFloat(0)
    private var paneViewPinningState = PaneViewPinningState.closed
    private var previousPaneViewPinningState = PaneViewPinningState.closed
    private var modalStartLocationX: CGFloat?
    
    fileprivate lazy var secondaryViewSideContainerView: UIView = {
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.clipsToBounds = true
        return containerView
    }()
    fileprivate lazy var secondaryViewModalContainerView: UIView = {
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.clipsToBounds = true
        return containerView
    }()
    private lazy var modalShadowView: UIView = {
        let shadowView = UIView()
        shadowView.alpha = 0
        shadowView.backgroundColor = self.modalShadowColor
        shadowView.translatesAutoresizingMaskIntoConstraints = false
        return shadowView
    }()
    private lazy var modalShadowImageView: UIImageView = {
        let shadowImageView = UIImageView(image: UIImage(named: "modalEdgeShadow", in: Bundle(for: PaneViewController.self), compatibleWith: nil))
        shadowImageView.alpha = 0
        shadowImageView.translatesAutoresizingMaskIntoConstraints = false
        return shadowImageView
    }()
    private lazy var sideHandleTouchView: UIView = {
        let touchHandleView = HandleView()
        touchHandleView.delegate = self
        touchHandleView.backgroundColor = .clear
        touchHandleView.translatesAutoresizingMaskIntoConstraints = false
        return touchHandleView
    }()
    private lazy var modalHandleTouchView: UIView = {
        let touchHandleView = HandleView()
        touchHandleView.delegate = self
        touchHandleView.backgroundColor = .clear
        touchHandleView.translatesAutoresizingMaskIntoConstraints = false
        return touchHandleView
    }()
    private lazy var handleView: UIView = {
        let handleView = UIView()
        handleView.translatesAutoresizingMaskIntoConstraints = false
        handleView.layer.cornerRadius = 2
        handleView.backgroundColor = self.handleColor
        return handleView
    }()
    private lazy var paneSeparatorView: UIView = {
        let separatorView = UIView()
        separatorView.translatesAutoresizingMaskIntoConstraints = false
        separatorView.backgroundColor = self.paneSeparatorColor
        return separatorView
    }()
    private lazy var sideHandleView: UIView = {
        let sideHandleView = UIView()
        sideHandleView.translatesAutoresizingMaskIntoConstraints = false
        sideHandleView.backgroundColor = UIColor.clear
        sideHandleView.addSubview(self.handleView)
        sideHandleView.addSubview(self.paneSeparatorView)
        let views = ["handleView": self.handleView, "paneSeparatorView": self.paneSeparatorView]
        let separatorLineWidth: CGFloat = 1.0 / UIScreen.main.scale
        let metrics = ["separatorLineWidth": separatorLineWidth]
        sideHandleView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "|[paneSeparatorView(==separatorLineWidth)]-3-[handleView(==4)]", options: [], metrics: metrics, views: views))
        sideHandleView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:[handleView(==44)]", options: [], metrics: nil, views: views))
        sideHandleView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[paneSeparatorView]|", options: [], metrics: nil, views: views))
        sideHandleView.addConstraint(NSLayoutConstraint(item: self.handleView, attribute: .centerY, relatedBy: .equal, toItem: sideHandleView, attribute: .centerY, multiplier: 1, constant: 0))
        return sideHandleView
    }()
    private lazy var primaryVisualEffectView: UIVisualEffectView = {
        let visualEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .light))
        visualEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        return visualEffectView
    }()
    private lazy var secondaryVisualEffectView: UIVisualEffectView = {
        let visualEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .light))
        visualEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        return visualEffectView
    }()
    
    public init(primaryViewController: UIViewController, secondaryViewController: UIViewController) {
        self.primaryViewController = primaryViewController
        self.secondaryViewController = secondaryViewController
        
        super.init(nibName: nil, bundle: nil)
        
        addChildViewController(primaryViewController)
        primaryViewController.didMove(toParentViewController: self)
        
        addChildViewController(secondaryViewController)
        secondaryViewController.didMove(toParentViewController: self)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        
        view.clipsToBounds = true
        
        primaryViewController.view.frame = view.bounds
        primaryViewController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(primaryViewController.view)
        view.addSubview(secondaryViewSideContainerView)
        view.addSubview(secondaryViewModalContainerView)
        view.addSubview(sideHandleTouchView)
        view.addSubview(modalHandleTouchView)
        
        primaryViewController.view.addSubview(modalShadowView)
        
        let views: [String: Any] = ["view": view, "primaryView": primaryViewController.view, "secondaryViewSideContainerView": secondaryViewSideContainerView, "secondaryViewModalContainerView": secondaryViewModalContainerView, "sideHandleView": sideHandleView, "modalShadowView": modalShadowView, "sideHandleTouchView": sideHandleTouchView, "modalHandleTouchView": modalHandleTouchView]
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "|[primaryView][secondaryViewSideContainerView]", options: [], metrics: nil, views: views))
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[primaryView]|", options: [], metrics: nil, views: views))
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[secondaryViewSideContainerView]|", options: [], metrics: nil, views: views))
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[secondaryViewModalContainerView]|", options: [], metrics: nil, views: views))
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[sideHandleTouchView]|", options: [], metrics: nil, views: views))
        let secondaryViewModalContainerWidthConstraint = NSLayoutConstraint(item: secondaryViewModalContainerView, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: view.bounds.width)
        secondaryViewModalContainerView.addConstraint(secondaryViewModalContainerWidthConstraint)
        self.secondaryViewModalContainerWidthConstraint = secondaryViewModalContainerWidthConstraint
        
        primaryViewController.view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "|[modalShadowView]|", options: [], metrics: nil, views: views))
        primaryViewController.view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[modalShadowView]|", options: [], metrics: nil, views: views))
        
        secondaryViewSideContainerView.addSubview(sideHandleView)
        
        let secondaryViewContainerTrailingConstraint = NSLayoutConstraint(item: secondaryViewSideContainerView, attribute: .trailing, relatedBy: .equal, toItem: view, attribute: .trailing, multiplier: 1, constant: 0)
        view.addConstraint(secondaryViewContainerTrailingConstraint)
        self.secondaryViewContainerTrailingConstraint = secondaryViewContainerTrailingConstraint
        
        let secondaryViewSideContainerWidthConstraint = NSLayoutConstraint(item: secondaryViewSideContainerView, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 0)
        secondaryViewSideContainerView.addConstraint(secondaryViewSideContainerWidthConstraint)
        self.secondaryViewSideContainerDraggingWidthConstraint = secondaryViewSideContainerWidthConstraint
        secondaryViewSideContainerDraggingWidthConstraint?.isActive = false
        secondaryViewSideContainerView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "|[sideHandleView(==10)]", options: [], metrics: nil, views: views))
        secondaryViewSideContainerView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[sideHandleView]|", options: [], metrics: nil, views: views))
        // We need a constraint for the width to make it off screen
        updateSecondaryViewSideBySideConstraint(forPinningState: .closed)
        
        let secondaryViewModalContainerHiddenLeadingConstraint = NSLayoutConstraint(item: secondaryViewModalContainerView, attribute: .leading, relatedBy: .equal, toItem: view, attribute: .trailing, multiplier: 1, constant: 0)
        let secondaryViewModalContainerShowingLeadingConstraint = NSLayoutConstraint(item: secondaryViewModalContainerView, attribute: .leading, relatedBy: .equal, toItem: view, attribute: .leading, multiplier: 1, constant: 0)
        view.addConstraint(secondaryViewModalContainerHiddenLeadingConstraint)
        view.addConstraint(secondaryViewModalContainerShowingLeadingConstraint)
        secondaryViewModalContainerShowingLeadingConstraint.isActive = false
        self.secondaryViewModalContainerHiddenLeadingConstraint = secondaryViewModalContainerHiddenLeadingConstraint
        self.secondaryViewModalContainerShowingLeadingConstraint = secondaryViewModalContainerShowingLeadingConstraint
        
        // Center the side touch to the handle view
        sideHandleTouchView.addConstraint(NSLayoutConstraint(item: sideHandleTouchView, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 88))
        view.addConstraint(NSLayoutConstraint(item: sideHandleTouchView, attribute: .centerX, relatedBy: .equal, toItem: handleView, attribute: .centerX, multiplier: 1, constant: 0))
        view.addConstraint(NSLayoutConstraint(item: sideHandleTouchView, attribute: .centerY, relatedBy: .equal, toItem: handleView, attribute: .centerY, multiplier: 1, constant: 0))
        
        modalHandleTouchView.addConstraint(NSLayoutConstraint(item: modalHandleTouchView, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 110))
        view.addConstraint(NSLayoutConstraint(item: modalHandleTouchView, attribute: .leading, relatedBy: .equal, toItem: secondaryViewModalContainerView, attribute: .leading, multiplier: 1, constant: -44))
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[modalHandleTouchView]|", options: [], metrics: nil, views: views))
        
        updateSecondaryViewLocationForTraitCollection(traitCollection)
        
        updateSizeClassOfChildViewControllers()
        
        view.addGestureRecognizer(panGestureRecognizer)
        modalShadowView.addGestureRecognizer(modalShadowCloseTapGestureRecognizer)
        modalHandleTouchView.addGestureRecognizer(modalHandleCloseTapGestureRecognizer)
    }
    
    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if !touchStartedDownInHandle {
            // Find the narrow side and make it so the modal only goes out that far, even in the other orientation
            if traitCollection.horizontalSizeClass == .compact || traitCollection.verticalSizeClass == .compact {
                let narrowestSide = min(view.bounds.height, view.bounds.width)
                secondaryViewModalContainerOpenLocation = view.bounds.width - narrowestSide
                secondaryViewModalContainerWidthConstraint?.constant = narrowestSide
                
                if isSecondaryViewShowing {
                    secondaryViewModalContainerShowingLeadingConstraint?.constant = secondaryViewModalContainerOpenLocation
                }
            } else {
                secondaryViewModalContainerOpenLocation = 0
            }
        }
    }
    
    override open func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        super.willTransition(to: newCollection, with: coordinator)
        
        // If they're going from Regular to Compact, save off the width enum so we can restore it if they go back
        if newCollection.horizontalSizeClass == .compact && traitCollection.horizontalSizeClass == .regular {
            previousPaneViewPinningState = paneViewPinningState
        }
        
        // We also want to show the default side view had they not had the side view showing, but did have the modal showing
        if newCollection.horizontalSizeClass == .regular && traitCollection.horizontalSizeClass == .compact && previousPaneViewPinningState == .closed && isSecondaryViewShowing {
            previousPaneViewPinningState = .openDefault
        }
        
        // Close the secondary view if we're changing from compact to regular or regular to compact
        if newCollection.horizontalSizeClass != traitCollection.horizontalSizeClass {
            dismissSecondaryViewAnimated(false)
        }
        
        updateSecondaryViewLocationForTraitCollection(newCollection)
        
        // If we're going back to Regular from Compact, restore the secondary view width enum
        if newCollection.horizontalSizeClass == .regular && traitCollection.horizontalSizeClass == .compact {
            updateSecondaryViewSideBySideConstraint(forPinningState: previousPaneViewPinningState)
        }
    }
    
    open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        updateSizeClassOfChildViewControllers()
    }
    
    open override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        coordinator.animate(alongsideTransition: { _ in
            self.updateSizeClassOfChildViewControllers()
        }, completion: nil)
    }
    
    @objc func panGestureRecognized(_ gestureRecognizer: UIPanGestureRecognizer) {
        switch gestureRecognizer.state {
        case .began:
            // Ignore if they're moving up/down too much
            guard abs(gestureRecognizer.velocity(in: view).y) < abs(gestureRecognizer.velocity(in: view).x) else { break }
            
            touchStartedWithSecondaryOpen = isSecondaryViewShowing
            
            delegate?.paneViewControllerDidStartPanning(self)
            
            switch presentationMode {
            case .sideBySide:
                if sideHandleTouchView.frame.contains(gestureRecognizer.location(in: view)) {
                    primaryViewWillChangeWidthObservers.notify(primaryViewController.view)
                    touchStartedDownInHandle = true
                    secondaryViewSideContainerDraggingWidthConstraint?.constant = secondaryViewSideContainerView.bounds.width
                    secondaryViewSideContainerDraggingWidthConstraint?.isActive = true
                    secondaryViewSideContainerCurrentWidthConstraint?.isActive = false
                    
                    blurIfNeeded()
                }
            case .modal:
                modalStartLocationX = gestureRecognizer.location(in: secondaryViewController.view).x
                
                if modalHandleTouchView.frame.contains(gestureRecognizer.location(in: view)) ||
                    (shouldAllowDragModal && secondaryViewModalContainerView.frame.contains(gestureRecognizer.location(in: view))) {
                    // This allows the view to be dragged onto the screen from the right
                    if !isSecondaryViewShowing {
                        isSecondaryViewShowing = true
                        modalShadowImageView.alpha = 1
                        secondaryViewModalContainerShowingLeadingConstraint?.constant = view.bounds.width
                        secondaryViewModalContainerHiddenLeadingConstraint?.isActive = false
                        secondaryViewModalContainerShowingLeadingConstraint?.isActive = true
                    }
                    touchStartedDownInHandle = true
                }
            }
        case .changed:
            guard touchStartedDownInHandle else {
                // Cancel the recognition
                gestureRecognizer.isEnabled = false
                gestureRecognizer.isEnabled = true
                return
            }
            
            let location = gestureRecognizer.location(in: view)
            switch presentationMode {
            case .sideBySide:
                let newConstant = abs(location.x - view.bounds.width)
                
                if newConstant < PaneViewController.minimumWidth {
                    secondaryViewContainerTrailingConstraint?.constant = -newConstant + PaneViewController.minimumWidth
                    secondaryViewSideContainerDraggingWidthConstraint?.constant = PaneViewController.minimumWidth
                } else {
                    secondaryViewSideContainerDraggingWidthConstraint?.constant = newConstant
                }
            case .modal:
                secondaryViewModalContainerShowingLeadingConstraint?.constant = max(location.x - modalOpenGap - (modalStartLocationX ?? 0), secondaryViewModalContainerOpenLocation)
                modalShadowView.alpha = 1.0 - (location.x / view.bounds.width)
            }
        case .ended, .failed, .cancelled:
            guard touchStartedDownInHandle else { return }
            
            delegate?.paneViewControllerDidFinishPanning(self)
            modalStartLocationX = nil
            switch presentationMode {
            case .sideBySide:
                secondaryViewSideContainerDraggingWidthConstraint?.isActive = false
                secondaryViewSideContainerCurrentWidthConstraint?.isActive = true
                moveSideViewToPredeterminedPositionClosestToWidthAnimated(true)
                primaryViewDidChangeWidthObservers.notify(primaryViewController.view)
            case .modal:
                // If they tapped or dragged past the first quarter of the screen (if secondary was open) or drag only to the first quarter of the screen (if secondary started closed), close (again)
                let dragVelocity = gestureRecognizer.velocity(in: view).x
                if dragVelocity > 10 ||
                    (dragVelocity > -10 &&
                        (secondaryViewModalContainerShowingLeadingConstraint?.constant ?? 0 > (view.bounds.width * 0.25) + secondaryViewModalContainerOpenLocation && touchStartedWithSecondaryOpen) ||
                        (secondaryViewModalContainerShowingLeadingConstraint?.constant ?? 0 > (view.bounds.width * 0.75) + secondaryViewModalContainerOpenLocation && !touchStartedWithSecondaryOpen)) {
                    secondaryViewModalContainerShowingLeadingConstraint?.constant = secondaryViewModalContainerOpenLocation
                    dismissSecondaryViewAnimated(true)
                } else {
                    // Fake that the view wasn't showing so we can animate back into place
                    isSecondaryViewShowing = false
                    showSecondaryViewAnimated(true)
                }
            }
            
            touchStartedDownInHandle = false
        case .possible:
            break
        }
    }
    
    @objc func tapGestureRecognized(_ gestureRecognizer: UITapGestureRecognizer) {
        switch gestureRecognizer.state {
        case .ended:
            dismissSecondaryViewAnimated(true)
        case _:
            break
        }
    }
    
    // MARK: Methods
    
    override public func showSecondaryViewAnimated(_ animated: Bool, pinningState: PaneViewPinningState = .openDefault) {
        guard !isSecondaryViewShowing else { return }
        
        isSecondaryViewShowing = true
        
        let modalShadowViewAlpha: CGFloat
        switch traitCollection.horizontalSizeClass {
        case .regular:
            modalShadowViewAlpha = 0
            blurIfNeeded()
            primaryViewWillChangeWidthObservers.notify(primaryViewController.view)
            updateSecondaryViewSideBySideConstraint(forPinningState: pinningState)
        case .compact, .unspecified:
            primaryViewController.view.addSubview(modalShadowView)
            modalShadowViewAlpha = 1
            secondaryViewModalContainerShowingLeadingConstraint?.constant = secondaryViewModalContainerOpenLocation
            secondaryViewModalContainerHiddenLeadingConstraint?.isActive = false
            secondaryViewModalContainerShowingLeadingConstraint?.isActive = true
        }
        
        modalShadowImageView.alpha = modalShadowViewAlpha
        let startingHorizontalSizeClass = self.traitCollection.horizontalSizeClass
        UIView.animate(withDuration: animated ? 0.3 : 0, animations: {
            self.view.layoutIfNeeded()
            self.modalShadowView.alpha = modalShadowViewAlpha
        }, completion: { _ in
            self.removeBlurIfNeeded()
            self.updateSizeClassOfChildViewControllers()
            if startingHorizontalSizeClass == .regular {
                self.primaryViewDidChangeWidthObservers.notify(self.primaryViewController.view)
            }
        })
    }
    
    override public func dismissSecondaryViewAnimated(_ animated: Bool) {
        guard isSecondaryViewShowing else { return }
        
        isSecondaryViewShowing = false
        
        switch traitCollection.horizontalSizeClass {
        case .regular:
            blurIfNeeded()
            primaryViewWillChangeWidthObservers.notify(primaryViewController.view)
            updateSecondaryViewSideBySideConstraint(forPinningState: .closed)
        case .compact, .unspecified:
            secondaryViewModalContainerShowingLeadingConstraint?.isActive = false
            secondaryViewModalContainerHiddenLeadingConstraint?.isActive = true
        }
        
        let startingHorizontalSizeClass = self.traitCollection.horizontalSizeClass
        UIView.animate(withDuration: animated ? 0.3 : 0, animations: {
            self.view.layoutIfNeeded()
            self.modalShadowView.alpha = 0
        }, completion: { _ in
            self.modalShadowImageView.alpha = 0
            self.removeBlurIfNeeded()
            self.updateSizeClassOfChildViewControllers()
            if startingHorizontalSizeClass == .regular {
                self.primaryViewDidChangeWidthObservers.notify(self.primaryViewController.view)
            }
        })
    }
    
    private func blurIfNeeded() {
        guard shouldBlurWhenSideBySideResizes && primaryVisualEffectView.superview == nil && secondaryVisualEffectView.superview == nil else { return }
        
        if let primaryView = primaryViewToBlur {
            primaryView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
            primaryView.alpha = 0
            primaryView.frame = primaryViewController.view.bounds
            primaryViewController.view.addSubview(primaryView)
        }
        
        primaryVisualEffectView.alpha = 0
        primaryVisualEffectView.frame = primaryViewController.view.bounds
        primaryViewController.view.addSubview(primaryVisualEffectView)
        
        if let secondaryView = secondaryViewToBlur {
            secondaryView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
            secondaryView.alpha = 0
            secondaryView.frame = secondaryViewController.view.bounds
            secondaryViewController.view.addSubview(secondaryView)
        }
        
        secondaryVisualEffectView.alpha = 0
        secondaryVisualEffectView.frame = secondaryViewController.view.bounds
        secondaryViewController.view.addSubview(secondaryVisualEffectView)
        
        UIView.animate(withDuration: 0.1) {
            self.primaryViewToBlur?.alpha = 1
            self.primaryVisualEffectView.alpha = 1
            self.secondaryViewToBlur?.alpha = 1
            self.secondaryVisualEffectView.alpha = 1
        }
    }
    
    private func removeBlurIfNeeded() {
        guard primaryVisualEffectView.superview != nil && secondaryVisualEffectView.superview != nil else { return }
        
        UIView.animate(withDuration: 0.1, animations: {
            self.primaryViewToBlur?.alpha = 0
            self.primaryVisualEffectView.alpha = 0
            self.secondaryViewToBlur?.alpha = 0
            self.secondaryVisualEffectView.alpha = 0
        }, completion: { _ in
            self.primaryViewToBlur?.removeFromSuperview()
            self.primaryVisualEffectView.removeFromSuperview()
            self.secondaryViewToBlur?.removeFromSuperview()
            self.secondaryVisualEffectView.removeFromSuperview()
        })
    }
    
    private func updateSizeClassOfChildViewControllers() {
        // The vertical size class will be the same as self's
        let compactTraitCollection = UITraitCollection(traitsFrom: [UITraitCollection(verticalSizeClass: traitCollection.verticalSizeClass), UITraitCollection(horizontalSizeClass: .compact)])
        let regularTraitCollection = UITraitCollection(traitsFrom: [UITraitCollection(verticalSizeClass: traitCollection.verticalSizeClass), UITraitCollection(horizontalSizeClass: .regular)])
        
        // If self is Regular, the child controllers may be Compact
        // If self is Compact, the child controllers are all Compact
        switch traitCollection.horizontalSizeClass {
        case .regular:
            // This value seemed to be a good one on iPad to choose when subviews should be compact or not
            setOverrideTraitCollection(primaryViewController.view.bounds.width >= 500 ? regularTraitCollection : compactTraitCollection, forChildViewController: primaryViewController)
            setOverrideTraitCollection(secondaryViewController.view.bounds.width >= 500 ? regularTraitCollection : compactTraitCollection, forChildViewController: secondaryViewController)
        case .compact, .unspecified:
            setOverrideTraitCollection(compactTraitCollection, forChildViewController: primaryViewController)
            setOverrideTraitCollection(compactTraitCollection, forChildViewController: secondaryViewController)
        }
    }
    
    private func updateSecondaryViewSideBySideConstraint(forPinningState pinningState: PaneViewPinningState) {
        if let secondaryViewSideContainerCurrentWidthConstraint = secondaryViewSideContainerCurrentWidthConstraint {
            secondaryViewSideContainerView.removeConstraint(secondaryViewSideContainerCurrentWidthConstraint)
            view.removeConstraint(secondaryViewSideContainerCurrentWidthConstraint)
        }
        
        paneViewPinningState = pinningState
        
        let newSideSecondaryViewWidthConstraint: NSLayoutConstraint
        switch pinningState {
        case .openHalf:
            isSecondaryViewShowing = true
            newSideSecondaryViewWidthConstraint = NSLayoutConstraint(item: secondaryViewSideContainerView, attribute: .width, relatedBy: .equal, toItem: primaryViewController.view, attribute: .width, multiplier: 1, constant: 0)
            view.addConstraint(newSideSecondaryViewWidthConstraint)
        case .openDefault:
            isSecondaryViewShowing = true
            newSideSecondaryViewWidthConstraint = NSLayoutConstraint(item: secondaryViewSideContainerView, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: PaneViewController.minimumWidth)
            secondaryViewSideContainerView.addConstraint(newSideSecondaryViewWidthConstraint)
        case .closed:
            isSecondaryViewShowing = false
            newSideSecondaryViewWidthConstraint = NSLayoutConstraint(item: secondaryViewSideContainerView, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 0)
            secondaryViewSideContainerView.addConstraint(newSideSecondaryViewWidthConstraint)
            secondaryViewContainerTrailingConstraint?.constant = 0
        }
        
        secondaryViewSideContainerCurrentWidthConstraint = newSideSecondaryViewWidthConstraint
    }
    
    private func moveSideViewToPredeterminedPositionClosestToWidthAnimated(_ animated: Bool) {
        let fullWidth = view.bounds.width
        let currentWidth: CGFloat = {
            if secondaryViewContainerTrailingConstraint?.isActive == true && secondaryViewContainerTrailingConstraint?.constant ?? 0 > PaneViewController.minimumWidth / 2 {
                return PaneViewController.minimumWidth - (secondaryViewContainerTrailingConstraint?.constant ?? PaneViewController.minimumWidth)
            } else {
                return secondaryViewSideContainerView.bounds.width
            }
        }()
        var bestPinningState: PaneViewPinningState = .closed
        for pinningState in PaneViewPinningState.all() {
            if abs(currentWidth - bestPinningState.paneViewWidth(forScreenWidth: fullWidth)) > abs(currentWidth - pinningState.paneViewWidth(forScreenWidth: fullWidth)) {
                bestPinningState = pinningState
            }
        }
        
        updateSecondaryViewSideBySideConstraint(forPinningState: bestPinningState)
        
        UIView.animate(withDuration: animated ? 0.3 : 0, animations: {
            self.view.layoutIfNeeded()
        }, completion: { _ in
            self.removeBlurIfNeeded()
            self.updateSizeClassOfChildViewControllers()
            self.primaryViewDidChangeWidthObservers.notify(self.primaryViewController.view)
        })
        
    }
    
    private func updateSecondaryViewLocationForTraitCollection(_ traitCollection: UITraitCollection) {
        switch traitCollection.horizontalSizeClass {
        case .regular:
            presentationMode = .sideBySide
            sideHandleTouchView.isUserInteractionEnabled = true
            modalHandleTouchView.isUserInteractionEnabled = false
            secondaryViewController.view.frame = secondaryViewSideContainerView.bounds
            secondaryViewController.view.translatesAutoresizingMaskIntoConstraints = true
            secondaryViewSideContainerView.insertSubview(secondaryViewController.view, at: 0)
        case .compact, .unspecified:
            presentationMode = .modal
            sideHandleTouchView.isUserInteractionEnabled = false
            modalHandleTouchView.isUserInteractionEnabled = true
            secondaryViewController.view.translatesAutoresizingMaskIntoConstraints = false
            secondaryViewModalContainerView.addSubview(secondaryViewController.view)
            secondaryViewModalContainerView.addSubview(modalShadowImageView)
            
            let views: [String: Any] = ["secondaryView": secondaryViewController.view, "modalShadowImageView": modalShadowImageView]
            let metrics = ["modalOpenGap": modalOpenGap]
            secondaryViewModalContainerView.removeConstraints(modalShadowView.constraints)
            secondaryViewModalContainerView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "[modalShadowImageView][secondaryView]|", options: [], metrics: nil, views: views))
            secondaryViewModalContainerView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "|-modalOpenGap-[secondaryView]|", options: [], metrics: metrics, views: views))
            secondaryViewModalContainerView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[secondaryView]|", options: [], metrics: nil, views: views))
            secondaryViewModalContainerView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[modalShadowImageView]|", options: [], metrics: nil, views: views))
        }
    }
    
}

extension PaneViewController: HandleViewDelegate {
    
    func hitTest(_ point: CGPoint, withEvent event: UIEvent?, inView: UIView) -> UIView? {
        let mainViewPoint = inView.convert(point, to: view)
        if secondaryViewModalContainerView.frame.contains(mainViewPoint) || secondaryViewSideContainerView.frame.contains(mainViewPoint) {
            let convertedPoint = inView.convert(point, to: secondaryViewController.view)
            return secondaryViewController.view.hitTest(convertedPoint, with: event)
        }
        
        let convertedPoint = inView.convert(point, to: primaryViewController.view)
        return primaryViewController.view.hitTest(convertedPoint, with: event)
    }
    
}

extension PaneViewController: UIGestureRecognizerDelegate {
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return false
    }
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
}

public protocol PaneViewControllerDelegate: class {
    
    func paneViewControllerDidStartPanning(_ paneViewController: PaneViewController)
    func paneViewControllerDidFinishPanning(_ paneViewController: PaneViewController)
    
}
