
import UIKit


/// Manages page navigation between view controllers. View controllers can be navigated via swiping gestures, or called programmatically.
open class EMPageViewController: UIViewController, UIScrollViewDelegate {
    
    /// The object that provides view controllers on an as-needed basis throughout the navigation of the page view controller.
    ///
    /// If the data source is `nil`, gesture based isScrolling will be disabled and all view controllers must be provided through `selectViewController:direction:animated:completion:`.
    ///
    /// - important: If you are using a data source, make sure you set `dataSource` before calling `selectViewController:direction:animated:completion:`.
    open weak var dataSource: EMPageViewControllerDataSource?
    
    /// The object that receives messages throughout the navigation process of the page view controller.
    open weak var delegate: EMPageViewControllerDelegate?
    
    /// The direction isScrolling navigation occurs
    open private(set) var navigationOrientation: NavigationOrientation = .horizontal
    
    private var isOrientationHorizontal: Bool {
        return self.navigationOrientation == .horizontal
    }
    
    /// The underlying `UIScrollView` responsible for isScrolling page views.
    /// - important: Properties should be set with caution to prevent unexpected behavior.
    open private(set) lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.isPagingEnabled = true
        scrollView.scrollsToTop = false
        
        scrollView.autoresizingMask = [
            .flexibleTopMargin,
            .flexibleRightMargin,
            .flexibleBottomMargin,
            .flexibleLeftMargin
        ]
        
        scrollView.bounces = true
        scrollView.alwaysBounceHorizontal = isOrientationHorizontal
        scrollView.alwaysBounceVertical = !isOrientationHorizontal
        scrollView.translatesAutoresizingMaskIntoConstraints = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        
        return scrollView
    }()
    
    /// The view controller before the selected view controller.
    private var prevVC: UIViewController?
    
    /// The currently selected view controller. Can be `nil` if no view controller is selected.
    open private(set) var selectedVC: UIViewController!
    
    /// The view controller after the selected view controller.
    private var nextVC: UIViewController?
    
    /// Boolean that indicates whether the page controller is currently in the process of isScrolling.
    open private(set) var isScrolling = false
    
    /// The direction the page controller is isScrolling towards.
    open private(set) var navDirection: NavigationDirection = .forward
    
    /// Flag used to prevent isScrolling delegate when shifting scrollView
    private var adjustingContentOffset = false
    
    private var loadNewAdjoiningVCsOnFinish = false
    
    private var didFinishScrollingCompletionHandler: ((_ transitionSuccessful: Bool) -> Void)?
    
    /// Used for accurate view appearance messages
    private var transitionAnimated = false
    
    // MARK: - Public Methods
    
    /// Initializes a newly created page view controller with the specified navigation orientation.
    /// - parameter navigationOrientation: The page view controller's navigation scroll direction.
    /// - returns: The initialized page view controller.
    public convenience init(_ initialVC: UIViewController) {
        self.init()
        //self.selectedVC = initialVC
    }
    
    /**
     Sets the view controller that will be selected after the animation. This method is also used to provide the first view controller that will be selected in the page view controller.
     
     If a data source has been set, the view controllers before and after the selected view controller will also be loaded but not appear yet.
     
     - important: If you are using a data source, make sure you set `dataSource` before calling `selectViewController:direction:animated:completion:`
     
     - parameter viewController: The view controller to be selected.
     - parameter direction: The direction of the navigation and animation, if applicable.
     - parameter completion: A block that's called after the transition is finished. The block parameter `transitionSuccessful` is `true` if the transition to the selected view controller was completed successfully.
     */
    open func select(_ viewController: UIViewController,
                     _ direction: NavigationDirection = .forward,
                     animated: Bool = true,
                     _ completion: ((_ transitionSuccessful: Bool) -> Void)? = nil) {
        layoutViews()
                   loadNewAdjoiningVCsOnFinish = true
        switch direction {
        case .forward:
            nextVC = viewController
            scrollForward(animated: animated, completion: completion)
        case .back:
            prevVC = viewController
            scrollBack(animated: animated, completion: completion)
        }
    }
    
    
    /**
     Transitions to the view controller right of the currently selected view controller in a horizontal orientation, or below the currently selected view controller in a vertical orientation. Also described as going to the next page.
     
     - parameter animated: A Boolean whether or not to animate the transition
     - parameter completion: A block that's called after the transition is finished. The block parameter `transitionSuccessful` is `true` if the transition to the selected view controller was completed successfully. If `false`, the transition returned to the view controller it started from.
     */
    open func scrollForward(animated: Bool, completion: ((_ transitionSuccessful: Bool) -> Void)?) {
        
        guard nextVC != nil else {
            return
        }
        // Cancel current animation and move
        if isScrolling {
            if isOrientationHorizontal {
                scrollView.setContentOffset(CGPoint(x: view.bounds.width * 2, y: 0), animated: false)
            } else {
                scrollView.setContentOffset(CGPoint(x: 0, y: view.bounds.height * 2), animated: false)
            }
        }
        
        didFinishScrollingCompletionHandler = completion
        transitionAnimated = animated
        if isOrientationHorizontal {
            scrollView.setContentOffset(CGPoint(x: view.bounds.width * 2, y: 0), animated: animated)
        } else {
            scrollView.setContentOffset(CGPoint(x: 0, y: view.bounds.height * 2), animated: animated)
        }
    }
    
    /**
     Transitions to the view controller left of the currently selected view controller in a horizontal orientation, or above the currently selected view controller in a vertical orientation. Also described as going to the previous page.
     
     - parameter animated: A Boolean whether or not to animate the transition
     - parameter completion: A block that's called after the transition is finished. The block parameter `transitionSuccessful` is `true` if the transition to the selected view controller was completed successfully. If `false`, the transition returned to the view controller it started from.
     */
    open func scrollBack(animated: Bool, completion: ((_ transitionSuccessful: Bool) -> Void)?) {
        
        guard prevVC != nil else {
            return
        }
        
        // Cancel current animation and move
        if isScrolling {
            scrollView.setContentOffset(CGPoint.zero, animated: false)
        }
        
        didFinishScrollingCompletionHandler = completion
        transitionAnimated = animated
        scrollView.setContentOffset(CGPoint.zero, animated: animated)
    }
    
    // MARK: - View Controller Overrides
    
    // Overriden to have control of accurate view appearance method calls
    open override var shouldAutomaticallyForwardAppearanceMethods : Bool {
        return false
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        
        scrollView.delegate = self
        view.addSubview(scrollView)
    }
    
    open override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        guard !isScrolling else {
            return
        }
        
        scrollView.frame = view.bounds
        
        if isOrientationHorizontal {
            scrollView.contentSize = CGSize(
                width: view.bounds.width * 3,
                height: view.bounds.height
            )
        } else {
            scrollView.contentSize = CGSize(
                width: view.bounds.width,
                height: view.bounds.height * 3
            )
        }
        self.layoutViews()
    }
    
    
    // MARK: - View Controller Management
    
    private func loadViewControllers(for selectedVC: UIViewController) {
        
        // Scrolled forward
        if selectedVC == nextVC {
            
            // Shift view controllers forward
            prevVC = self.selectedVC
            self.selectedVC = nextVC
            
            self.selectedVC!.endAppearanceTransition()
            
            self.removeChildIfNeeded(prevVC)
            prevVC?.endAppearanceTransition()
            
            delegate?.em_didFinishScrollingFrom(self, didFinishScrollingFrom: prevVC, destinationVC: self.selectedVC!, transitionSuccessful: true)
            
            didFinishScrollingCompletionHandler?(true)
            didFinishScrollingCompletionHandler = nil
            
            // Load new before view controller if required
            if loadNewAdjoiningVCsOnFinish {
                loadPrevVC(for: selectedVC)
                loadNewAdjoiningVCsOnFinish = false
            }
            
            // Load new after view controller
            loadNextVC(for: selectedVC)
            
            
            // Scrolled back
        } else if selectedVC == prevVC {
            
            // Shift view controllers back
            nextVC = self.selectedVC
            self.selectedVC = prevVC
            
            self.selectedVC!.endAppearanceTransition()
            
            self.removeChildIfNeeded(nextVC)
            nextVC?.endAppearanceTransition()
            
            delegate?.em_didFinishScrollingFrom(self, didFinishScrollingFrom: nextVC!, destinationVC: self.selectedVC!, transitionSuccessful: true)
            
            didFinishScrollingCompletionHandler?(true)
            didFinishScrollingCompletionHandler = nil
            
            // Load new after view controller if required
            if loadNewAdjoiningVCsOnFinish {
                loadNextVC(for: selectedVC)
                loadNewAdjoiningVCsOnFinish = false
            }
            
            // Load new before view controller
            loadPrevVC(for: selectedVC)
            
            // Scrolled but ended up where started
        } else if selectedVC == self.selectedVC {
            
            guard isScrolling else {
                return
            }
            
            self.selectedVC!.beginAppearanceTransition(true, animated: transitionAnimated)
            
            switch navDirection {
            case .forward:
                nextVC?.beginAppearanceTransition(false, animated: transitionAnimated)
            case .back:
                prevVC?.beginAppearanceTransition(false, animated: transitionAnimated)
            }
            
            self.selectedVC!.endAppearanceTransition()
            
            // Remove hidden view controllers
            self.removeChildIfNeeded(prevVC)
            self.removeChildIfNeeded(nextVC)
            
            
            switch navDirection {
            case .forward:
                if let vc = nextVC,
                    let selVC = self.selectedVC {
                    vc.endAppearanceTransition()
                    delegate?.em_didFinishScrollingFrom(self, didFinishScrollingFrom: selVC, destinationVC: vc, transitionSuccessful: false)
                }
            case .back:
                if let vc = prevVC,
                    let selVC = self.selectedVC {
                    vc.endAppearanceTransition()
                    delegate?.em_didFinishScrollingFrom(self, didFinishScrollingFrom: selVC, destinationVC: vc, transitionSuccessful: false)
                }
            }
            
            didFinishScrollingCompletionHandler?(false)
            didFinishScrollingCompletionHandler = nil
            
            if loadNewAdjoiningVCsOnFinish {
                
                switch navDirection {
                case .forward:
                    loadNextVC(for: selectedVC)
                case .back:
                    loadPrevVC(for: selectedVC)
                }
            }
        }
        isScrolling = false
    }
    
    private func loadPrevVC(for selectedVC: UIViewController) {
        // Retreive the new before controller from the data source if available, otherwise set as nil
        prevVC = dataSource?.em_getControllerBefore(self, controller: selectedVC)
    }
    
    private func loadNextVC(for selectedVC: UIViewController) {
        // Retreive the new after controller from the data source if available, otherwise set as nil
        nextVC = dataSource?.em_getControllerAfter(self, controller: selectedVC)
    }
    
    
    // MARK: - View Management
    
    private func addChildIfNeeded(_ vc: UIViewController) {
        scrollView.addSubview(vc.view)
        self.addChild(vc)
        vc.didMove(toParent: self)
    }
    
    private func removeChildIfNeeded(_ vc: UIViewController?) {
        if let vc = vc {
            vc.view.removeFromSuperview()
            vc.didMove(toParent: nil)
            vc.removeFromParent()
        }
    }
    
    private func layoutViews() {
        
        let viewWidth = view.bounds.width
        let viewHeight = view.bounds.height
        
        var beforeInset: CGFloat = 0
        var afterInset: CGFloat = 0
        
        if prevVC == nil {
            beforeInset = isOrientationHorizontal ? -viewWidth : -viewHeight
        }
        
        if nextVC == nil {
            afterInset = isOrientationHorizontal ? -viewWidth : -viewHeight
        }
        
        self.adjustingContentOffset = true
        scrollView.contentOffset = CGPoint(x: isOrientationHorizontal ? viewWidth : 0, y: isOrientationHorizontal ? 0 : viewHeight)
        
        if isOrientationHorizontal {
            scrollView.contentInset = UIEdgeInsets(
                top: 0, left: beforeInset, bottom: 0, right: afterInset
            )
        } else {
            scrollView.contentInset = UIEdgeInsets(
                top: beforeInset, left: 0, bottom: afterInset, right: 0
            )
        }
        
        self.adjustingContentOffset = false
        
        if isOrientationHorizontal {
            prevVC?.view.frame = CGRect(x: 0, y: 0, width: viewWidth, height: viewHeight)
            self.selectedVC?.view.frame = CGRect(x: viewWidth, y: 0, width: viewWidth, height: viewHeight)
            nextVC?.view.frame = CGRect(x: viewWidth * 2, y: 0, width: viewWidth, height: viewHeight)
        } else {
            prevVC?.view.frame = CGRect(x: 0, y: 0, width: viewWidth, height: viewHeight)
            self.selectedVC?.view.frame = CGRect(x: 0, y: viewHeight, width: viewWidth, height: viewHeight)
            nextVC?.view.frame = CGRect(x: 0, y: viewHeight * 2, width: viewWidth, height: viewHeight)
        }
    }
    
    
    // MARK: - Internal Callbacks
    
    private func willScroll(from startingVC: UIViewController?,
                            to destinationVC: UIViewController) {
        if startingVC != nil {
            delegate?.em_willStartScrollingFrom(
                self,
                willStartScrollingFrom: startingVC!,
                destinationVC: destinationVC
            )
        }
        
        destinationVC.beginAppearanceTransition(true, animated: transitionAnimated)
        startingVC?.beginAppearanceTransition(false, animated: transitionAnimated)
        self.addChildIfNeeded(destinationVC)
    }
    
    private func didFinishScrolling(to viewController: UIViewController) {
        self.loadViewControllers(for: viewController)
        self.layoutViews()
    }
    
    
    // MARK: - UIScrollView Delegate
    
    open func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard !adjustingContentOffset else {
            return
        }
        
        let distance = isOrientationHorizontal ? view.bounds.width : view.bounds.height
        
        let progress = ((isOrientationHorizontal ? scrollView.contentOffset.x : scrollView.contentOffset.y) - distance) / distance
        
        
        /// Thresholds to update view layouts call delegates
        func finish() {
            if progress >= 1 && nextVC != nil {
                didFinishScrolling(to: nextVC!)
            } else if progress <= -1 && prevVC != nil {
                didFinishScrolling(to: prevVC!)
            } else if progress == 0  && selectedVC != nil {
                didFinishScrolling(to: selectedVC!)
            }
        }
        
        // Scrolling forward / after
        if progress > 0 {
            guard nextVC != nil else {
                finish()
                return
            }
            if !isScrolling {
                willScroll(from: selectedVC, to: nextVC!)
                isScrolling = true
            }
            
            // check if direction changed
            if navDirection == .back {
                didFinishScrolling(to: selectedVC!)
                willScroll(from: selectedVC, to: nextVC!)
            }
            
            navDirection = .forward
            
            if let vc = selectedVC {
                delegate?.em_isScrollingFrom(self, isScrollingFrom: vc, destinationVC: nextVC!, progress: progress)
            }
            
            // Scrolling back / before
        } else if progress < 0 {
            
            guard prevVC != nil else {
                finish()
                return
            }
            
            if !isScrolling {
                willScroll(from: selectedVC, to: prevVC!)
                isScrolling = true
            }
            
            // check if direction changed
            if navDirection == .forward {
                didFinishScrolling(to: selectedVC!)
                willScroll(from: selectedVC, to: prevVC!)
            }
            
            navDirection = .back
            
            if let vc = selectedVC {
                delegate?.em_isScrollingFrom(self, isScrollingFrom: vc, destinationVC: prevVC!, progress: progress)
            }
            
            // At zero
        } else {
            switch navDirection {
            case .forward:
                if let vc = nextVC, let selVC = selectedVC {
                    delegate?.em_isScrollingFrom(self, isScrollingFrom: selVC, destinationVC: vc, progress: progress)
                }
            case .back:
                if let vc = prevVC, let selVC = selectedVC {
                    delegate?.em_isScrollingFrom(self, isScrollingFrom: selVC, destinationVC: vc, progress: progress)
                }
            }
        }
        finish()
    }
    
    open func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        transitionAnimated = true
    }
    
    open func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        // setContentOffset is called to center the selected view after bounces
        // This prevents yucky behavior at the beginning and end of the page collection by making sure setContentOffset is called only if...
        
        guard isOrientationHorizontal else {
            //TODO: improve code
            if prevVC != nil && nextVC != nil ||
                // It isn't at the beginning or end of the page collection
                nextVC != nil && prevVC == nil && scrollView.contentOffset.y > abs(scrollView.contentInset.top) ||
                // If it's at the beginning of the collection, the decelleration can't be triggered by isScrolling away from, than torwards the inset
                prevVC != nil && nextVC == nil && scrollView.contentOffset.y < abs(scrollView.contentInset.bottom) {
                // Same as the last condition, but at the end of the collection
                scrollView.setContentOffset(CGPoint(x: 0, y: view.bounds.height), animated: true)
            }
            return
        }
        
        if prevVC != nil && nextVC != nil ||
            // It isn't at the beginning or end of the page collection
            nextVC != nil && prevVC == nil && scrollView.contentOffset.x > abs(scrollView.contentInset.left) ||
            // If it's at the beginning of the collection, the decelleration can't be triggered by isScrolling away from, than torwards the inset
            prevVC != nil && nextVC == nil && scrollView.contentOffset.x < abs(scrollView.contentInset.right) {
            // Same as the last condition, but at the end of the collection
            scrollView.setContentOffset(CGPoint(x: view.bounds.width, y: 0), animated: true)
        }
    }
}
