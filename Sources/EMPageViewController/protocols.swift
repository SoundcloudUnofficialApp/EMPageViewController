
import UIKit

/**
 The `EMPageViewControllerDataSource` protocol is adopted to provide the view controllers that are displayed when the user scrolls through pages. Methods are called on an as-needed basis.
 
 Each method returns a `UIViewController` object or `nil` if there are no view controllers to be displayed.
 
 - note: If the data source is `nil`, gesture based scrolling will be disabled and all view controllers must be provided through `selectViewController:direction:animated:completion:`.
 */
public protocol EMPageViewControllerDataSource: class {
    
    /**
     Called to optionally return a view controller that is to the left of a given view controller in a horizontal orientation, or above a given view controller in a vertical orientation.
     
     - parameter pageViewController: The page view controller
     - parameter viewController: The point of reference view controller
     
     - returns: The view controller that is to the left of the given `viewController` in a horizontal orientation, or above the given `viewController` in a vertical orientation, or `nil` if there is no view controller to be displayed.
     */
    func em_getControllerBefore( _ pageVC: EMPageViewController,
                                 controller vc: UIViewController) -> UIViewController?
    
    /**
     Called to optionally return a view controller that is to the right of a given view controller.
     
     - parameter pageViewController: The page view controller
     - parameter viewController: The point of reference view controller
     
     - returns: The view controller that is to the right of the given `viewController` in a horizontal orientation, or below the given `viewController` in a vertical orientation, or `nil` if there is no view controller to be displayed.
     */
    func em_getControllerAfter(_ pageVC: EMPageViewController,
                               controller vc: UIViewController) -> UIViewController?
}

/**
 The EMPageViewControllerDelegate protocol is adopted to receive messages for all important events of the page transition process.
 */
public protocol EMPageViewControllerDelegate: class {
    
    /**
     Called before scrolling to a new view controller.
     
     - note: This method will not be called if the starting view controller is `nil`. A common scenario where this will occur is when you initialize the page view controller and use `selectViewController:direction:animated:completion:` to load the first selected view controller.
     
     - important: If bouncing is enabled, it is possible this method will be called more than once for one page transition. It can be called before the initial scroll to the destination view controller (which is when it is usually called), and it can also be called when the scroll momentum carries over slightly to the view controller after the original destination view controller.
     
     - parameter pageViewController: The page view controller
     - parameter startingViewController: The currently selected view controller the transition is starting from
     - parameter destinationViewController: The view controller that will be scrolled to, where the transition should end
     */
    func em_willStartScrollingFrom(_ pageVC: EMPageViewController,
                                   willStartScrollingFrom startingVC: UIViewController,
                                   destinationVC: UIViewController)
    
    /**
     Called whenever there has been a scroll position change in a page transition. This method is very useful if you need to know the exact progress of the page transition animation.
     
     - note: This method will not be called if the starting view controller is `nil`. A common scenario where this will occur is when you initialize the page view controller and use `selectViewController:direction:animated:completion:` to load the first selected view controller.
     
     - parameter pageViewController: The page view controller
     - parameter startingViewController: The currently selected view controller the transition is starting from
     - parameter destinationViewController: The view controller being scrolled to where the transition should end
     - parameter progress: The progress of the transition, where 0 is a neutral scroll position, >= 1 is a complete transition to the right view controller in a horizontal orientation, or the below view controller in a vertical orientation, and <= -1 is a complete transition to the left view controller in a horizontal orientation, or the above view controller in a vertical orientation. Values may be greater than 1 or less than -1 if bouncing is enabled and the scroll velocity is quick enough.
     */
    func em_isScrollingFrom(_ pageVC: EMPageViewController,
                            isScrollingFrom startingVC: UIViewController,
                            destinationVC: UIViewController,
                            progress: CGFloat)
    
    /**
     Called after a page transition attempt has completed.
     
     - important: If bouncing is enabled, it is possible this method will be called more than once for one page transition. It can be called after the scroll transition to the intended destination view controller (which is when it is usually called), and it can also be called when the scroll momentum carries over slightly to the view controller after the intended destination view controller. In the latter scenario, `transitionSuccessful` will return `false` the second time it's called because the scroll view will bounce back to the intended destination view controller.
     
     - parameter pageViewController: The page view controller
     - parameter startingViewController: The currently selected view controller the transition is starting from
     - parameter destinationViewController: The view controller that has been attempted to be selected
     - parameter transitionSuccessful: A Boolean whether the transition to the destination view controller was successful or not. If `true`, the new selected view controller is `destinationViewController`. If `false`, the transition returned to the view controller it started from, so the selected view controller is still `startingViewController`.
     */
    func em_didFinishScrollingFrom(_ pageVC: EMPageViewController,
                                   didFinishScrollingFrom startingVC: UIViewController?,
                                   destinationVC: UIViewController,
                                   transitionSuccessful: Bool)
}

extension EMPageViewControllerDelegate {
    
    func em_willStartScrollingFrom(_ pageVC: EMPageViewController,
                                   willStartScrollingFrom startingVC: UIViewController,
                                   destinationVC:UIViewController) {
        
    }
    
    func em_isScrollingFrom(_ pageVC: EMPageViewController,
                            isScrollingFrom startingVC: UIViewController,
                            destinationVC:UIViewController,
                            progress: CGFloat) {
        
    }
    
    func em_didFinishScrollingFrom(_ pageVC: EMPageViewController,
                                   didFinishScrollingFrom startingVC: UIViewController?,
                                   destinationVC:UIViewController,
                                   transitionSuccessful: Bool) {
        
    }
}


/// The navigation scroll direction.
public enum NavigationDirection : String {
    
    /// Forward direction. Can be right in a horizontal orientation or down in a vertical orientation.
    
    case forward
    /// Reverse direction. Can be left in a horizontal orientation or up in a vertical orientation.
    case back
}

///  The navigation scroll orientation.
public enum NavigationOrientation: String {
    
    /// Horiziontal orientation. Scrolls left and right.
    
    case horizontal
    /// Vertical orientation. Scrolls up and down.
    case vertical
}
