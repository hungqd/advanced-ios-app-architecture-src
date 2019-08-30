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

public class DropoffLocationPickerContentViewController: NiblessViewController {

  // MARK: - Properties
  // State
  let pickupLocation: Location
  let state: Observable<DropoffLocationPickerViewControllerState>
  let disposeBag = DisposeBag()

  // User Interactions
  let userInteractions: DropoffLocationPickerUserInteractions

  // Root View
  var rootView: DropoffLocationPickerContentRootView {
    return view as! DropoffLocationPickerContentRootView
  }

  // MARK: - Methods
  init(pickupLocation: Location,
       state: Observable<DropoffLocationPickerViewControllerState>,
       userInteractions: DropoffLocationPickerUserInteractions) {
    self.pickupLocation = pickupLocation
    self.state = state
    self.userInteractions = userInteractions

    super.init()

    self.navigationItem.title = "Where To?"
    self.navigationItem.largeTitleDisplayMode = .automatic
    self.navigationItem.leftBarButtonItem =
      UIBarButtonItem(barButtonSystemItem: .cancel,
                      target: self,
                      action: #selector(cancelDropoffLocationPicker))
  }

  public override func loadView() {
    view = DropoffLocationPickerContentRootView(userInteractions: userInteractions)
  }

  public override func viewDidLoad() {
    super.viewDidLoad()

    setUpSearchController()
    observeState()
  }

  public override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)

    userInteractions.searchForDropoffLocations(using: "", for: pickupLocation)
  }

  public override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)

    navigationItem.searchController?.isActive = false
  }

  func setUpSearchController() {
    let pickupLocationCopy = self.pickupLocation
    let searchController = ObservableUISearchController(searchResultsController: nil)
    searchController.obscuresBackgroundDuringPresentation = false
    searchController.observable
      .debounce(0.9, scheduler: MainScheduler.instance)
      .subscribe(onNext: { [weak self] query in
        self?.userInteractions.searchForDropoffLocations(using: query, for: pickupLocationCopy)
      })
      .disposed(by: disposeBag)

    navigationItem.searchController = searchController
    definesPresentationContext = true
  }

  func observeState() {
    state
      .subscribe(onNext: { [weak self] viewControllerState in
        self?.rootView.searchResults = viewControllerState.searchResults
      })
      .disposed(by: disposeBag)

    state
      .map { $0.errorsToPresent }
      .distinctUntilChanged()
      .subscribe(onNext: { [weak self] errorsToPresent in
         if let errorMessage = errorsToPresent.first {
          if let presentedViewController = self?.presentedViewController {
            presentedViewController.present(errorMessage: errorMessage) {
              self?.userInteractions.finishedPresenting(errorMessage)
            }
          } else {
            self?.present(errorMessage: errorMessage) {
              self?.userInteractions.finishedPresenting(errorMessage)
            }
          }
        }
      })
      .disposed(by: disposeBag)
  }

  @objc
  func cancelDropoffLocationPicker() {
    userInteractions.cancelDropoffLocationPicker()
  }
}

