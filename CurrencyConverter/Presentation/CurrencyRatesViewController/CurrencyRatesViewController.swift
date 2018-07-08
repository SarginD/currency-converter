//
//  ViewController.swift
//  CurrencyConverter
//
//  Created by d.sargin on 01/07/2018.
//  Copyright © 2018 d.sargin. All rights reserved.
//

import UIKit
import SnapKit
import PureLayout

final class CurrencyRatesViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, CurrencyRateCellDelegate {

    // Dependencies
    private let dataManager = CurrencyRatesDataManager()
    private let currencyRatesService: ICurrencyRatesService = Locator.shared.currencyRatesService()

    // Model
    struct ViewModel {
        var amount: Double?
        var rate: Rate
    }

    var positionsArray = [String]()

    private var dataSource = [ViewModel]()
    private var baseAmount: ViewModel?

    // UI
    private lazy var currencyCellReuseId: String = {
        return String(describing: CurrencyRateCell.self)
    }()

    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.backgroundColor = .white
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = 71
        tableView.estimatedRowHeight = 0
        tableView.estimatedSectionHeaderHeight = 0
        tableView.estimatedSectionFooterHeight = 0
        tableView.separatorStyle = .none
        let cellNib = UINib(nibName: currencyCellReuseId, bundle: Bundle.main)
        tableView.register(cellNib, forCellReuseIdentifier: currencyCellReuseId)
        return tableView
    }()

    // MARK: - Life cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadDataSource()
    }

    var isFirstUpdate = true

    private func loadDataSource() {
        dataManager.startUpdatingDataSource { [weak self] result in
            DispatchQueue.main.async {
                guard let `self` = self else { return }
                switch result {
                case .success(let result):
                    if self.dataManager.baseCurrency.value != result.baseCurrencyCode {
                        print("updateFailed")
                        return
                    }
                    let newRatesCurrencyCodes = [result.baseCurrencyCode] + result.rates.map { $0.currencyCode }
                    let diff = self.dataManager.calculateDiff(oldRatesCurrencyCodes: self.positionsArray, newRatesCurrencyCodes: newRatesCurrencyCodes)
                    let baseRate = Rate(currencyCode: result.baseCurrencyCode, baseCurrencyCode: result.baseCurrencyCode, rate: 1)
                    self.updateDataSource(newDataSource: [ViewModel(amount: nil, rate: baseRate)] + result.rates.map { ViewModel(amount: nil, rate: $0) }, diff: diff)
                    self.updateTableView(newRatesCurrencyCodes: newRatesCurrencyCodes)
                case .fail(let error):
                    print(error)
                }
            }
        }
    }

    private func updateDataSource(newDataSource: [ViewModel], diff: (toUpdate: [String], toDelete: [String], toInsert: [String])) {

        diff.toDelete.forEach { currencyCodeToDelete in
            if let indexToDelete = dataSource.index(where: { $0.rate.currencyCode == currencyCodeToDelete }) {
                dataSource.remove(at: indexToDelete)
            }
        }
        diff.toInsert.forEach { currencyCodeToInsert in
            if let indexOfItemToInsert = newDataSource.index(where: { $0.rate.currencyCode == currencyCodeToInsert }) {
                let newItem = newDataSource[indexOfItemToInsert]
                dataSource.append(newItem)
            }
        }
        diff.toUpdate.forEach { currencyCodeToUpdate in
            guard currencyCodeToUpdate != baseAmount?.rate.baseCurrencyCode else {
                return
            }
            if let indexOfNewItem = newDataSource.index(where: { $0.rate.currencyCode == currencyCodeToUpdate }),
                let indexOfOldItem = dataSource.index(where: { $0.rate.currencyCode == currencyCodeToUpdate }) {
                let newItem = newDataSource[indexOfNewItem]
                var oldItem = dataSource[indexOfOldItem]
                if let baseAmount = baseAmount, let amount = baseAmount.amount {
                    oldItem.amount = amount * newItem.rate.rate
                }
                oldItem.rate = newItem.rate
                dataSource.remove(at: indexOfOldItem)
                dataSource.insert(oldItem, at: indexOfOldItem)
            }
        }
    }

    private func updateTableView(newRatesCurrencyCodes: [String]) {
        let diff = self.dataManager.calculateDiff(oldRatesCurrencyCodes: self.positionsArray, newRatesCurrencyCodes: newRatesCurrencyCodes)

        var indexesToDelete = [IndexPath]()
        diff.toDelete.forEach {
            if let index = positionsArray.index(of: $0) {
                positionsArray.remove(at: index)
                indexesToDelete.append(IndexPath(row: index, section: 0))
            }
        }

        if newRatesCurrencyCodes.count == diff.toInsert.count {
            positionsArray = newRatesCurrencyCodes
        } else {
            positionsArray += diff.toInsert
        }
        var indexesToInsert = [IndexPath]()
        diff.toInsert.forEach {
            if let index = positionsArray.index(of: $0) {
                indexesToInsert.append(IndexPath(row: index, section: 0))
            }
        }

        var indexesToUpdate = [IndexPath]()
        diff.toUpdate.forEach {
            if let index = positionsArray.index(of: $0), index != 0 {
                indexesToUpdate.append(IndexPath(row: index, section: 0))
            }
        }

        if indexesToDelete.count == 0, indexesToInsert.count == 0 {
            reconfigureVisibleCells(indexes: indexesToUpdate)
        } else if !tableView.hasUncommittedUpdates {
            tableView.beginUpdates()
            tableView.deleteRows(at: indexesToDelete, with: .fade)
            tableView.reloadRows(at: indexesToUpdate, with: .none)
            tableView.insertRows(at: indexesToInsert, with: .fade)
            tableView.endUpdates()
        } else {
            print("has uncommited updates")
        }
    }

    private func reconfigureVisibleCells(indexes: [IndexPath]) {
        tableView.indexPathsForVisibleRows?.forEach { [weak self] visibleRowIndex in
            guard indexes.contains(visibleRowIndex) else { return }
            guard let `self` = self else { return }
            guard let cell = self.tableView.cellForRow(at: visibleRowIndex) else { return }
            self.configureCell(cell: cell, indexPath: visibleRowIndex)
        }
    }

    // MARK: - SetupUI

    private func setupUI() {
        view.backgroundColor = .white
        view.addSubview(tableView)
        tableView.snp.makeConstraints {
            $0.left.right.bottom.equalToSuperview()
        }
        tableView.autoPin(toTopLayoutGuideOf: self, withInset: 0)
    }

    // MARK: - UITableViewDataSource

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: currencyCellReuseId, for: indexPath) as? CurrencyRateCell else {
            return UITableViewCell()
        }
        cell.delegate = self
        return cell
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }

    // MARK: - UITableViewDelegate

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        configureCell(cell: cell, indexPath: indexPath)
    }

    private func configureCell(cell: UITableViewCell, indexPath: IndexPath) {
        guard let cell = cell as? CurrencyRateCell,
            positionsArray.count > indexPath.row,
            !cell.amountTextField.isEditing else {
                return
        }
        let currencyCode = positionsArray[indexPath.row]
        if let cellViewModelIndex = dataSource.index(where: {
            $0.rate.currencyCode == currencyCode
        }) {
            let cellViewModel = dataSource[cellViewModelIndex]
            let flag = currencyRatesService.currencyFlagImage(currencyCode: cellViewModel.rate.currencyCode)
            let name = currencyRatesService.currencyRateName(currencyCode: cellViewModel.rate.currencyCode)
            var amount: Double?
            if let baseAmount = baseAmount, let baseAmountValue = baseAmount.amount {
                amount = baseAmountValue * cellViewModel.rate.rate
            }
            let model = CurrencyRateCell.ViewModel(currencyCode: cellViewModel.rate.currencyCode, currencyName: name, currencyFlag: flag, amount: amount, rate: cellViewModel.rate)
            cell.configure(with: model)
        }

        cell.delegate = self
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) as? CurrencyRateCell else { return }
        if cell.amountTextField.isEditing {
            cell.amountTextField.resignFirstResponder()
        } else {
            cell.amountTextField.becomeFirstResponder()
        }
        let currentBaseCurrency = cell.currencyCodeLabel.text ?? ""
        dataManager.baseCurrency.mutate {
            $0 = currentBaseCurrency
        }
        baseAmount?.rate.baseCurrencyCode = currentBaseCurrency
        baseAmount?.amount = cell.model?.amount
        if let indexToMove = positionsArray.index(of: currentBaseCurrency) {
            positionsArray.remove(at: indexToMove)
            positionsArray.insert(currentBaseCurrency, at: 0)
        }
    }

    // MARK: - CurrencyRateCellDelegate

    func currencyRateCellDidBeginEditing(_ currencyRateCell: CurrencyRateCell) {
        let topIndexPath = IndexPath(row: 0, section: 0)
        guard let currentIndexPath = tableView.indexPath(for: currencyRateCell) else { return }
        guard currentIndexPath.row != topIndexPath.row else { return }
        tableView.beginUpdates()
        let currentBaseCurrency = currencyRateCell.currencyCodeLabel.text ?? ""
        dataManager.baseCurrency.mutate {
            $0 = currentBaseCurrency
        }
        baseAmount?.rate.baseCurrencyCode = currentBaseCurrency
        baseAmount?.amount = currencyRateCell.model?.amount
        positionsArray.remove(at: currentIndexPath.row)
        positionsArray.insert(currentBaseCurrency, at: 0)
        tableView.moveRow(at: currentIndexPath, to: topIndexPath)
        tableView.scrollToRow(at: topIndexPath, at: .top, animated: true)
        tableView.endUpdates()
    }

    func currencyRateCellDidChange(_ currencyRateCell: CurrencyRateCell) {
        guard let model = currencyRateCell.model,
            model.rate.currencyCode == dataManager.baseCurrency.value else { return }
        baseAmount = ViewModel(amount: model.amount, rate: model.rate)
        baseAmount?.rate.baseCurrencyCode = model.currencyCode
        updateTableView(newRatesCurrencyCodes: positionsArray)
    }

}
