//
//  AlleeTransType.swift
//  KDS_IOS
//
//  Created by Rodrigo Busata on 25/07/18.
//  Copyright © 2018 Bematech. All rights reserved.
//

import Foundation

@objc public enum AlleeTransType: Int, Codable {
    case insert = 1
    case delete = 2
    case update = 3
    case transfer = 4
    case askStation = 5
    case replace = 6
}
