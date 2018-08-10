//
//  SocketSendOrder.swift
//  KDS_IOS
//
//  Created by Rodrigo Busata on 20/07/18.
//  Copyright © 2018 Bematech. All rights reserved.
//

import Foundation
import BSocketHelper

class SocketSendOrder: BaseSocketMessage {
    
    var order: AlleeOrder?
    
    
    init(guid: String, order: AlleeOrder, deviceSerial: String) {
        super.init(guid: guid, type: TypeSocketMessage.sendOrder, originDeviceSerial: deviceSerial)
        self.order = order
    }
    
    
    private enum CodingKeys: String, CodingKey {
        case order
    }
    
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.order = try container.decode(AlleeOrder.self, forKey: .order)
        try super.init(from: decoder)
    }
    
    override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(order, forKey: .order)
        try super.encode(to: encoder)
    }
    
    
    override func toJson() -> String? {
        return JsonUtil<SocketSendOrder>.toJson(self)
    }
    
    
    static func from(json: String) -> SocketSendOrder? {
        return JsonUtil<SocketSendOrder>.from(json: json)
    }
}

extension TypeSocketMessage {
    
    static var sendOrder: String {
        get {
            return "SEND_ORDER"
        }
    }
}
