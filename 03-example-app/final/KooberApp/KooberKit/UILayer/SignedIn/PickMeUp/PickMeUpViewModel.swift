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

public class PickMeUpViewModel: DropoffLocationDeterminedResponder,
                                RideOptionDeterminedResponder,
                                CancelDropoffLocationSelectionResponder {

  // MARK: - Properties
  public var view: Observable<PickMeUpView> { return viewSubject.asObservable() }
  private let viewSubject: BehaviorSubject<PickMeUpView>
  var progress: PickMeUpRequestProgress
  let newRideRepository: NewRideRepository
  let newRideRequestAcceptedResponder: NewRideRequestAcceptedResponder
  let mapViewModel: PickMeUpMapViewModel

  public var shouldDisplayWhereTo: Observable<Bool> { return shouldDisplayWhereToSubject.asObservable() }
  private let shouldDisplayWhereToSubject = BehaviorSubject<Bool>(value: true)
  public var errorMessages: Observable<ErrorMessage> { return errorMessagesSubject.asObservable() }
  private let errorMessagesSubject = PublishSubject<ErrorMessage>()
  public let errorPresentation: BehaviorSubject<ErrorPresentation?> = BehaviorSubject(value: nil)

  let disposeBag = DisposeBag()

  // MARK: - Methods
  public init(pickupLocation: Location,
              newRideRepository: NewRideRepository,
              newRideRequestAcceptedResponder: NewRideRequestAcceptedResponder,
              mapViewModel: PickMeUpMapViewModel,
              shouldDisplayWhereTo: Bool = true) {
    self.viewSubject = BehaviorSubject(value: .initial)
    self.progress = .initial(pickupLocation: pickupLocation)
    self.newRideRepository = newRideRepository
    self.newRideRequestAcceptedResponder = newRideRequestAcceptedResponder
    self.mapViewModel = mapViewModel
    self.shouldDisplayWhereToSubject.onNext(shouldDisplayWhereTo)

    viewSubject
      .asObservable() 
      .subscribe(onNext: { [weak self] view in
        self?.updateShouldDisplayWhereTo(basedOn: view)
      })
      .disposed(by: disposeBag)
  }

  func updateShouldDisplayWhereTo(basedOn view: PickMeUpView) {
    shouldDisplayWhereToSubject.onNext(shouldDisplayWhereTo(during: view))
  }

  func shouldDisplayWhereTo(during view: PickMeUpView) -> Bool {
    switch view {
    case .initial, .selectDropoffLocation:
      return true
    case .selectRideOption, .confirmRequest, .sendingRideRequest, .final:
      return false
    }
  }

  public func cancelDropoffLocationSelection() {
    viewSubject.onNext(.initial)
  }

  public func dropOffUser(at location: Location) {
    guard case let .initial(pickupLocation) = progress else {
      fatalError()
    }
    let waypoints = NewRideWaypoints(pickupLocation: pickupLocation,
                                     dropoffLocation: location)
    progress = .waypointsDetermined(waypoints: waypoints)
    viewSubject.onNext(.selectRideOption)
    mapViewModel.dropoffLocation.onNext(location)
  }

  public func pickUpUser(in rideOptionID: RideOptionID) {
    if case let .waypointsDetermined(waypoints) = progress {
      let rideRequest = NewRideRequest(waypoints: waypoints,
                                       rideOptionID: rideOptionID)
      progress = .rideRequestReady(rideRequest: rideRequest)
      viewSubject.onNext(.confirmRequest)
    } else if case let .rideRequestReady(oldRideRequest) = progress {
      let rideRequest = NewRideRequest(waypoints: oldRideRequest.waypoints,
                                       rideOptionID: rideOptionID)
      progress = .rideRequestReady(rideRequest: rideRequest)
      viewSubject.onNext(.confirmRequest)
    } else {
      fatalError()
    }
  }

  @objc
  public func showSelectDropoffLocationView() {
    viewSubject.onNext(.selectDropoffLocation)
  }
  
  @objc
  public func sendRideRequest() {
    guard case let .rideRequestReady(rideRequest) = progress else {
      fatalError()
    }
    viewSubject.onNext(.sendingRideRequest)
    newRideRepository.request(newRide: rideRequest)
      .done {
        self.viewSubject.onNext(.final)
      }.catch { error in
        self.goToNextScreenAfterErrorPresentation()
        let errorMessage = ErrorMessage(title: "Ride Request Error",
                                        message: "There was an error trying to confirm your ride request.\nPlease try again.")
        self.errorMessagesSubject.onNext(errorMessage)
      }
  }

  public func finishedSendingNewRideRequest() {
    newRideRequestAcceptedResponder.newRideRequestAccepted()
  }

  func goToNextScreenAfterErrorPresentation() {
    _ = errorPresentation
      .filter { $0 == .dismissed }
      .take(1)
      .subscribe(onNext: { [weak self] _ in
        self?.viewSubject.onNext(PickMeUpView.confirmRequest)
      })
  }
}
