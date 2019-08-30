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

public class RideOptionPickerViewModel {

  // MARK: - Properties
  let repository: RideOptionRepository
  public var pickerSegments: Observable<RideOptionSegmentedControlViewModel> { return pickerSegmentsSubject.asObservable() }
  private let pickerSegmentsSubject = BehaviorSubject<RideOptionSegmentedControlViewModel>(value: RideOptionSegmentedControlViewModel())
  let rideOptionDeterminedResponder: RideOptionDeterminedResponder

  public var errorMessages: Observable<ErrorMessage> {
    return errorMessagesSubject.asObservable()
  }
  private let errorMessagesSubject = PublishSubject<ErrorMessage>()

  // MARK: - Methods
  public init(repository: RideOptionRepository,
              rideOptionDeterminedResponder: RideOptionDeterminedResponder) {
    self.repository = repository
    self.rideOptionDeterminedResponder = rideOptionDeterminedResponder
  }

  public func loadRideOptions(availableAt pickupLocation: Location, screenScale: CGFloat) {
    repository
      .readRideOptions(availableAt: pickupLocation)
      .then { (rideOptions: [RideOption]) -> Promise<RideOptionPickerRideOptions> in
        let pickerRideOptions = RideOptionPickerRideOptions(rideOptions: rideOptions)
        return Promise.value(pickerRideOptions)
      }
      .then { (pickerRideOptions: RideOptionPickerRideOptions) -> Promise<[RideOptionSegmentViewModel]>  in
        let factory = RideOptionSegmentsFactory(state: pickerRideOptions)
        let segments = factory.makeSegments(screenScale: screenScale)
        return Promise.value(segments)
      }
      .done { segments in
        self.pickerSegmentsSubject.onNext(RideOptionSegmentedControlViewModel(segments: segments))
      }
      .catch { error in
        let errorMessage = ErrorMessage(title: "Ride Option Error",
                                        message: "We're having trouble getting available ride options. Please start a new ride and try again.")
        self.errorMessagesSubject.onNext(errorMessage)
      }
  }

  public func select(rideOptionID: RideOptionID) {
    do {
      var segments = try pickerSegmentsSubject.value().segments
      for (index, segment) in segments.enumerated() {
        segments[index].isSelected = (segment.id == rideOptionID)
      }
      pickerSegmentsSubject.onNext(RideOptionSegmentedControlViewModel(segments: segments))
      rideOptionDeterminedResponder.pickUpUser(in: rideOptionID)
    } catch {
      fatalError("Error reading value from picker segments subject.")
    }
  }
}
