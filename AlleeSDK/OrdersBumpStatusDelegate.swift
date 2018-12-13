//
//  OrdersBumpStatusDelegate.swift
//  AlleeSDK
//
//  Created by Rodrigo Busata on 12/12/18.
//  Copyright © 2018 Bematech. All rights reserved.
//

import Foundation

@objc public protocol OrdersBumpStatusDelegate {
    
    func updated(ordersBumpStatus: [AlleeOrderBumpStatus])
}
