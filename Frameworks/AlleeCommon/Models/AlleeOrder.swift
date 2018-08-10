//
//  AlleeOrder.swift
//  KDS_IOS
//
//  Created by Rodrigo Busata on 20/07/18.
//  Copyright © 2018 Bematech. All rights reserved.
//

import Foundation
import BSocketHelper

@objc open class AlleeOrder: NSObject, Codable {
    
    @objc open var id: String?
    @objc open var posTerminal: Int = 0
    @objc open var guestTable: String?
    @objc open var serverName: String?
    @objc open var destination: String?
    @objc open var userInfo: String?
    @objc open var phone: String?
    @objc open var orderMessages: [String]?
    
    @objc open var transType: AlleeTransType = .insert
    
    var orderType: OrderType = .regular
    
    @objc open var items: [AlleeItem]?
    @objc open var customer: AlleeCustomer?
    
    
    public override init() {
    }
    
    
    @objc open func set(orderType: AlleeOrderType) {
        switch orderType {
        case .regular:
            self.orderType = .regular
            
        case .rush:
            self.orderType = .rush
            
        case .fire:
            self.orderType = .fire
        }
    }
    
    
    @objc public enum AlleeOrderType: Int {
        case regular, rush, fire
    }
    
    
    func toJson() -> String? {
        return JsonUtil<AlleeOrder>.toJson(self)
    }
    
    
    static func from(json: String) -> AlleeOrder? {
        return JsonUtil<AlleeOrder>.from(json: json)
    }
    
    
    enum OrderType: String, Codable {
        case regular = "REGULAR"
        case rush = "RUSH"
        case fire = "FIRE"
    }
}
