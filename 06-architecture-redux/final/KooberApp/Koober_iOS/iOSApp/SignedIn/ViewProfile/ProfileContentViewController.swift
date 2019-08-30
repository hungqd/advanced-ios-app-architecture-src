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
import KooberKit
import RxSwift

public class ProfileContentViewController: NiblessViewController {

  // MARK: - Properties
  // State
  let state: Observable<ProfileViewControllerState>
  let disposeBag = DisposeBag()

  // User Interactions
  let userInteractions: ProfileUserInteractions

  // Root View
  var rootView: ProfileContentRootView { return view as! ProfileContentRootView }

  // MARK: - Methods
  init(state: Observable<ProfileViewControllerState>,
       userInteractions: ProfileUserInteractions) {
    self.state = state
    self.userInteractions = userInteractions

    super.init()

    self.navigationItem.title = "My Profile"
    self.navigationItem.rightBarButtonItem =
      UIBarButtonItem(barButtonSystemItem: .done,
                      target: self,
                      action: #selector(dismissProfile))
  }

  public override func loadView() {
    view = ProfileContentRootView(userInteractions: userInteractions)
  }

  public override func viewDidLoad() {
    super.viewDidLoad()

    observeState()
  }

  func observeState() {
    state
      .map { $0.profile }
      .distinctUntilChanged()
      .subscribe(onNext: { [weak self] userProfile in
        self?.rootView.userProfile = userProfile
      })
      .disposed(by: disposeBag)

    state
      .map { $0.errorsToPresent }
      .distinctUntilChanged()
      .subscribe(onNext: { [weak self] errorsToPresent in
        if let errorMessage = errorsToPresent.first {
          self?.present(errorMessage: errorMessage) {
            self?.userInteractions.finishedPresenting(errorMessage)
          }
        }
      })
      .disposed(by: disposeBag)
  }

  @objc
  func dismissProfile() {
    userInteractions.dismissProfile()
  }
}
