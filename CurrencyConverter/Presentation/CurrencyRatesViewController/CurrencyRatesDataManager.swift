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

        func createWorkItem() -> DispatchWorkItem? {
            weak var weakWorkItem: DispatchWorkItem?
            let workItem = DispatchWorkItem { [weak self] in
                guard let workItem = weakWorkItem, !workItem.isCancelled
                    else {
                        self?.workItems.removeAll()
                        return
                }
                guard let `self` = self else { return }
                self.currencyRatesService.loadCurrencyRates(baseCurrency: self.baseCurrency.value) { [weak self] result in
                    self?.workItems.removeAll()
                    guard let `self` = self, !workItem.isCancelled else {
                        return
                    }

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
            weakWorkItem = workItem
            return workItem
        }

        timer?.setEventHandler { [weak self] in
            guard let `self` = self,
                self.workItems.count == 0,
                let workItem = createWorkItem()
                else { return }

            self.workItems.append(workItem)
            queue.async(execute: workItem)
        }

        timer?.resume()
    }

    func stopUpdatingDataSource() {
        workItems.forEach { $0.cancel() }
        workItems.removeAll()
        timer?.cancel()
        timer = nil
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

    deinit {
        stopUpdatingDataSource()
    }

}
