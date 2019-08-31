
import UIKit
import EMPageViewController

class RootViewController: UIViewController, EMPageViewControllerDataSource, EMPageViewControllerDelegate {
    
    @IBOutlet weak var reverseButton: UIButton!
    @IBOutlet weak var scrollToButton: UIButton!
    @IBOutlet weak var forwardButton: UIButton!
    
    var pageVC: EMPageViewController?
    
    var greetings = ["Hello!", "¡Hola!", "Salut!", "Hallo!", "Ciao!"]
    var greetingColors: [UIColor] = [
        UIColor(red: 108.0/255.0, green: 122.0/255.0, blue: 137.0/255.0, alpha: 1.0),
        UIColor(red: 135.0/255.0, green: 211.0/255.0, blue: 124.0/255.0, alpha: 1.0),
        UIColor(red: 34.0/255.0, green: 167.0/255.0, blue: 240.0/255.0, alpha: 1.0),
        UIColor(red: 245.0/255.0, green: 171.0/255.0, blue: 53.0/255.0, alpha: 1.0),
        UIColor(red: 214.0/255.0, green: 69.0/255.0, blue: 65.0/255.0, alpha: 1.0)
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let currentViewController = self.viewController(at: 0)!
        let pageVC = EMPageViewController(currentViewController)
                
        pageVC.dataSource = self
        pageVC.delegate = self
        
        pageVC.select(currentViewController, .forward, animated: false)
        
        addChild(pageVC)
        view.insertSubview(pageVC.view, at: 0)
        // Insert the page controller view below the navigation buttons
        pageVC.didMove(toParent: self)
        
        self.pageVC = pageVC
    }
    
    
    // MARK: - scroll / transition methods
    
    @IBAction func forward(_ sender: AnyObject) {
        pageVC!.scrollForward(animated: true, completion: nil)
    }
    
    @IBAction func reverse(_ sender: AnyObject) {
        pageVC!.scrollBack(animated: true, completion: nil)
    }
    
    @IBAction func scrollTo(_ sender: AnyObject) {
        
        let choiceViewController = UIAlertController(title: "Scroll To...", message: nil, preferredStyle: UIAlertController.Style.actionSheet)
        
        let selectedIndex = index(ofAccessibilityElement: pageVC!.selectedVC as! GreetingViewController)
        
        for (index, viewControllerGreeting) in greetings.enumerated() {
            
            guard index != selectedIndex else {
                continue
            }
            
            let action = UIAlertAction(title: viewControllerGreeting, style: UIAlertAction.Style.default, handler: { (alertAction) in
                
                let viewController = self.viewController(at: index)!
                
                let direction: NavigationDirection = index > selectedIndex ? .forward : .back
                
                self.pageVC!.select(viewController, direction, animated: true)
                
            })
            
            choiceViewController.addAction(action)
        }
        
        let action = UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel, handler: nil)
        choiceViewController.addAction(action)
        
        present(choiceViewController, animated: true, completion: nil)
        
    }
    
    func viewController(at index: Int) -> GreetingViewController? {
        if greetings.count == 0 || index < 0 || index >= greetings.count {
            return nil
        }
        
        let vc = storyboard!.instantiateViewController(withIdentifier: "GreetingViewController") as! GreetingViewController
        vc.greeting = greetings[index]
        vc.color = greetingColors[index]
        return vc
    }
    
    func index(of viewController: GreetingViewController) -> Int? {
        if let greeting = viewController.greeting {
            return greetings.firstIndex(of: greeting)
        } else {
            return nil
        }
    }
    
    

    // MARK: - EMPageViewController Data Source
    
    func em_getControllerBefore(_ pageVC: EMPageViewController, controller vc: UIViewController) -> UIViewController? {
        
        if let i = index(of: vc as! GreetingViewController) {
            let prevVC = self.viewController(at: i - 1)
            return prevVC
        } else {
            return nil
        }
    }
    
    func em_getControllerAfter(_ pageVC: EMPageViewController, controller vc: UIViewController) -> UIViewController? {
        
        if let i = index(of: vc as! GreetingViewController) {
            let nextVC = self.viewController(at: i + 1)
            return nextVC
        } else {
            return nil
        }
    }
    
    
    
    //MARK: EMPageViewControllerDelegate
    
    
    func em_willStartScrollingFrom(_ pageVC: EMPageViewController, willStartScrollingFrom startVC: UIViewController,  destinationVC: UIViewController) {
        
        let startGreetingViewController = startVC as! GreetingViewController
        let destinationGreetingViewController = destinationVC as! GreetingViewController
        
        //print("Will start scrolling from \(startGreetingViewController.greeting) to \(destinationGreetingViewController.greeting).")
    }
    
    func em_isScrollingFrom(_ pageVC: EMPageViewController, isScrollingFrom startVC: UIViewController, destinationVC: UIViewController, progress: CGFloat) {
        let startGreetingViewController = startVC as! GreetingViewController
        let destinationGreetingViewController = destinationVC as! GreetingViewController
        
        // Ease the labels' alphas in and out
        let absoluteProgress = abs(progress)
        startGreetingViewController.label.alpha = pow(1 - absoluteProgress, 2)
        destinationGreetingViewController.label.alpha = pow(absoluteProgress, 2)
        
        //print("Is scrolling from \(startGreetingViewController.greeting) to \(destinationGreetingViewController.greeting) with progress '\(progress)'.")
    }
    
    func em_didFinishScrollingFrom(_ pageVC: EMPageViewController, didFinishScrollingFrom startVC: UIViewController?, destinationVC: UIViewController, transitionSuccessful: Bool) {
        let startVC = startVC as! GreetingViewController?
        let destinationVC = destinationVC as! GreetingViewController
        
        // If the transition is successful, the new selected view controller is the destination view controller.
        // If it wasn't successful, the selected view controller is the start view controller
        if transitionSuccessful {
            
            if index(of: destinationVC) == 0 {
                reverseButton.isEnabled = false
            } else {
                reverseButton.isEnabled = true
            }
            
            if index(of: destinationVC) == greetings.count - 1 {
                forwardButton.isEnabled = false
            } else {
                forwardButton.isEnabled = true
            }
        }
        
        //print("Finished scrolling from \(startVC?.greeting) to \(destinationVC.greeting). Transition successful? \(transitionSuccessful)")
    }
    
}

