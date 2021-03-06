//
//  SignInViewController.swift
//  MySampleApp
//
//
// Copyright 2017 Amazon.com, Inc. or its affiliates (Amazon). All Rights Reserved.
//
// Code generated by AWS Mobile Hub. Amazon gives unlimited permission to 
// copy, distribute and modify it.
//
// Source code generated from template: aws-my-sample-app-ios-swift v0.12
//
//

import UIKit
import AWSMobileHubHelper
import AWSCognitoIdentityProvider

class SignInViewController: UIViewController {
    @IBOutlet weak var anchorView: UIView!

// Support code for Facebook provider UI.
    @IBOutlet weak var facebookButton: UIButton!

// Support code for Google provider UI.
    @IBOutlet weak var googleButton: UIButton!

    @IBOutlet weak var customProviderButton: UIButton!
    @IBOutlet weak var customCreateAccountButton: UIButton!
    @IBOutlet weak var customForgotPasswordButton: UIButton!
    @IBOutlet weak var customUserIdField: UITextField!
    @IBOutlet weak var customPasswordField: UITextField!
    @IBOutlet weak var leftHorizontalBar: UIView!
    @IBOutlet weak var rightHorizontalBar: UIView!
    @IBOutlet weak var orSignInWithLabel: UIView!
    
    var didSignInObserver: AnyObject!
    
    var passwordAuthenticationCompletion: AWSTaskCompletionSource<AnyObject>?
    
    // MARK: - View lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
         print("Sign In Loading.")
        
            didSignInObserver =  NotificationCenter.default.addObserver(forName: NSNotification.Name.AWSIdentityManagerDidSignIn,
                object: AWSIdentityManager.default(),
                queue: OperationQueue.main,
                using: {(note: Notification) -> Void in
                    // perform successful login actions here
            })

                facebookButton.removeFromSuperview()
                googleButton.removeFromSuperview()
                // Custom UI Setup
                customProviderButton.addTarget(self, action: #selector(self.handleCustomSignIn), for: .touchUpInside)
                customCreateAccountButton.addTarget(self, action: #selector(self.handleUserPoolSignUp), for: .touchUpInside)
                customForgotPasswordButton.addTarget(self, action: #selector(self.handleUserPoolForgotPassword), for: .touchUpInside)
                customProviderButton.setImage(UIImage(named: "LoginButton"), for: UIControlState())
    }
    
    deinit {
        NotificationCenter.default.removeObserver(didSignInObserver)
    }
    
    func dimissController() {
        self.dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Utility Methods
    
    func handleLoginWithSignInProvider(_ signInProvider: AWSSignInProvider) {
        AWSIdentityManager.default().login(signInProvider: signInProvider, completionHandler: {(result: Any?, error: Error?) in
            // If no error reported by SignInProvider, discard the sign-in view controller.
            if error == nil {
                DispatchQueue.main.async(execute: {
                    self.presentingViewController?.dismiss(animated: true, completion: nil)
                })
            }
             print("result = \(result), error = \(error)")
        })
    }

    func showErrorDialog(_ loginProviderName: String, withError error: NSError) {
         print("\(loginProviderName) failed to sign in w/ error: \(error)")
        let alertController = UIAlertController(title: NSLocalizedString("Sign-in Provider Sign-In Error", comment: "Sign-in error for sign-in failure."), message: NSLocalizedString("\(loginProviderName) failed to sign in w/ error: \(error)", comment: "Sign-in message structure for sign-in failure."), preferredStyle: .alert)
        let doneAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: "Label to cancel sign-in failure."), style: .cancel, handler: nil)
        alertController.addAction(doneAction)
        present(alertController, animated: true, completion: nil)
    }

    // MARK: - IBActions

    
}
