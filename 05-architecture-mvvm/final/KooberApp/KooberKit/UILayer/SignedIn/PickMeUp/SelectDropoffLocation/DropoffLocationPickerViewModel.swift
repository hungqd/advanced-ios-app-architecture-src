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

public class DropoffLocationPickerViewModel {

  // MARK: - Properties
  let pickupLocation: Location
  let locationRepository: LocationRepository
  let dropoffLocationDeterminedResponder: DropoffLocationDeterminedResponder
  let cancelDropoffLocationSelectionResponder: CancelDropoffLocationSelectionResponder

  public var errorMessages: Observable<ErrorMessage> {
    return errorMessagesSubject.asObservable()
  }
  private let errorMessagesSubject = PublishSubject<ErrorMessage>()

  let disposeBag = DisposeBag()

  public let searchInput = BehaviorSubject<String>(value: "")
  public let searchResults = BehaviorSubject<[NamedLocation]>(value: [])
  var currentSearchID: UUID?

  // MARK: - Methods
  public init(pickupLocation: Location,
              locationRepository: LocationRepository,
              dropoffLocationDeterminedResponder: DropoffLocationDeterminedResponder,
              cancelDropoffLocationSelectionResponder: CancelDropoffLocationSelectionResponder) {
    self.pickupLocation = pickupLocation
    self.locationRepository = locationRepository
    self.dropoffLocationDeterminedResponder = dropoffLocationDeterminedResponder
    self.cancelDropoffLocationSelectionResponder = cancelDropoffLocationSelectionResponder
    searchInput
      .asObservable()
      .subscribe(onNext: searchForDropoffLocations(using:))
      .disposed(by: disposeBag)
  }

  func searchForDropoffLocations(using query: String) {
    let searchID = UUID()
    currentSearchID = searchID
    locationRepository
      .searchForLocations(using: query, pickupLocation: pickupLocation)
      .done { [weak self] searchResults in
        guard searchID == self?.currentSearchID else { return }
        self?.update(searchResults: searchResults)
      }
      .catch { error in
        let errorMessage = ErrorMessage(title: "Location Error",
                                        message: "Sorry, we ran into an unexpected error while getting locations.\nPlease try again.")
        self.errorMessagesSubject.onNext(errorMessage)
      }
  }

  private func update(searchResults: [NamedLocation]) {
    self.searchResults.onNext(searchResults)
  }

  public func select(dropoffLocation: NamedLocation) {
    dropoffLocationDeterminedResponder.dropOffUser(at: dropoffLocation.location)
  }

  @objc
  public func cancelDropoffLocationSelection() {
    cancelDropoffLocationSelectionResponder.cancelDropoffLocationSelection()
  }
}
