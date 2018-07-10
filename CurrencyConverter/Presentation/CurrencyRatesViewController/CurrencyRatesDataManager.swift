//
//  CurrencyRatesDataManager.swift
//  CurrencyConverter
//
//  Created by d.sargin on 02/07/2018.
//  Copyright © 2018 d.sargin. All rights reserved.
//

import Foundation

private extension String {
    static let defaultBaseCurrency: String = "USD"
}

private extension Int {
    static let updateIntervalSeconds: Int = 1
    static let updateLeewayMilliseconds: Int = 100
}

final class CurrencyRatesDataManager {

    // Model
    var baseCurrency = ThreadSafeValueWrapper(String.defaultBaseCurrency)
    var rates = ThreadSafeValueWrapper([RateInfo]())
    var positionsArray = ThreadSafeValueWrapper([String]())

    // Dependencies
    private let currencyRatesService: ICurrencyRatesService = Locator.shared.currencyRatesService()

    // MARK: Public API

    var workItems: [DispatchWorkItem] = []
    var timer: DispatchSourceTimer?

    func startUpdatingDataSource(onUpdate: @escaping (Result<(toUpdate: [IndexPath], toDelete: [IndexPath], toInsert: [IndexPath])>) -> Void) {

        let queue = DispatchQueue(label: "customSerialQueue")
        timer?.cancel()
        timer = DispatchSource.makeTimerSource(queue: queue)
        timer?.schedule(deadline: .now(),
                        repeating: .seconds(.updateIntervalSeconds),
                        leeway: .milliseconds(.updateLeewayMilliseconds))

        func createWorkItem() -> DispatchWorkItem {
            return DispatchWorkItem { [weak self] in
                guard let `self` = self else { return }
                self.currencyRatesService.loadCurrencyRates(baseCurrency: self.baseCurrency.value) { [weak self] result in
                    guard let `self` = self else { return }
                    self.workItems.removeAll()

                    switch result {
                    case .success(let result):
                        guard self.baseCurrency.value == result.baseCurrencyCode else { return }
                        let baseRateInfo = RateInfo(currencyCode: result.baseCurrencyCode, baseCurrencyCode: result.baseCurrencyCode, rate: 1)
                        let newRateInfos = [baseRateInfo] + result.rates
                        let indexPathsDiff = self.updateDataSource(newDataSource: newRateInfos)
                        onUpdate(Result.success(indexPathsDiff))
                    case .fail(let error):
                        onUpdate(.fail(error))
                    }

                    print("update")
                }
            }
        }

        timer?.setEventHandler { [weak self] in
            guard let `self` = self else { return }
            if self.workItems.count > 0 { return }
            let workItem = createWorkItem()
            self.workItems.append(workItem)
            queue.async(execute: workItem)
        }

        timer?.resume()
    }

    func createCellViewModel(baseAmount: Double?, rateInfo: RateInfo) -> CurrencyRateCell.ViewModel {
        let flag = currencyRatesService.currencyFlagImage(currencyCode: rateInfo.currencyCode)
        let name = currencyRatesService.currencyRateName(currencyCode: rateInfo.currencyCode)
        var amount: Double?
        if let baseAmount = baseAmount {
            amount = baseAmount * rateInfo.rate
        }
        return CurrencyRateCell.ViewModel(currencyCode: rateInfo.currencyCode, currencyName: name, currencyFlag: flag, amount: amount)
    }

    // MARK: - Private API

    private func stopUpdatingDataSource() {
        timer?.cancel()
        timer = nil
    }

    deinit {
        stopUpdatingDataSource()
    }

}
