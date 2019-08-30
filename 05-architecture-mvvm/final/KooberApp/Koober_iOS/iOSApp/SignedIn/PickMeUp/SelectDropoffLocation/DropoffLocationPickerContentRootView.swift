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

enum CellIdentifier: String {

  case cell
}

class DropoffLocationPickerContentRootView: NiblessView {

  // MARK: - Properties
  let viewModel: DropoffLocationPickerViewModel
  let disposeBag = DisposeBag()

  var searchResults = BehaviorSubject<[NamedLocation]>(value: [])

  let tableView: UITableView = {
    let tableView = UITableView(frame: .zero, style: .plain)
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: CellIdentifier.cell.rawValue)
    tableView.insetsContentViewsToSafeArea = true
    tableView.contentInsetAdjustmentBehavior = .automatic
    return tableView
  }()

  // MARK: - Methods
  init(frame: CGRect = .zero,
       viewModel: DropoffLocationPickerViewModel) {
    self.viewModel = viewModel

    super.init(frame: frame)

    addSubview(tableView)
    tableView.dataSource = self
    tableView.delegate = self

    viewModel.searchResults
      .asDriver(onErrorRecover: { _ in fatalError("Encountered unexpected view model search results observable error.") })
      .drive(searchResults)
      .disposed(by: disposeBag)

    searchResults
      .asDriver(onErrorRecover: { _ in fatalError("Encountered unexpected search results observable error.") })
      .drive(onNext: { [weak self] _ in self?.tableView.reloadData() })
      .disposed(by: disposeBag)
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    tableView.frame = bounds
  }
}

extension DropoffLocationPickerContentRootView: UITableViewDataSource {

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    do {
      return try searchResults.value().count
    } catch {
      fatalError("Error reading value from search results subject.")
    }
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    do {
      let cell = tableView.dequeueReusableCell(withIdentifier: CellIdentifier.cell.rawValue)
      cell?.textLabel?.text = try searchResults.value()[indexPath.row].name
      return cell!
    } catch {
      fatalError("Error reading value from search results subject.")
    }
  }
}

extension DropoffLocationPickerContentRootView: UITableViewDelegate {
  
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    do {
      let selectedLocation = try searchResults.value()[indexPath.row]
      viewModel.select(dropoffLocation: selectedLocation)
    } catch {
      fatalError("Error reading value from search results subject.")
    }
  }
}
