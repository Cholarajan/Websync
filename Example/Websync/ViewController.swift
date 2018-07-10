//
//  ViewController.swift
//  Websync
//
//  Created by cholaitnj@gmail.com on 07/05/2018.
//  Copyright (c) 2018 cholaitnj@gmail.com. All rights reserved.
//

import UIKit
import Websync

struct pLogin: Codable {
    var userName: String
    var password: String
}

extension KeyedDecodingContainer {
    func optionalkey<T>(_ key: K, _ defaultValue: T) throws -> T
        where T : Decodable {
            return try decodeIfPresent(T.self, forKey: key) ?? defaultValue
    }
}

class rLogin: Codable {
    var success: Bool
    var access_token: String
    
    // If not sure with keys (For missing keys).
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.success = try container.optionalkey(.success, false)
        self.access_token = try container.optionalkey(.access_token, "optional value")
    }
}


class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // Encode
        let user = pLogin(userName: "raj@xyz.com", password: "raj123456")
        
        // Simple call:::
        Websync().post(postBody: user, methodName: "users", expected: rLogin.self) { response, error in
            
            if response != nil {
                
                let userResponse = response as! rLogin
                print(userResponse.success)
                
            } else {
                
                // Error message here..
                
            }
            
        }
        
        
        // Api call with header, cache:::
        Websync().post(postBody: user, methodName: "users", expected: rLogin.self, header: ["auth":"12121"], cache: true) { response, error in
            
            if response != nil {
                
                let userResponse = response as! rLogin
                print(userResponse.success)
                
            } else {
                
                // Error message here..
                
            }
            
        }
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

