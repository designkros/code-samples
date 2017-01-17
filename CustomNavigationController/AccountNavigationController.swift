//
//  AccountNavigationController.swift
//  Sample
//
//  Created by Michael Rose on 9/28/16.
//  Copyright © 2016 Michael Rose. All rights reserved.
//

import UIKit

// Manages the top navigation bar, top image view (tear icon), middle content area (a stack of AccountViewController subclasses), bottom action button, and bottom footer bottoms.

let AccountDefaultAnimationDuration = 0.35
enum AccountControllerState{
    case create
    case login
}

class AccountNavigationController: UIViewController {
    
    private enum AccountTransition {
        case none
        case crossfade
        case push
        case pop
    }
    
    @IBOutlet weak var navBar: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var cancelButtonContainer: UIView!
    
    @IBOutlet weak var logoImageView: UIImageView!
    @IBOutlet weak var logoImageViewYConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var errorLabelHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var containerViewHeightConstaint: NSLayoutConstraint!
    
    @IBOutlet weak var actionButtonContainer: UIView!
    
    @IBOutlet weak var footerButtonViewHeightConstriant: NSLayoutConstraint!
    @IBOutlet weak var footerButtonView: UIView!
    
    @IBOutlet weak var activityIndicator: UIImageView!
   
    
    var viewControllers:Array! = [AccountViewController]()
    var rootViewController: AccountViewController { return viewControllers.first! }
    var state: AccountControllerState = AccountHelper.userCreated ? .login : .create
    private var isTransitioning = false
    private var keyboardShowing = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Load the root "Create Account" view controller by default. In the near future you should be able to init with your desired "state" (Create Account or Login)
        let storyBoardName = state == .create ? "CreateAccount" : "Login"
        let controllerName = state == .create ? "CreateAccountNamesViewController" : "LoginCredentialsViewController"
        let rootViewController = UIStoryboard(name:storyBoardName, bundle: nil).instantiateViewController(withIdentifier: controllerName) as! AccountViewController
        
        setRootViewController(viewController: rootViewController)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Hide navigation bar
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
        
        // Only needed for iPhone SE
        if ScreenSizeHelper.currentDevice == .iPhoneSE {
            // Register for keyboard notifications
            NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: .UIKeyboardWillShow, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: .UIKeyboardWillHide, object: nil)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Show navigation bar
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
        
        // Only needed for iPhone SE
        if ScreenSizeHelper.currentDevice == .iPhoneSE {
            // Unregister for keyboard notifications
            NotificationCenter.default.removeObserver(self, name: .UIKeyboardWillShow, object: nil)
            NotificationCenter.default.removeObserver(self, name: .UIKeyboardWillHide, object: nil)
        }
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override var prefersStatusBarHidden: Bool {
        return keyboardShowing
    }
    
    // MARK: - Keyboard
    
    func keyboardWillShow(notification: NSNotification) {
        // Hide status bar
        keyboardShowing = true
        
        // Hide navigatio nbar
        hideNavigationBar(hide: true, animated: true)
        
        // Move the logo
        logoImageViewYConstraint.constant = 20.0
        
        UIView.animate(withDuration: AccountDefaultAnimationDuration, animations: {
            self.setNeedsStatusBarAppearanceUpdate()
            self.view.layoutIfNeeded()
        })
    }
    
    func keyboardWillHide(notification: NSNotification) {
        // Show status bar
        keyboardShowing = false
        
        // Show navigation bar
        hideNavigationBar(hide: false, animated: true)
        
        // Move the logo
        logoImageViewYConstraint.constant = 83.0
        
        UIView.animate(withDuration: AccountDefaultAnimationDuration, animations: {
            self.setNeedsStatusBarAppearanceUpdate()
            self.view.layoutIfNeeded()
        })
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Hide the keyboard on background touch
        view.endEditing(true)
        super.touchesBegan(touches, with: event)
    }
    
    // MARK: - User Action
    
    @IBAction func backButtonTapped(_ sender: AnyObject) {
        if (!isTransitioning) { // Wait until current transition is complete before allow to go back again
            pop(animated: true)
        }
    }
    
    // MARK: - View Controller Management
    
    func didFinish(success: Bool) {
        // If successful login and not paired, show the pairing sequence
        if success && !AccountHelper.userPairedDeivce {
            performSegue(withIdentifier: "showPairingIntro", sender: self)
        }
        // Otherwise decide if the home view controller needs to be pushed or popped
        else {
            // Is home view controller already in the navigation stack?
            if let homeViewController = appDelegate.rootViewController.viewControllerInstanceOfTypeInNavigationStack(type: HomeViewController.self) {
                // Show navigation bar, navigationController is nil in viewWillDisappear
                // after popToViewController is called below
                self.navigationController?.setNavigationBarHidden(false, animated: true)
                
                // Pop to existing home view controller instance
                _ = self.navigationController?.popToViewController(homeViewController, animated: true)
            } else {
                // Push to new home view controller instance
                performSegue(withIdentifier: "showHomeView", sender: self)
            }
        }
    }
    
    func setRootViewController(viewController: AccountViewController, animated: Bool = false) {
        // Grab the from view controller (if available)
        var fromViewController: AccountViewController?
        if viewControllers.last != nil {
            fromViewController = viewControllers.last
        }
        
        // Clear the navigation stack
        viewControllers.removeAll()
        
        // Add the root view controller to the fresh navigation stack
        viewControllers.append(viewController)
        
        // Transition from view controller to root view controller
        let type: AccountTransition = animated ? .crossfade : .none
        transition(toViewController: viewController, fromViewController: fromViewController, transition: type)
    }
    
    func push(viewController: AccountViewController, animated: Bool = false) {
        let fromViewContrller = viewControllers.last! // There should always be at least the root view controller in the stack
        let toViewController = viewController
        
        // Retain the toViewController to the navigation stack
        viewControllers.append(toViewController)
        
        // Transition from view controller to view controller
        let type: AccountTransition = animated ? .push : .none
        transition(toViewController: toViewController, fromViewController: fromViewContrller, transition: type)
    }
    
    func pop(animated: Bool = false, completion: ((Bool) -> Swift.Void)? = nil) {
        let fromViewController = viewControllers.popLast()!
        let toViewController = viewControllers.last!
        
        // Transition from view controller to view controller
        let type: AccountTransition = animated ? .pop : .none
        transition(toViewController: toViewController, fromViewController: fromViewController, transition: type, completion: completion)
    }
    
    func popToRoot(animated: Bool = false) {
        let fromViewController = viewControllers.popLast()!
        let rootViewController = viewControllers.first!
        
        // Reset navigation stack
        viewControllers = [rootViewController]
        
        // Transition from view controller to view controller
        let type: AccountTransition = animated ? .pop : .none
        transition(toViewController: rootViewController, fromViewController: fromViewController, transition: type)
    }

    private func transition(toViewController: AccountViewController, fromViewController: AccountViewController?, transition: AccountTransition, completion: ((Bool) -> Swift.Void)? = nil) {
        isTransitioning = true
        
        var fromSnapshot: UIView?
        if let fromViewController = fromViewController {
            // Take a snapshot of the fromViewController to animate before removing it from the view hierarchy
            fromSnapshot = fromViewController.view.snapshotView(afterScreenUpdates: false)
            fromSnapshot?.frame = fromViewController.view.frame
            fromSnapshot?.alpha = 1.0
            containerView.addSubview(fromSnapshot!)
            
            // Remove the fromViewController from the view hierarchy
            fromViewController.willMove(toParentViewController: nil)
            fromViewController.view.removeFromSuperview()
            fromViewController.removeFromParentViewController()
        }
        
        // Add toViewController to the view hierarchy
        addChildViewController(toViewController)
        
        // Set this instance toViewController's account navigation controller property
        toViewController.accountNavigationController = self
        
        // Adjust content height based on the child its about to load
        containerViewHeightConstaint.constant = toViewController.view.bounds.size.height
        
        // Hide error view
        // IMPORTANT! This needs to be done manually here so it can work with the content view height change
        errorLabelHeightConstraint.constant  = 0
        
        // Adjust footer container height (based on buttons)
        // IMPORTANT! This needs to be done manually here so it can work with the content view height change
        var footerHeight: CGFloat = 0
        if let buttonCount = toViewController.accountNavigationItem.footerButtons?.count {
            footerHeight = 44.0 * CGFloat(buttonCount)
        }
        footerButtonViewHeightConstriant.constant = footerHeight
        
        if (transition != .none && fromSnapshot != nil) {
            // Animate the content view height change
            UIView.animate(withDuration: AccountDefaultAnimationDuration, animations: {
                self.view.layoutIfNeeded()
            })
        }
        
        toViewController.view.frame = self.containerView.bounds
        containerView.addSubview(toViewController.view)
        
        toViewController.didMove(toParentViewController: self)
        
        // Update Account Navigation Item
        updateAccountNavigationItem(toViewController: toViewController, animated: transition != .none)
        
        // Transition between the from view and to view
        if fromSnapshot != nil {
            if transition != .none {
                // Preset the toViewController's view alpha
                toViewController.view.alpha = 0
                
                let toFinalFrame = toViewController.view.frame
                var toStartFrame = toViewController.view.frame
                
                var fromFinalFrame = fromSnapshot!.frame
                
                let offsetPercentage = 0.2
                var offset: CGFloat
                switch transition {
                case .push:
                    offset = containerView.bounds.width * CGFloat(offsetPercentage)
                    break
                case .pop:
                    offset = containerView.bounds.width * CGFloat(-offsetPercentage)
                    break
                default:
                    offset = 0
                }
                
                toStartFrame.origin.x = toStartFrame.origin.x + offset
                toViewController.view.frame = toStartFrame
                
                fromFinalFrame.origin.x = fromFinalFrame.origin.x - offset
                
                // Make sure the snapshot is on top of the toViewController's view
                containerView.bringSubview(toFront: fromSnapshot!)
                
                // Cross-fade the fromViewController (snapshot) to the toViewController
                UIView.animate(withDuration: AccountDefaultAnimationDuration, animations: {
                    fromSnapshot!.alpha = 0
                    fromSnapshot!.frame = fromFinalFrame
                    toViewController.view.alpha = 1.0
                    toViewController.view.frame = toFinalFrame
                }, completion: { finished in
                    fromSnapshot!.removeFromSuperview()
                    self.isTransitioning = false
                    if completion != nil{ completion!(finished) }
                })
            } else {
                fromSnapshot!.removeFromSuperview()
                self.isTransitioning = false
                if completion != nil{ completion!(true) }
            }
        } else {
            if transition != .none {
                // Preset the toViewController's view alpha
                toViewController.view.alpha = 0
                
                let toFinalFrame = toViewController.view.frame
                var toStartFrame = toViewController.view.frame
                
                let offsetPercentage = 0.2
                var offset: CGFloat
                switch transition {
                case .push:
                    offset = containerView.bounds.width * CGFloat(offsetPercentage)
                    break
                case .pop:
                    offset = containerView.bounds.width * CGFloat(-offsetPercentage)
                    break
                default:
                    offset = 0
                }
                
                toStartFrame.origin.x = toStartFrame.origin.x + offset
                toViewController.view.frame = toStartFrame
                
                // Cross-fade the fromViewController (snapshot) to the toViewController
                UIView.animate(withDuration: AccountDefaultAnimationDuration, animations: {
                    toViewController.view.alpha = 1.0
                    toViewController.view.frame = toFinalFrame
                }, completion: { finished in
                    self.isTransitioning = false
                    if completion != nil{ completion!(finished) }
                })
            } else {
                self.isTransitioning = false
                if completion != nil{ completion!(true) }
            }
        }
    }
    
    // MARK: - Account Navigation Items
    
    private func hideNavigationBar(hide: Bool, animated: Bool) {
        let toAlpha: CGFloat = hide ? 0 : 1.0
        if animated {
            navBar.isHidden = false
            UIView.animate(withDuration: AccountDefaultAnimationDuration, delay: 0, options: .beginFromCurrentState, animations: {
                self.navBar.alpha = toAlpha
            }, completion: nil)
        } else {
            navBar.alpha = toAlpha
        }
    }
    
    private func updateAccountNavigationItem(toViewController: AccountViewController, animated: Bool) {
        // Title
        updateTitle(viewController: toViewController, animated: animated)
        
        let navItem = toViewController.accountNavigationItem
        
        // Back Button
        updateBackButton(navItem: navItem, animated: animated)
        
        // Cancel Button
        updateCancelButton(navItem: navItem, animated: animated)
        
        // Hides Logo
        updateHidesLogo(navItem: navItem, animated: animated)
        
        // Action Button
        updateActionButton(navItem: navItem, animated: animated)
        
        // Footer Buttons
        updateFooterButtons(navItem: navItem, animated: animated)
        
        // Background Colors
        updateBackgroundColors(colors: navItem.backgroundColors, animated: animated)
    }
    
    private func transitionAccountNavigationItem(fromView: UIView?, toView: UIView?, animated: Bool) {
        
        // Transition between the to views (cross-fade)
        if fromView != nil && toView != nil {
            if animated {
                // Preset the actionButtons's alpha
                toView!.alpha = 0
                
                // Make sure the snapshot is on top of the toView
                toView!.superview!.bringSubview(toFront: fromView!)
                
                // Animate the transition
                UIView.animate(withDuration: AccountDefaultAnimationDuration, animations: {
                    toView!.alpha = 1.0
                    fromView!.alpha = 0
                }, completion: { (finished) in
                    fromView!.removeFromSuperview()
                })
            } else {
                fromView!.removeFromSuperview()
            }
        }
            
        // Transition just the from snapshot (fade out)
        else if (fromView != nil && toView == nil) {
            if animated {
                UIView.animate(withDuration: AccountDefaultAnimationDuration, animations: {
                    fromView!.alpha = 0
                }, completion: { (finished) in
                    fromView!.removeFromSuperview()
                })
            } else {
                fromView!.removeFromSuperview()
            }
        }
            
        // Transition just the to view (fade in)
        else if (fromView == nil && toView != nil) {
            if animated {
                // Preset the actionButtons's alpha
                toView!.alpha = 0
                
                // Animate the transition
                UIView.animate(withDuration: AccountDefaultAnimationDuration, animations: {
                    toView!.alpha = 1.0
                })
            }
        }
        
    }
    
    // MARK: - Title
    
    private func updateTitle(viewController: UIViewController, animated: Bool) {
        var title: String! = nil
        if let viewControllerTitle = viewController.title {
            title = viewControllerTitle.uppercased()
        }
        
        // Only animate if the titles are different
        var animationRequired = animated
        if let previousTitle = self.titleLabel.text {
            animationRequired = previousTitle != title && animated
        }
        
        if (animationRequired) {
            UIView.transition(with: titleLabel, duration: AccountDefaultAnimationDuration, options: .transitionCrossDissolve, animations: {
                self.titleLabel.text = title
            }, completion: nil)
        } else {
            self.titleLabel.text = title
        }
    }
    
    // MARK: - Back Button
    
    private func updateBackButton(navItem: AccountNavigationItem, animated: Bool) {
        let toState = viewControllers.count <= 1 || navItem.hidesBackButton
        let toAlpha: CGFloat = toState ? 0 : 1.0
        
        let fromState = backButton.isHidden
        
        // Only update the back button if it's a different state
        if (toState != fromState) {
            if (animated) {
                backButton.isHidden = false
                UIView.animate(withDuration: AccountDefaultAnimationDuration, animations: {
                    self.backButton.alpha = toAlpha
                }, completion: { finished in
                    if (finished) {
                        self.backButton.isHidden = toState
                    }
                })
            } else {
                backButton.alpha = toAlpha
                backButton.isHidden = toState
            }
        }
    }
    
    // MARK: - Cancel Button
    
    private func updateCancelButton(navItem: AccountNavigationItem, animated: Bool) {
        // Remove "from" button (if available)
        var fromSnapshot: UIView?
        var fromImage: UIImage?
        if let fromView = cancelButtonContainer.subviews.last {
            // Take a snapshot if this will need to be animated later
            fromSnapshot = fromView.snapshotView(afterScreenUpdates: false)
            fromSnapshot?.frame = fromView.bounds
            cancelButtonContainer.addSubview(fromSnapshot!)
            
            // Store "from" button title to check for animation
            let fromButton = fromView as! UIButton
            fromImage = fromButton.image(for: .normal)
            
            fromView.removeFromSuperview()
        }
        
        // Add "to" button (if available)
        var toView: UIView?
        var toImage: UIImage?
        if let cancelButton = navItem.cancelButton {
            cancelButtonContainer.addSubview(cancelButton)
            cancelButton.translatesAutoresizingMaskIntoConstraints = false
            let views = [ "cancelButton" : cancelButton ]
            cancelButtonContainer.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[cancelButton]|", options: [], metrics: nil, views: views))
            cancelButtonContainer.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[cancelButton]|", options: [], metrics: nil, views: views))
            
            // Store "to" button title to check for animation
            toImage = cancelButton.image(for: .normal)
            
            toView = cancelButton
        }
        
        // Don't animate if the button image is the same
        var animationRequired: Bool!
        if (fromImage != nil && toImage != nil) {
            animationRequired = !fromImage!.isEqual(toImage) && animated
        } else {
            animationRequired = animated
        }
        
        // Transition between "from" and "to"
        transitionAccountNavigationItem(fromView: fromSnapshot, toView: toView, animated: animationRequired)
    }
    
    // MARK: - Hides Logo
    
    private func updateHidesLogo(navItem: AccountNavigationItem, animated: Bool) {
        let toState = navItem.hidesLogo
        let toAlpha: CGFloat = toState ? 0 : 1.0
        
        let fromState = logoImageView.isHidden
        
        // Only update the logo if it's a different state
        if (toState != fromState) {
            if (animated) {
                logoImageView.isHidden = false
                UIView.animate(withDuration: AccountDefaultAnimationDuration, animations: {
                    self.logoImageView.alpha = toAlpha
                }, completion: { finished in
                    if (finished) {
                        self.logoImageView.isHidden = toState
                    }
                })
            } else {
                logoImageView.alpha = toAlpha
                logoImageView.isHidden = toState
            }
            
        }
    }
    
    // MARK: - Action Button
    
    private func updateActionButton(navItem: AccountNavigationItem, animated: Bool) {
        // Remove "from" button (if available)
        var fromSnapshot: UIView?
        if let fromView = actionButtonContainer.subviews.last {
            // Take a snapshot if this will need to be animated later
            fromSnapshot = fromView.snapshotView(afterScreenUpdates: false)
            fromSnapshot?.frame = fromView.bounds
            actionButtonContainer.addSubview(fromSnapshot!)
            
            fromView.removeFromSuperview()
        }
        
        // Add "to" button (if available)
        var toView: UIView?
        if let actionButton = navItem.actionButton {
            actionButtonContainer.addSubview(actionButton)
            actionButton.translatesAutoresizingMaskIntoConstraints = false
            let views = [ "actionButton" : actionButton ]
            actionButtonContainer.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[actionButton]|", options: [], metrics: nil, views: views))
            actionButtonContainer.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[actionButton]|", options: [], metrics: nil, views: views))
            
            toView = actionButton
        }
        
        // Transition between "from" and "to"
        transitionAccountNavigationItem(fromView: fromSnapshot, toView: toView, animated: animated)
    }
    
    // MARK: - Footer Buttons
    
    private func updateFooterButtons(navItem: AccountNavigationItem, animated: Bool) {
        // Remove "from" button (if available)
        var fromSnapshot: UIView?
        if let fromView = footerButtonView.subviews.last {
            // Using the actual view instead of snapshot because the UIStackView snapshot appears buggy
            // This also keep the original size of the fromView
            fromSnapshot = fromView
        }
        
        // Add "to" footer buttons (if available)
        var toView: UIView?
        if let footerButtons = navItem.footerButtons {
            let stackView = UIStackView(arrangedSubviews: footerButtons)
            stackView.axis = .vertical
            stackView.distribution = .fillEqually
            footerButtonView.addSubview(stackView)
            stackView.translatesAutoresizingMaskIntoConstraints = false
            let views = [ "stackView" : stackView ]
            footerButtonView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[stackView]|", options: [], metrics: nil, views: views))
            footerButtonView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[stackView]|", options: [], metrics: nil, views: views))
            
            toView = stackView
        }
        
        // Transition between "from" and "to"
        transitionAccountNavigationItem(fromView: fromSnapshot, toView: toView, animated: animated)
    }
	
    // MARK: - Activity Indicator
	
    func showActivityIndicator(show: Bool){
        if show == true {
            UIView.animate(withDuration: AccountDefaultAnimationDuration, animations: {
                self.activityIndicator.alpha = 1.0
                self.footerButtonView.alpha = 0.0
                self.actionButtonContainer.alpha = 0.0
            }, completion: { (complete) in
                Utils.rotate(layer: self.activityIndicator.layer)
            })
        } else {
            UIView.animate(withDuration: AccountDefaultAnimationDuration, animations: {
                self.activityIndicator.alpha = 0.0
                self.footerButtonView.alpha = 1.0
                self.actionButtonContainer.alpha = 1.0
            }, completion: nil)
        }
    }
	
    // MARK: - Background Colors
    
    private func updateBackgroundColors(colors: [UIColor], animated: Bool) {
        let gradientView = view as! IBGradientView
        
        let fromColors = gradientView.gradientLayer.colors as! [CGColor]
        
        var toColors = [CGColor]()
        for color in colors {
            toColors.append(color.cgColor)
        }
        
        // Don't animate if the colors are the same
        if (fromColors != toColors) {
            gradientView.gradientLayer.colors = toColors
            
            let animation = CABasicAnimation(keyPath: "colors")
            animation.toValue = toColors
            animation.fromValue = fromColors
            animation.duration = AccountDefaultAnimationDuration
            animation.isRemovedOnCompletion = true
            
            gradientView.gradientLayer.add(animation, forKey: "gradientAnimation")
        }
    }
    
    // MARK: - Error
    
    func displayError(errorString: String) {
        if (!isTransitioning) {
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .center
            let attributes = [ NSForegroundColorAttributeName : UIColor.white, NSFontAttributeName : UIFont(name: "AvenirNext-Regular", size: 15.0)!, NSParagraphStyleAttributeName : paragraphStyle ] as [String : Any]
            let errorAttributedString = NSAttributedString(string: " \(errorString)", attributes: attributes)
            
            let attachment = NSTextAttachment()
            attachment.image = UIImage(named: "warningIconTinyWht")
            attachment.bounds = CGRect(x: 0, y: -4.0, width:(attachment.image?.size.width)!, height:(attachment.image?.size.height)!)
            let attachmentAttributedString = NSAttributedString(attachment: attachment)
            
            let finalAttributedString = NSMutableAttributedString(attributedString: attachmentAttributedString)
            finalAttributedString.append(errorAttributedString)
            
            errorLabel.attributedText = finalAttributedString
            
            // Calculate height of final attributed string
            let height = finalAttributedString.height(containerWidth: errorLabel.bounds.size.width)
            errorLabelHeightConstraint.constant = height
            
            UIView.animate(withDuration: AccountDefaultAnimationDuration, animations: {
                self.view.layoutIfNeeded()
            })
        }
    }
    
    func hideError() {
        if (!isTransitioning && errorLabelHeightConstraint.constant != 0) {
            errorLabelHeightConstraint.constant  = 0
            UIView.animate(withDuration: AccountDefaultAnimationDuration, animations: {
                self.view.layoutIfNeeded()
            })
        }
    }
    
}



