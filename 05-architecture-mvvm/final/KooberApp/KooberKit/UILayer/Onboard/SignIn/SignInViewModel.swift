/// Copyright (c) 2018 Razeware LLC
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

import Foundation
import RxSwift

public class SignInViewModel {

  // MARK: - Properties
  let userSessionRepository: UserSessionRepository
  let signedInResponder: SignedInResponder

  // MARK: - Methods
  public init(userSessionRepository: UserSessionRepository,
              signedInResponder: SignedInResponder) {
    self.userSessionRepository = userSessionRepository
    self.signedInResponder = signedInResponder
  }

  public let emailInput = BehaviorSubject<String>(value: "")
  public let passwordInput = BehaviorSubject<Secret>(value: "")

  public var errorMessages: Observable<ErrorMessage> {
    return errorMessagesSubject.asObserver()
  }
  public let errorMessagesSubject = PublishSubject<ErrorMessage>()

  public let emailInputEnabled = BehaviorSubject<Bool>(value: true)
  public let passwordInputEnabled = BehaviorSubject<Bool>(value: true)
  public let signInButtonEnabled = BehaviorSubject<Bool>(value: true)
  public let signInActivityIndicatorAnimating = BehaviorSubject<Bool>(value: false)

  @objc
  public func signIn() {
    indicateSigningIn()
    let (email, password) = getEmailPassword()
    userSessionRepository.signIn(email: email, password: password)
      .done(signedInResponder.signedIn(to:))
      .catch(indicateErrorSigningIn)
  }

  func indicateSigningIn() {
    emailInputEnabled.onNext(false)
    passwordInputEnabled.onNext(false)
    signInButtonEnabled.onNext(false)
    signInActivityIndicatorAnimating.onNext(true)
  }

  func getEmailPassword() -> (String, Secret) {
    do {
      let email = try emailInput.value()
      let password = try passwordInput.value()
      return (email, password)
    } catch {
      fatalError("Error reading email and password from behavior subjects.")
    }
  }

  func indicateErrorSigningIn(_ error: Error) {
    errorMessagesSubject.onNext(ErrorMessage(title: "Sign In Failed",
                                             message: "Could not sign in.\nPlease try again."))
    emailInputEnabled.onNext(true)
    passwordInputEnabled.onNext(true)
    signInButtonEnabled.onNext(true)
    signInActivityIndicatorAnimating.onNext(false)
  }
}
