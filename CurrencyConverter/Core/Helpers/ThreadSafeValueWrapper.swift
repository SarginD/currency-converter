//
//  ThreadSafeValueWrapper.swift
//  CurrencyConverter
//
//  Created by d.sargin on 03/07/2018.
//  Copyright © 2018 d.sargin. All rights reserved.
//

import Foundation

final class ThreadSafeValueWrapper<T> {
    private let queue = DispatchQueue(label: UUID().uuidString,
                                      attributes: .concurrent)

    private var _value: T
    init(_ value: T) {
        self._value = value
    }

    var value: T {
        return queue.sync { _value }
    }

    func mutate(_ transform: @escaping (inout T) -> Void) {
        queue.async(flags: .barrier) { [weak self] in
            guard let `self` = self else { return }
            transform(&self._value)
        }
    }
}
