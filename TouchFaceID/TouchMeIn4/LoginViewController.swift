/// Copyright (c) 2017 Razeware LLC
///
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
///
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
///
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import UIKit
import CoreData

// Keychain Configuration
struct KeychainConfiguration {
  static let serviceName = "TouchMeIn"
  static let accessGroup: String? = nil
}

class LoginViewController: UIViewController {

  // MARK: Properties
  var managedObjectContext: NSManagedObjectContext?

  var passwordItems: [KeychainPasswordItem] = []
  let createLoginButtonTag = 0
  let loginButtonTag = 1
  let biometryHandler = BiometryAuth()

  // MARK: - IBOutlets
  @IBOutlet weak var usernameTextField: UITextField!
  @IBOutlet weak var passwordTextField: UITextField!
  @IBOutlet weak var createInfoLabel: UILabel!
  @IBOutlet weak var loginButton: UIButton!
  @IBOutlet weak var touchIDButton: UIButton!

  // MARK: - View Life Cycle
  override func viewDidLoad() {
    super.viewDidLoad()

    let hasLogin = UserDefaults.standard.bool(forKey: "hasLoginKey")

    if hasLogin {
      loginButton.setTitle("Login", for: .normal)
      loginButton.tag = loginButtonTag
      createInfoLabel.isHidden = true
    } else {
      loginButton.setTitle("Create", for: .normal)
      loginButton.tag = createLoginButtonTag
      createInfoLabel.isHidden = false
    }

    if let storedUsername = UserDefaults.standard.value(forKey: "username") as? String {
      usernameTextField.text = storedUsername
    }
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    touchIDButton.alpha = 0
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)

    // Automagically log the user in
    //    let touchBool = touchMe.canEvaluatePolicy()
    //    if touchBool {
    //      touchIDLoginAction()
    //    }

    // Fade in biometry button
    let buttonImage: UIImage?
    switch biometryHandler.availability.biometricType {
    case .none: buttonImage = nil
    case .touchID: buttonImage = UIImage(named: "Touch-icon-lg")
    case .faceID: buttonImage = UIImage(named: "FaceIcon")
    }
    touchIDButton.setImage(buttonImage,  for: .normal)
    if buttonImage != nil {
      UIView.animate(withDuration: 1) { [weak self] in
        self?.touchIDButton.alpha = 1
      }
    }
  }

  override var preferredStatusBarStyle: UIStatusBarStyle {
    return .lightContent
  }
}

// MARK: - IBActions
extension LoginViewController {

  @IBAction func loginAction(sender: UIButton) {
    // 1
    // Check that text has been entered into both the username and password fields.
    guard let newAccountName = usernameTextField.text,
      let newPassword = passwordTextField.text,
      !newAccountName.isEmpty,
      !newPassword.isEmpty else {
        showLoginFailedAlert()
        return
    }

    // 2
    usernameTextField.resignFirstResponder()
    passwordTextField.resignFirstResponder()

    // 3
    if sender.tag == createLoginButtonTag {
      // 4
      let hasLoginKey = UserDefaults.standard.bool(forKey: "hasLoginKey")
      if !hasLoginKey && usernameTextField.hasText {
        UserDefaults.standard.setValue(usernameTextField.text, forKey: "username")
      }

      // 5
      do {
        // This is a new account, create a new keychain item with the account name.
        let passwordItem = KeychainPasswordItem(service: KeychainConfiguration.serviceName,
                                                account: newAccountName,
                                                accessGroup: KeychainConfiguration.accessGroup)

        // Save the password for the new item.
        try passwordItem.savePassword(newPassword)
      } catch {
        fatalError("Error updating keychain - \(error)")
      }

      // 6
      UserDefaults.standard.set(true, forKey: "hasLoginKey")
      loginButton.tag = loginButtonTag
      performSegue(withIdentifier: "dismissLogin", sender: self)
    } else if sender.tag == loginButtonTag {
      // 7
      if checkLogin(username: newAccountName, password: newPassword) {
        performSegue(withIdentifier: "dismissLogin", sender: self)
      } else {
        // 8
        showLoginFailedAlert()
      }
    }
  }

  @IBAction func touchIDLoginAction() {

    biometryHandler.authenticateUser() { [weak self] message in

      guard let message = message else {
        self?.performSegue(withIdentifier: "dismissLogin", sender: self)
        return
      }

      // if the completion is not nil show an alert
      let alertView = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
      let okAction = UIAlertAction(title: "Darn!", style: .default)
      alertView.addAction(okAction)
      self?.present(alertView, animated: true)
    }
  }

  func checkLogin(username: String, password: String) -> Bool {
    guard username == UserDefaults.standard.value(forKey: "username") as? String else {
      return false
    }

    do {
      let passwordItem = KeychainPasswordItem(service: KeychainConfiguration.serviceName,
                                              account: username,
                                              accessGroup: KeychainConfiguration.accessGroup)
      let keychainPassword = try passwordItem.readPassword()
      return password == keychainPassword
    } catch {
      fatalError("Error reading password from keychain - \(error)")
    }
  }

  private func showLoginFailedAlert() {
    let alertView = UIAlertController(title: "Login Problem",
                                      message: "Wrong username or password.",
                                      preferredStyle:. alert)
    let okAction = UIAlertAction(title: "Foiled Again!", style: .default)
    alertView.addAction(okAction)
    present(alertView, animated: true)
  }
}

