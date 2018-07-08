//
//  Websync.swift
//
//  Created by Chola on 07/11/14.
//  Copyright (c) 2018 Chola. All rights reserved.
//

public typealias CompletionBlock = (Codable?, NSError?) -> ()

var websynch_baseUrl = ""

let nTimeout = 60.0

import UIKit

public class Websync: NSObject {
    
    var completionBlock : CompletionBlock!
    
    
    public func post<T : Encodable, R : Codable>(postBody: T, methodName: String, expected: R.Type, header: Dictionary<String, String>? = nil,  cache: Bool? = false, completionHandler: @escaping CompletionBlock) {
        
        let jsonData = try! JSONEncoder().encode(postBody)
            
        completionBlock = completionHandler
        
        sync_session(jsonData: jsonData, methodName: methodName, expected: expected, method: "POST", header: header)
            
       
    }
    
    public func put<T : Encodable, R : Codable>(postBody: T, methodName: String, expected: R.Type, header: Dictionary<String, String>? = nil,  cache: Bool? = false, completionHandler: @escaping CompletionBlock) {
        
        let jsonData = try! JSONEncoder().encode(postBody)
        
        completionBlock = completionHandler
        
        sync_session(jsonData: jsonData, methodName: methodName, expected: expected, method: "PUT", header: header)
        
        
    }
    
    public func get<R : Codable>(methodName: String, expected: R.Type, header: Dictionary<String, String>? = nil,  cache: Bool? = false, completionHandler: @escaping CompletionBlock) {
        
        completionBlock = completionHandler
        
        sync_session(jsonData: (nil as Data?)!, methodName: methodName, expected: expected, method: "GET", header: header)
        
        
    }
    

    private func request_param(jsonData: Data, methodName: String, method: String, header: Dictionary<String, String>? = nil) -> URLRequest {
        var request = URLRequest(url: URL(string: "\(websynch_baseUrl)\(methodName)")!)
        request.httpMethod = method
        
        if method != "GET" {
            request.httpBody = jsonData
        }
        
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        header?.forEach {
            request.addValue($0.key, forHTTPHeaderField: $0.value)
        }
        
        print("\(websynch_baseUrl)\(methodName)")
        
        return request
    }
    
    private func sync_session<R : Codable>(jsonData: Data, methodName: String, expected: R.Type, method: String, header: Dictionary<String, String>? = nil) {
        
        let request: URLRequest = request_param(jsonData: jsonData, methodName: methodName, method: method)
        
        let session = URLSession.shared
        let task = session.dataTask(with: request, completionHandler: { data, response, error -> Void in
            
            DispatchQueue.main.async {
                
                if data != nil {
                    
                    let userResponse = try! JSONDecoder().decode(expected, from: data!)
                    self.completionBlock(userResponse, nil)
                    
                    
                } else {
                    self.completionBlock(nil, error as NSError?)
                }
                
            }
            
        })
        
        task.resume()
    }
    
}

