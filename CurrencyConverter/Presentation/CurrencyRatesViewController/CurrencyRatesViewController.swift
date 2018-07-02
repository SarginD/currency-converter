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
    private var dataSource: CurrencyRates? {
        didSet {
            UIView.performWithoutAnimation {
                tableView.reloadData()
            }
        }
    }

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
        tableView.estimatedRowHeight = 71
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

    private func loadDataSource() {
        dataManager.startUpdatingDataSource { [weak self] result in
            DispatchQueue.main.async {
                guard let `self` = self else { return }
                switch result {
                case .success(let result):
                    self.dataSource = result
                case .fail(let error):
                    print(error)
                }
            }
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
        return dataSource?.rates.keys.count ?? 0
    }

    // MARK: - UITableViewDelegate

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let cell = cell as? CurrencyRateCell,
            let dataSource = dataSource else {
            return
        }
        let currencyCodes = dataSource.rates.map { $0.key }
        let flag = currencyRatesService.currencyFlagImage(currencyCode: currencyCodes[indexPath.row])
        let name = currencyRatesService.currencyRateName(currencyCode: currencyCodes[indexPath.row])
        let model = CurrencyRateCell.ViewModel(currencyCode: currencyCodes[indexPath.row], currencyName: name, currencyFlag: flag)
        cell.configure(with: model)
        cell.delegate = self
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) as? CurrencyRateCell else { return }
        if cell.amountTextField.isEditing {
            cell.amountTextField.resignFirstResponder()
        } else {
            cell.amountTextField.becomeFirstResponder()
        }
    }

    // MARK: - UITextFieldDelegate

    func currencyRateCellDidBeginEditing(_ currencyRateCell: CurrencyRateCell) {
        let topIndexPath = IndexPath(row: 0, section: 0)
        guard let currentIndexPath = tableView.indexPath(for: currencyRateCell) else { return }
        guard currentIndexPath.row != topIndexPath.row else { return }
        tableView.moveRow(at: currentIndexPath, to: topIndexPath)
        tableView.scrollToRow(at: topIndexPath, at: .top, animated: true)
    }

}
