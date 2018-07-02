//
//  SessionFactory.swift
//  CurrencyConverter
//
//  Created by d.sargin on 02/07/2018.
//  Copyright © 2018 d.sargin. All rights reserved.
//

import Foundation

protocol IURLSessionFactory {

    func createURLSession(delegate: URLSessionDelegate) -> URLSession
    func sharedURLSession() -> URLSession
}

final class URLSessionFactory: IURLSessionFactory {

    func createURLSession(delegate: URLSessionDelegate) -> URLSession {
        let session = URLSession(configuration: createURLSessionConfiguration(), delegate: delegate, delegateQueue: nil)
        return session
    }

    func sharedURLSession() -> URLSession {
        return URLSession.shared
    }

    private func createURLSessionConfiguration() -> URLSessionConfiguration {
        return URLSessionConfiguration.default
    }

}
