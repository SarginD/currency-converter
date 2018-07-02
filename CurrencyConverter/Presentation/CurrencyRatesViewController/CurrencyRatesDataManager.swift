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

final class CurrencyRatesDataManager {

    // Dependencies
    private let currencyRatesService: ICurrencyRatesService = Locator.shared.currencyRatesService()

    func loadDataSource(completion: @escaping (Result<CurrencyRates>) -> Void) {
        currencyRatesService.loadCurrencyRates(baseCurrensy: "USD", completion: completion)
    }
    var workItems: [DispatchWorkItem] = []

    var timer: DispatchSourceTimer?

    func startUpdatingDataSource(onUpdate: @escaping (Result<CurrencyRates>) -> Void) {

        let queue = DispatchQueue(label: "customSerialQueue")

        timer?.cancel()

        timer = DispatchSource.makeTimerSource(queue: queue)

        timer?.schedule(deadline: .now(), repeating: .seconds(1), leeway: .milliseconds(100))

        let workItem = DispatchWorkItem { [weak self] in
            self?.currencyRatesService.loadCurrencyRates(baseCurrensy: "USD") { result in
                self?.workItems.removeAll()
                onUpdate(result)
                print("update")
            }
        }

        timer?.setEventHandler { [weak self] in
            guard let `self` = self else { return }
            if self.workItems.count > 0 { return }
            self.workItems.append(workItem)
            queue.async(execute: workItem)
        }

        timer?.resume()
    }

    private func stopUpdatingDataSource() {
        timer?.cancel()
        timer = nil
    }

    deinit {
        stopUpdatingDataSource()
    }

}
