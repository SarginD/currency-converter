//
//  RequestManagerMock.swift
//  CurrencyConverterTests
//
//  Created by d.sargin on 12/07/2018.
//  Copyright © 2018 d.sargin. All rights reserved.
//

import Foundation
import SwiftyJSON
@testable import CurrencyConverter

enum RequestManagerMockError: Error {
    case resourceNameIsNil
    case failedToParseData
    case parsingError
}

final class RequestManagerMock: IRequestManager {

    var resourceName: String?

    func execute(_ request: IRequest, parser: IResultParser?, completion: ((Any?, Error?) -> Void)?) -> URLSessionDataTask? {
        guard let resourceName = resourceName, let data = loadJson(name: resourceName) else {
            completion?(nil, RequestManagerMockError.resourceNameIsNil)
            return nil
        }
        var resultError: NSError?
        var result: Any? = data
        var json: Any?
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
        completion?(result, resultError)
        return nil
    }

    func load<Request, Model>(_ request: Request, completion: @escaping (Result<Model>) -> Void) -> URLSessionDataTask? where Request : ModelRequest, Model == Request.Model {
        return execute(request, parser: nil) { (data, error) in
            if let error = error {
                completion(.fail(error))
                return
            }
            guard let data = data else {
                completion(.fail(RequestManagerMockError.failedToParseData))
                return
            }
            if let result = Model.from(JSON(data)) {
                completion(.success(result))
            } else {
                completion(.fail(RequestManagerMockError.parsingError))
            }
        }
    }

    private func loadJson(name: String) -> Data? {
        guard let path = Bundle(for: type(of: self)).path(forResource: name, ofType: "json") else { return nil }
        let data = try? Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
        return data
    }

}
