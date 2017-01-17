//
//  CreateAccountEmailViewController.swift
//  Sample
//
//  Created by Michael Rose on 9/29/16.
//  Copyright © 2016  Michael Rose. All rights reserved.
//

import UIKit
import DataManager

// One of many view controllers in the account creation process (login also uses this parent class).

class CreateAccountEmailViewController: AccountViewController {
    
    @IBOutlet weak var emailTextField: TransparentTextField!
    @IBOutlet weak var passwordTextField: TransparentTextField!
    @IBOutlet weak var passwordConfirmationTextField: TransparentTextField!
    
    // Needed to set this view's height and the containerView height in the AccountNavigationController
    override var contentHeight: CGFloat {
        get {
            return 170.0
        }
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        get {
            return .lightContent
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Title
        self.title = "Create Account"
        
        // Account Button
        let actionButton = UIButton(type: .custom)
        actionButton.setTitle("Next".uppercased(), for: .normal)
        actionButton.setTitleColor(UIColor.white, for: .normal)
        actionButton.setTitleColor(UIColor.RGBA(r: 255, g: 255, b: 255, a: 0.3), for: .disabled)
        actionButton.titleLabel?.font = UIFont(name: "AvenirNext-Bold", size: 20.0)
        actionButton.isEnabled = false
        actionButton.addTarget(self, action: #selector(didNext), for: .touchUpInside)
        accountNavigationItem.actionButton = actionButton
        
        // Footer Button
        let footerButton = UIButton(type: .custom)
        footerButton.setTitle("I have an account", for: .normal)
        footerButton.titleLabel?.font = UIFont(name: "AvenirNext-Regular", size: 15.0)
        footerButton.titleLabel?.textColor = UIColor.white
        footerButton.addTarget(self, action: #selector(didAccount), for: .touchUpInside)
        accountNavigationItem.footerButtons = [footerButton]
        
        // Cancel Button
        let cancelButton = UIButton(type: .custom)
        cancelButton.setImage(UIImage(named:"iconClose"), for: .normal)
        cancelButton.addTarget(self, action:#selector(didCancel) , for: .touchUpInside)
        accountNavigationItem.cancelButton = cancelButton
        
        // Init Text Fields
        emailTextField.delegate = self
        emailTextField.addImageWith(name: "mailIconTinyWht")
        
        passwordTextField.delegate = self
        passwordTextField.addImageWith(name: "lockIconTinyWht")
        
        passwordConfirmationTextField.delegate = self
        passwordConfirmationTextField.addImageWith(name: "lockIconTinyWht")
        
        // If they already have been entered (user went back) init text field text from account object
        if let email = account!.email {
            self.emailTextField.text = email
        }
        if let password = account!.password {
            self.passwordTextField.text = password
        }
        
        // Validate Submit button
        accountNavigationItem.actionButton?.isEnabled = validEntry(confirmation: nil)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        // Clear password confirmation when the screen exits (force re-entry)
        passwordConfirmationTextField.text = nil
    }
    
    // MARK: - User Action
    
    func didNext() {
        passwordTextField.setHighlightState(highlightState: passwordTextField.isFirstResponder ? .show : .hide, animated: true)
        passwordConfirmationTextField.setHighlightState(highlightState: passwordConfirmationTextField.isFirstResponder ? .show : .hide, animated: true)
        
        let viewController = UIStoryboard(name: "CreateAccount", bundle: nil).instantiateViewController(withIdentifier: "CreateAccountSecurityViewController") as! AccountViewController
        viewController.account = account
        accountNavigationController?.push(viewController: viewController, animated: true)
    }
    
    func didCancel() {
        Analytics.buttonClicked(buttonEventName: "Create_Account_Step_2_Close")
        let viewController = UIStoryboard(name: "CreateAccount", bundle: nil).instantiateViewController(withIdentifier: "CreateAccountSkipViewController") as! AccountViewController
        viewController.account = account
        accountNavigationController?.push(viewController: viewController, animated: true)
    }
    
    func didAccount() {
        let viewController = UIStoryboard(name: "Login", bundle: nil).instantiateViewController(withIdentifier: "LoginCredentialsViewController") as! AccountViewController
        accountNavigationController?.setRootViewController(viewController: viewController, animated: true)
    }
    
    // MARK: - Validation
    
    func validEmail(email:String) -> Bool {
        let regex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        let predicate = NSPredicate(format:"SELF MATCHES %@", regex)
        
        return predicate.evaluate(with: email)
    }
    
    func validPassword(password: String) -> Bool {
        let regex = "^(?=.*[a-z])(?=.*[A-Z])(?=.*[0-9]).{8,}$"
        let predicate = NSPredicate(format:"SELF MATCHES %@", regex)
        
        return predicate.evaluate(with: password)
    }
    
    func validEntry(confirmation: String?) -> Bool {
        if account?.email != nil {
            if let password = account?.password {
                if let confirmation = confirmation {
                    return confirmation == password
                } else if let confirmation = passwordConfirmationTextField.text {
                    return confirmation == password
                }
            }
        }
        return false
    }
    
}

extension CreateAccountEmailViewController: UITextFieldDelegate {
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        let transparentTextField = textField as! TransparentTextField
        
        // Focus
        //Hide right textfield image
        transparentTextField.addStatusImageWith(name: "")
        
        transparentTextField.hasFocus = true
        
        // Highlight
        if transparentTextField == passwordTextField {
            if (passwordTextField.highlightState == .error && passwordConfirmationTextField.highlightState == .error) {
                passwordConfirmationTextField.setHighlightState(highlightState: .hide, animated: true)
                passwordConfirmationTextField.addStatusImageWith(name: "")
            }
        } else if transparentTextField == passwordConfirmationTextField {
            if (passwordTextField.highlightState == .error && passwordConfirmationTextField.highlightState == .error) {
                passwordTextField.setHighlightState(highlightState: .hide, animated: true)
            }
        }
        transparentTextField.setHighlightState(highlightState: .show, animated: true)
        
        // Select All
        if let text = textField.text {
            if (text.characters.count > 0) {
                DispatchQueue.main.async {
                    transparentTextField.selectAll(nil)
                }
            }
        }
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let text: NSString = (textField.text ?? "") as NSString
        let resultString = text.replacingCharacters(in: range, with: string)
        // let transparentTextField = textField as! TransparentTextField
        
        // Hide any errors when the user starts typing again
        accountNavigationController?.hideError()
        
        // Enable "Next" Button?
        accountNavigationItem.actionButton?.isEnabled = validEntry(confirmation: resultString)
        
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        // Fixes bug where text in textfield flies in from the top left
        // This is required for any view controller that uses accountNavigationController.displayError()
        textField.layoutIfNeeded()
        
        let transparentTextField = textField as! TransparentTextField
        
        // Focus
        transparentTextField.hasFocus = false
        
        // Highlight
        if (transparentTextField.highlightState != .error) {
            transparentTextField.setHighlightState(highlightState: .hide, animated: true)
        }
        
        // Validate Email
        if (transparentTextField == emailTextField) {
            // First, local validation
            if validEmail(email: emailTextField.text!) {
                // Second, server validation
                AWS.sharedInstance.checkUserStatus(userName: emailTextField.text!, callBack: { (status) in
                    print("check user status = \(status)")
                    switch status {
                    case 404:
                        // Available
                        self.account!.email = self.emailTextField.text!
                        self.emailTextField.setHighlightState(highlightState: .hide, animated: true)
                        
                        // Enable "Next" Button?
                        self.accountNavigationItem.actionButton?.isEnabled = self.validEntry(confirmation: nil)
                        break
                    case 200:
                        // Not Available
                        self.account!.email = nil
                        self.emailTextField.setHighlightState(highlightState: .error, animated: true)
                        self.accountNavigationController?.displayError(errorString: "Email address has already been registered")
                        
                        // Enable "Next" Button?
                        self.accountNavigationItem.actionButton?.isEnabled = self.validEntry(confirmation: nil)
                        break
                    case 401:                        // Not Available
                        self.account!.email = nil
                        self.emailTextField.setHighlightState(highlightState: .error, animated: true)
                        self.accountNavigationController?.displayError(errorString: "Email address has already been registered")
                        
                        // Enable "Next" Button?
                        self.accountNavigationItem.actionButton?.isEnabled = self.validEntry(confirmation: nil)
                        break
                    default:
                        // Unknown
                        break
                    }
                })
            } else {
                // Throw local error
                account!.email = nil
                emailTextField.setHighlightState(highlightState: .error, animated: true)
                accountNavigationController?.displayError(errorString: "Invalid email address")
            }
        }
        
        // Validate Password
        if (transparentTextField == passwordTextField) {
            
            if validPassword(password: passwordTextField.text!) {
                // Save valid password
                account!.password = passwordTextField.text!
                passwordTextField.addStatusImageWith(name: "checkmarkIconTinyWht")
            } else  {
                // Remove password
                account!.password = nil
                 accountNavigationController?.displayError(errorString: "Password must be 8 characters or more with 1 lower and 1 uppercase letter plus 1 number.")
                // Throw local error
                passwordTextField.setHighlightState(highlightState: .error, animated: true)
                passwordTextField.addStatusImageWith(name: "warningIconTinyWht")
               
            }
        }
        if (transparentTextField == passwordConfirmationTextField) {
            if let password = passwordTextField.text {
                if password != passwordConfirmationTextField.text! {
                    accountNavigationController?.displayError(errorString: "Your passwords do not match")
                     let image = validPassword(password:passwordTextField.text!) ? "checkmarkIconTinyWht": "warningIconTinyWht"
                    passwordTextField.addStatusImageWith(name: image)
                    passwordConfirmationTextField.addStatusImageWith(name: "warningIconTinyWht")

                    passwordTextField.setHighlightState(highlightState: .error, animated: true)
                    passwordConfirmationTextField.setHighlightState(highlightState: .error, animated: true)
                   
                    
                }else{
                    passwordConfirmationTextField.addStatusImageWith(name: "checkmarkIconTinyWht")
                }
                
            }
        }
        
        // Enable "Next" Button?
        accountNavigationItem.actionButton?.isEnabled = validEntry(confirmation: nil)
        
        // A second call to layoutIfNeeded() is required here.
        // Fixes bug where the right icons fly in by forcing redraw before animation of keyboard/error takes place
        textField.layoutIfNeeded()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if (textField == emailTextField) {
            passwordTextField.becomeFirstResponder()
        } else if (textField == passwordTextField) {
            passwordConfirmationTextField.becomeFirstResponder()
        } else if (textField == passwordConfirmationTextField) {
            if (accountNavigationItem.actionButton!.isEnabled) {
                didNext()
            } else {
                passwordTextField.setHighlightState(highlightState: .error, animated: true)
                passwordConfirmationTextField.setHighlightState(highlightState: .error, animated: true)
                
                accountNavigationController?.displayError(errorString: "Your passwords do not match")
                passwordTextField.addStatusImageWith(name: "warningIconTinyWht")
                passwordConfirmationTextField.addStatusImageWith(name: "warningIconTinyWht")

            }
        }
        
        return false;
    }
}
