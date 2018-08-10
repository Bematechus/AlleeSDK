//
//  AlleeCustomer.swift
//  KDS_IOS
//
//  Created by Rodrigo Busata on 31/07/18.
//  Copyright © 2018 Bematech. All rights reserved.
//

import Foundation
import BSocketHelper

@objc open class AlleeCustomer: NSObject, Codable {
    
    @objc open var id: String?
    @objc open var name: String?
    @objc open var phone: String?
    @objc open var phone2: String?
    @objc open var address: String?
    @objc open var address2: String?
    @objc open var city: String?
    @objc open var state: String?
    @objc open var zip: String?
    @objc open var country: String?
    @objc open var email: String?
    @objc open var webmail: String?

    
    @objc open var transType: AlleeTransType = .insert
    
    
    public override init() {
    }
    
    
    func toJson() -> String? {
        return JsonUtil<AlleeCustomer>.toJson(self)
    }
    
    
    static func from(json: String) -> AlleeCustomer? {
        return JsonUtil<AlleeCustomer>.from(json: json)
    }
}
