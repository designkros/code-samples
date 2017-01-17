//
//  AccountViewController.swift
//  Sample
//
//  Created by Michael Rose on 9/30/16.
//  Copyright © 2016  Michael Rose. All rights reserved.
//

// The base view controller for all view controllers used in the AccountNavigationController stack — which is responsible for both account creation and account log in.

import UIKit

class AccountViewController: UIViewController {
    var account: Account?
    let accountNavigationItem = AccountNavigationItem()
    var accountNavigationController: AccountNavigationController?
    
    var contentHeight: CGFloat {
        get {
            assert(false, "Subclass of AccountViewController must override contentHeight property.")
            return 0
        }
    }
   
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the views content height (used by AccountNavigationController's contentView container)
        var frame = self.view.frame
        frame.size.height = CGFloat(contentHeight)
        self.view.frame = frame
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
        //
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        print("viewWillDisappear")
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        print("viewDidDisappear")
    }
}
