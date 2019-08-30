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
import PromiseKit

public class SignUpViewModel {

  // MARK: - Properties
  let userSessionRepository: UserSessionRepository
  let signedInResponder: SignedInResponder

  // MARK: - Methods
  public init(userSessionRepository: UserSessionRepository,
              signedInResponder: SignedInResponder) {
    self.userSessionRepository = userSessionRepository
    self.signedInResponder = signedInResponder
  }

  public let nameInput = BehaviorSubject<String>(value: "")
  public let nicknameInput = BehaviorSubject<String>(value: "")
  public let emailInput = BehaviorSubject<String>(value: "")
  public let mobileNumberInput = BehaviorSubject<String>(value: "")
  public let passwordInput = BehaviorSubject<Secret>(value: "")

  public var errorMessages: Observable<ErrorMessage> {
    return errorMessagesSubject.asObservable()
  }
  public let errorMessagesSubject = PublishSubject<ErrorMessage>()

  @objc
  public func signUp() {
    let (name, nickname, email, mobileNumber, password) = getFieldValues()
    let newAccount = NewAccount(fullName: name,
                                nickname: nickname,
                                email: email,
                                mobileNumber: mobileNumber,
                                password: password)
    userSessionRepository.signUp(newAccount: newAccount)
      .done(signedInResponder.signedIn(to:))
      .catch(handleSignUpError)
  }

  func getFieldValues() -> (String, String, String, String, Secret) {
    do {
      let name = try nameInput.value()
      let nickname = try nicknameInput.value()
      let email = try emailInput.value()
      let mobileNumber = try mobileNumberInput.value()
      let password = try passwordInput.value()
      return (name, nickname, email, mobileNumber, password)
    } catch {
      fatalError("Error accessing field values from sign up screen.")
    }
  }

  func handleSignUpError(_ error: Error) {
    errorMessagesSubject.onNext(ErrorMessage(title: "Sign Up Failed",
                                             message: "Could not sign up.\nPlease try again."))
  }
}
