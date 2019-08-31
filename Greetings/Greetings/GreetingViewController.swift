

import UIKit

class GreetingViewController: UIViewController {

    @IBOutlet weak var label: UILabel!
    var greeting: String!
    var color: UIColor!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = color
        label.text = greeting
    }
}
