//
//  ViewController.swift
//  CurrencyConverter
//
//  Created by d.sargin on 01/07/2018.
//  Copyright © 2018 d.sargin. All rights reserved.
//

import UIKit
import SnapKit
import Reachability
import PureLayout

private extension String {
    static let currencyCellReuseId = String(describing: CurrencyRateCell.self)
}

final class CurrencyRatesViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, CurrencyRateCellDelegate {

    // Dependencies
    private let dataManager = CurrencyRatesDataManager()
    private let reachability = Reachability()

    // Model
    private var baseAmount: Double?

    // UI
    private lazy var tableView: UITableView = {
        let tableView = TPKeyboardAvoidingTableView(frame: .zero, style: .plain)
        tableView.backgroundColor = .white
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = 71
        tableView.estimatedRowHeight = 0
        tableView.estimatedSectionHeaderHeight = 0
        tableView.estimatedSectionFooterHeight = 0
        tableView.separatorStyle = .none
        let cellNib = UINib(nibName: .currencyCellReuseId, bundle: Bundle.main)
        tableView.register(cellNib, forCellReuseIdentifier: .currencyCellReuseId)
        return tableView
    }()

    // MARK: - Life cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        startUpdatingDataSource()
    }

    // MARK: - Private API

    private func startUpdatingDataSource() {
        do {
            try reachability?.startNotifier()
        } catch {
            showAlert(text: "Failed to start connection notifier")
        }
        reachability?.whenReachable = { [weak self] _ in
            self?.dataManager.startUpdatingDataSource { [weak self] result in
                DispatchQueue.main.async {
                    guard let `self` = self else { return }
                    switch result {
                    case .success(let indexPathsDiff):
                        self.updateTableView(indexPathsDiff: indexPathsDiff)
                    case .fail(let error):
                        self.showAlert(error: error)
                    }
                }
            }
        }
        reachability?.whenUnreachable = { [weak self] _ in
            self?.dataManager.stopUpdatingDataSource()
        }

    }

    private func updateTableView(newRatesCurrencyCodes: [String]) {
        let currencyCodesDiff = dataManager.calculateCurrencyCodesDiff(oldRatesCurrencyCodes: dataManager.positionsArray.value, newRatesCurrencyCodes: newRatesCurrencyCodes)
        let indexPathsDiff = dataManager.updatePositionsArray(newRatesCurrencyCodes: newRatesCurrencyCodes, currencyCodesDiff: currencyCodesDiff)
        updateTableView(indexPathsDiff: indexPathsDiff)
    }

    private func updateTableView(indexPathsDiff: IndexPathsDiff) {
        if indexPathsDiff.toDelete.count == 0, indexPathsDiff.toInsert.count == 0 {
            reconfigureVisibleCells(indexes: indexPathsDiff.toUpdate)
        } else {
            tableView.beginUpdates()
            tableView.deleteRows(at: indexPathsDiff.toDelete, with: .fade)
            tableView.reloadRows(at: indexPathsDiff.toUpdate, with: .none)
            tableView.insertRows(at: indexPathsDiff.toInsert, with: .fade)
            tableView.endUpdates()
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
        guard let cell = tableView.dequeueReusableCell(withIdentifier: .currencyCellReuseId, for: indexPath) as? CurrencyRateCell else {
            return UITableViewCell()
        }
        cell.delegate = self
        return cell
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataManager.rates.value.count
    }

    // MARK: - UITableViewDelegate

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        configureCell(cell: cell, indexPath: indexPath)
    }

    private func configureCell(cell: UITableViewCell, indexPath: IndexPath) {
        guard let cell = cell as? CurrencyRateCell,
            dataManager.positionsArray.value.count > indexPath.row,
            !cell.amountTextField.isEditing else {
                return
        }
        let currencyCode = dataManager.positionsArray.value[indexPath.row]
        if let cellViewModelIndex = dataManager.rates.value.index(where: {
            $0.currencyCode == currencyCode
        }) {
            let cellRateInfo = dataManager.rates.value[cellViewModelIndex]
            let cellViewModel = dataManager.createCellViewModel(baseAmount: baseAmount, rateInfo: cellRateInfo)
            cell.configure(with: cellViewModel)
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
        baseAmount = cell.model?.amount
        if let indexToMove = dataManager.positionsArray.value.index(of: currentBaseCurrency) {
            dataManager.positionsArray.mutate {
                $0.insert($0.remove(at: indexToMove), at: 0)
            }
        }
    }

    // MARK: - CurrencyRateCellDelegate

    func currencyRateCellDidBeginEditing(_ currencyRateCell: CurrencyRateCell) {
        let topIndexPath = IndexPath(row: 0, section: 0)
        guard let currentIndexPath = tableView.indexPath(for: currencyRateCell) else { return }
        guard currentIndexPath.row != topIndexPath.row else { return }
        let currentBaseCurrency = currencyRateCell.currencyCodeLabel.text ?? ""
        dataManager.baseCurrency.mutate {
            $0 = currentBaseCurrency
        }
        baseAmount = currencyRateCell.model?.amount
        dataManager.positionsArray.mutate {
            $0.insert($0.remove(at: currentIndexPath.row), at: 0)
        }
        tableView.beginUpdates()
        tableView.moveRow(at: currentIndexPath, to: topIndexPath)
        tableView.endUpdates()
        tableView.scrollRectToVisible(.zero, animated: true)
    }

    func currencyRateCellDidChange(_ currencyRateCell: CurrencyRateCell) {
        guard let model = currencyRateCell.model,
            model.currencyCode == dataManager.baseCurrency.value else { return }
        baseAmount = model.amount
        updateTableView(newRatesCurrencyCodes: dataManager.positionsArray.value)
    }

}
