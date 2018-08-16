//
//  AlleeSDK.swift
//  AlleeSDK
//
//  Created by Rodrigo Busata on 25/07/18.
//  Copyright © 2018 Bematech. All rights reserved.
//

import Foundation
import BSocketHelper


@objc open class AlleeSDK: NSObject, BSocketHelperDelegate {

    @objc static open let shared = AlleeSDK()
    
    private let deviceSerial = UIDevice.current.identifierForVendor!.uuidString
    private let appId = "com.bematech.allee"
    
    private let getDataTimeout: UInt32 = 15
    private let maxAttempts = 5
    private var currentSend: [CurrentSend] = []
    
    
    @objc open func start(withStoreKey storeKey: String, andPort port: Int=1111, env:Environment=Environment.prod) {
        BSocketHelper.shared.start(onPort: port,
                                   withDeviceSerial: self.deviceSerial,
                                   andDeviceHostOrder: nil,
                                   andStoreKey: storeKey,
                                   andAppVersion: nil,
                                   andAppId: self.appId + (env == .stage ? "-Stage" : env == .dev ? "-Dev" : ""),
                                   andDeviceType: .pos,
                                   andSocketHelperDelegate: self)
    }
    
    
    @objc open func send(order: AlleeOrder, callback: @escaping (_ error: String?)->Void) {
        DispatchQueue.global(qos: .background).async {
            self.send(order: order, callback: callback, attempts: 0)
        }
    }
    
    
    private func send(order: AlleeOrder, callback: @escaping (_ error: String?)->Void, attempts: Int) {
        let currentGuid = UUID().uuidString
        guard let device = self.getTargetDevice() else {
            DispatchQueue.main.async {
                callback("No Allees available")
            }
            return
        }
        
        guard let deviceSerial = device.serial else {
            DispatchQueue.main.async {
                callback("Invalid serial")
            }
            return
        }
        
        self.currentSend.append(CurrentSend(guid: currentGuid, deviceSerial: deviceSerial, callback: callback))
        
        guard let request = SocketSendOrder(guid: currentGuid, order: order,
                                            deviceSerial: self.deviceSerial).toJson() else {
                                                
                                                DispatchQueue.main.async {
                                                    callback("Failed to create request")
                                                }
                                                return
        }
        
        BSocketHelper.shared.send(msg: request, toDeviceSerial: deviceSerial) { (error) in
            if let error = error {
                if attempts > self.maxAttempts {
                    DispatchQueue.main.async {
                        callback(error)
                    }
                    
                } else {
                    sleep(1)
                    self.send(order: order, callback: callback, attempts: attempts + 1)
                }
            }
        }
        
        DispatchQueue.global(qos: .background).async {
            sleep(self.getDataTimeout)
            
            guard let currenSendIndex = self.currentSend.index(where: { (c2) -> Bool in
                return c2.guid == currentGuid
                
            }) else {
                return
            }
            
            let currentSend = self.currentSend.remove(at: currenSendIndex)
            
            BroadcastDiscovery.shared.manageLanDevicesQueue.sync {
                BroadcastDiscovery.shared.removeLanDevice(currentSend.deviceSerial)
            }
            
            DispatchQueue.main.async {
                callback("TIMEOUT on send to: \(currentSend.deviceSerial)")
            }
        }
    }
    
    
    public func received(message: String) {
        let socketMessage = BaseSocketMessage.fromBase(json: message)
        if let type = socketMessage?.type {
            
            switch type {
            case TypeSocketMessage.callback:
                guard let socketCallback = SocketCallback.from(json: message) else {
                    return
                }
                
                guard let currenSendIndex = self.currentSend.index(where: { (c2) -> Bool in
                    return c2.guid == socketMessage?.guid
                    
                }) else {
                    return
                }
                
                let currentSend = self.currentSend.remove(at: currenSendIndex)
                
                DispatchQueue.main.async {
                    currentSend.callback(socketCallback.error)
                }
                
            default: break
            }
        }
    }
    
    
    private func getTargetDevice() -> BroadcastDevice? {
        return BroadcastDiscovery.shared.allLanDevices().min { (d1, d2) -> Bool in
            return d1.hostOrder ?? 999 < d2.hostOrder ?? 999
        }
    }
    
    private struct CurrentSend: Equatable {
        
        var guid: String
        var deviceSerial: String
        var callback: (_ error: String?)->Void
        
        init(guid: String, deviceSerial: String, callback: @escaping (_ error: String?)->Void) {
            self.guid = guid
            self.deviceSerial = deviceSerial
            self.callback = callback
        }
        
        
        static func == (lhs: AlleeSDK.CurrentSend, rhs: AlleeSDK.CurrentSend) -> Bool {
            return lhs.guid == rhs.guid
        }
    }
    
    
    public func update(storeKey: String) {
        BroadcastDiscovery.shared.update(storeKey: storeKey)
    }
    
    
    public func update(port: Int) throws {
        try BSocketHelper.shared.update(port: port)
    }
    
    
    @objc public enum Environment: Int {
        case prod, stage, dev
    }
}
