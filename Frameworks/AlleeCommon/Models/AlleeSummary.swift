//
//  AlleeSummary.swift
//  KDS_IOS
//
//  Created by Rodrigo Busata on 16/08/18.
//  Copyright © 2018 Bematech. All rights reserved.
//

import Foundation

@objc open class AlleeSummary: NSObject, Codable {
    
    @objc open var ingredientName: String?
    @objc open var ingredientQuantity: Int = 1
    
    public override init() {
    }
}
