//
//  RequestManager.swift
//  CurrencyConverter
//
//  Created by d.sargin on 01/07/2018.
//  Copyright © 2018 d.sargin. All rights reserved.
//

import Foundation
import SwiftyJSON

enum RequestErorr: Error {
    case invalidUrl
    case defaultNetworkError
    case parsingError
}

protocol IRequestManager {

    @discardableResult
    func execute(_ request: IRequest, parser: IResultParser?, completion: ((Any?, Error?) -> Void)?) -> URLSessionDataTask?

    @discardableResult
    func load<Request: ModelRequest, Model>(_ request: Request, completion: @escaping (Result<Model>) -> Void) -> URLSessionDataTask? where Model == Request.Model
}

final class RequestManager: NSObject, IRequestManager, URLSessionDelegate {

    var sessionDelegate: URLSessionDelegate?

    // Dependencies
    let requestConstructor: IRequestConstructor
    let sessionFactory: IURLSessionFactory

    @objc lazy var session: URLSession = {
        return sessionFactory.sharedURLSession()
    }()

    // MARK: - Initializers

    init(requestConstructor: IRequestConstructor, sessionFactory: IURLSessionFactory) {
        self.requestConstructor = requestConstructor
        self.sessionFactory = sessionFactory
    }

    // MARK: - IRequestManager

    func execute(_ request: IRequest, parser: IResultParser?, completion: ((Any?, Error?) -> Void)?) -> URLSessionDataTask? {
        guard let urlRequest = requestConstructor.constructURLRequest(from: request) else {
            completion?(nil, RequestErorr.invalidUrl)
            return nil
        }

        let dataTask = session.dataTask(with: urlRequest) { (data, response, error) in
            var resultError = error as NSError?
            var result: Any? = data
            var json: Any?
            if let data = data, resultError == nil {
                do {
                    json = try JSONSerialization.jsonObject(with: data, options: .allowFragments)
                    if let parser = parser, let json = json {
                        result = parser.parseResponse(json)
                    } else {
                        result = json
                    }
                } catch let error as NSError {
                    resultError = error
                }
            }
            completion?(result, resultError)
        }
        dataTask.resume()
        return dataTask
    }

    func load<Request: ModelRequest, Model>(_ request: Request, completion: @escaping (Result<Model>) -> Void) -> URLSessionDataTask? where Model == Request.Model {
        return execute(request, parser: nil) { (data, error) in
            if let error = error {
                completion(.fail(error))
                return
            }
            guard let data = data else {
                completion(.fail(RequestErorr.defaultNetworkError))
                return
            }
            if let result = Model.from(JSON(data)) {
                completion(.success(result))
            } else {
                completion(.fail(RequestErorr.parsingError))
            }
        }
    }

    // MARK: - URLSessionDelegate

    public func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge,
                           completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        sessionDelegate?.urlSession?(session, didReceive: challenge, completionHandler: completionHandler)
    }
}
