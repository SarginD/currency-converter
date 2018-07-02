//
//  Locator.swift
//  CurrencyConverter
//
//  Created by d.sargin on 02/07/2018.
//  Copyright © 2018 d.sargin. All rights reserved.
//

import Foundation

final class Locator {

    static let shared = Locator()

    // MARK: - Instance storage

    @objc public var registry = [String: Any]()

    public func register<T>(key: T.Type, instance: T) {
        self.registry["\(T.self)"] = instance
    }

    public func get<T>(_: T.Type) -> T? {
        return registry["\(T.self)"] as? T
    }

    public func instance<T>(forKey key: T.Type, factory: @escaping () -> T) -> T {
        if let instance = get(key) {
            return instance
        } else {
            let instance = factory()
            register(key: key, instance: instance)
            return instance
        }
    }

    // MARK: - Services and factories

    func requestManager() -> IRequestManager {
        return instance(forKey: RequestManager.self) {
            return RequestManager(requestConstructor: Locator.shared.requestConstructor(),
                                  sessionFactory: Locator.shared.urlSessionFactory())
        }
    }

    func requestConstructor() -> IRequestConstructor {
        return RequestConstructor()
    }

    func urlSessionFactory() -> IURLSessionFactory {
        return URLSessionFactory()
    }

    func currencyRatesService() -> ICurrencyRatesService {
        return CurrencyRatesService(requestManager: Locator.shared.requestManager())
    }
}
