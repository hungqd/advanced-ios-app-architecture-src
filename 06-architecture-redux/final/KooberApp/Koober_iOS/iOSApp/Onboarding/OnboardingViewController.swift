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

import UIKit
import KooberUIKit
import PromiseKit
import KooberKit
import RxSwift

public class OnboardingViewController: NiblessNavigationController {

  // MARK: - Properties
  // State
  let state: Observable<OnboardingState>
  var stateDisposable: Disposable?
  var welcomePushed = false

  // User Interactions
  let userInteractions: OnboardingUserInteractions

  // Child View Controllers
  let welcomeViewController: WelcomeViewController
  let signInViewController: SignInViewController
  let signUpViewController: SignUpViewController

  // MARK: - Methods
  init(state: Observable<OnboardingState>,
       userInteractions: OnboardingUserInteractions,
       welcomeViewController: WelcomeViewController,
       signInViewController: SignInViewController,
       signUpViewController: SignUpViewController) {
    self.state = state
    self.userInteractions = userInteractions
    self.welcomeViewController = welcomeViewController
    self.signInViewController = signInViewController
    self.signUpViewController = signUpViewController
    super.init()
    self.delegate = self
  }

  public override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)

    observeState()
  }

  public override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)

    stopObservingState()
  }

  func observeState() {
    stateDisposable =
      state
        .distinctUntilChanged(OnboardingState.sameCase)
        .subscribe(onNext: { [weak self] onboardingState in
          self?.present(onboardingState)
        })
  }

  func stopObservingState() {
    stateDisposable?.dispose()
  }

  func present(_ onboardingState: OnboardingState) {
    switch onboardingState {
    case .welcoming:
      presentWelcome()
    case .signingIn:
      presentSignIn()
    case .signingUp:
      presentSignUp()
    }
  }

  func presentWelcome() {
    if shouldSkipWelcomePresentation() {
      return
    }
    pushViewController(welcomeViewController, animated: false)
    welcomePushed = true
  }

  func shouldSkipWelcomePresentation() -> Bool {
    if let _ = topViewController as? WelcomeViewController {
      return true
    } else {
      return false
    }
  }

  func presentSignIn() {
    pushViewController(signInViewController, animated: true)
  }

  func presentSignUp() {
    pushViewController(signUpViewController, animated: true)
  }

  func hideOrShowNavigationBar(navigationWillShow viewControllerToBeShown: UIViewController, animated: Bool) {
    if viewControllerToBeShown is WelcomeViewController {
      hideNavigationBar(animated: animated)
    } else {
      showNavigationBar(animated: animated)
    }
  }
}

// MARK: - Navigation Bar Presentation
extension OnboardingViewController {

  func hideNavigationBar(animated: Bool) {
    if animated {
      transitionCoordinator?.animate(alongsideTransition: { context in
        self.setNavigationBarHidden(true, animated: animated)
      })
    } else {
      setNavigationBarHidden(true, animated: false)
    }
  }

  func showNavigationBar(animated: Bool) {
    if self.isNavigationBarHidden {
      self.setNavigationBarHidden(false, animated: animated)
    }
  }
}

// MARK: - UINavigationControllerDelegate
extension OnboardingViewController: UINavigationControllerDelegate {

  public func navigationController(_ navigationController: UINavigationController,
                                   willShow viewController: UIViewController,
                                   animated: Bool) {
    hideOrShowNavigationBar(navigationWillShow: viewController, animated: animated)
  }

  public func navigationController(_ navigationController: UINavigationController,
                                   didShow viewController: UIViewController,
                                   animated: Bool) {
    guard welcomePushed else {
      return
    }
    if viewController is WelcomeViewController {
      userInteractions.navigatedBackToWelcome()
    }
  }
}
