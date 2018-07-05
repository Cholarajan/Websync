//
//  ViewController.swift
//  Websync
//
//  Created by cholaitnj@gmail.com on 07/05/2018.
//  Copyright (c) 2018 cholaitnj@gmail.com. All rights reserved.
//

import UIKit

struct pLogin: Codable {
    var userName: String
    var password: String
}

struct rLogin: Codable {
    var success: Bool
    var access_token: String
}

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // Encode
        let user = pLogin(userName: "raj@xyz.com", password: "raj123456")
        
        CRRest().post(postBody: user, methodName: "users", expected: rLogin.self) { response, error in
            
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

