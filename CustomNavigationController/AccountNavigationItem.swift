//
//  AccountNavigationItem.swift
//  Sample
//
//  Created by Michael Rose on 10/4/16.
//  Copyright © 2016 Michael Rose. All rights reserved.
//

// Information that the view controller provides to the AccountNavigationController to redraw the user interface (if needed). We're using the same principle/relationship as UINavigationController and UINavigationItem.

import UIKit

class AccountNavigationItem: NSObject {
    var hidesBackButton: Bool = false
    var hidesLogo:Bool = false
    var cancelButton: UIButton?
    var actionButton: UIButton?
    var footerButtons: [UIButton]?
    var backgroundColors: [UIColor] = [UIColor.RGB(r: 133, g: 208, b: 203), UIColor.RGB(r: 48, g: 177, b: 201)]
}
