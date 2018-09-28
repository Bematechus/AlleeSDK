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

    @objc static public let shared = AlleeSDK()
    
    public typealias Callback = (_ error: String?)->Void
    
    private let deviceSerial = UIDevice.current.identifierForVendor!.uuidString
    private let appId = "com.bematech.allee"
    
    private let getDataTimeout: UInt32 = 15
    private let maxAttempts = 5
    private var currentSend: [CurrentSend] = []
    
    private var storeKey: String?
    
    @objc open func start(withStoreKey storeKey: String, andPort port: Int=1111, env:Environment=Environment.prod) {
        self.storeKey = storeKey
        
        BSocketHelper.shared.start(onPort: port,
                                   withDeviceSerial: self.deviceSerial,
                                   andDeviceHostOrder: nil,
                                   andStoreKey: storeKey,
                                   andAppVersion: nil,
                                   andAppId: self.appId + (env == .stage ? "-Stage" : env == .dev ? "-Dev" : ""),
                                   andDeviceType: .pos,
                                   andSocketHelperDelegate: self)
    }
    
    
    @objc open func send(order: AlleeOrder, callback: @escaping Callback) {
        DispatchQueue.global(qos: .background).async {
            self.send(order: order, orderXML: nil, callback: callback, attempts: 0)
        }
    }
    
    
    @objc open func send(orderXML: String, callback: @escaping Callback) {
        DispatchQueue.global(qos: .background).async {
            self.send(order: nil, orderXML: orderXML, callback: callback, attempts: 0)
        }
    }
    
    
    private func send(order: AlleeOrder?, orderXML: String?, callback: @escaping Callback, attempts: Int) {
        guard let request = self.makeRequest(order: order, orderXML: orderXML, callback: callback) else { return }
        
        BSocketHelper.shared.send(msg: request.json, toDeviceSerial: request.deviceSerial) { (error) in
            if let error = error {
                if attempts > self.maxAttempts {
                    DispatchQueue.main.async {
                        callback(error)
                    }
                    
                } else {
                    sleep(1)
                    self.send(order: order, orderXML: orderXML, callback: callback, attempts: attempts + 1)
                }
            }
        }
        
        DispatchQueue.global(qos: .background).async {
            sleep(self.getDataTimeout)
            
            guard let currenSendIndex = self.currentSend.index(where: { (c2) -> Bool in
                return c2.guid == request.guid
                
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
    
    
    private func makeRequest(order: AlleeOrder?, orderXML: String?,
                             callback: @escaping Callback) -> (guid: String, deviceSerial: String, json: String)? {
        
        let currentGuid = UUID().uuidString
        guard let device = self.getTargetDevice() else {
            DispatchQueue.main.async {
                callback("No Allees available")
            }
            return nil
        }
        
        guard let toDevice = device.serial else {
            DispatchQueue.main.async {
                callback("Invalid serial")
            }
            return nil
        }
        
        guard let request = SocketSendOrder(guid: currentGuid, storeKey: self.storeKey ?? "",
                                            order: order, orderXML: orderXML,
                                            deviceSerial: self.deviceSerial).toJson()?.toAES() else {
                                                
                                                DispatchQueue.main.async {
                                                    callback("Failed to create request")
                                                }
                                                return nil
        }
        
        self.currentSend.append(CurrentSend(guid: currentGuid, deviceSerial: toDevice, callback: callback))
        
        return (currentGuid, toDevice, request)
    }
    
    
    public func received(message: String) {
        let socketMessage = BaseSocketMessage.fromBase(json: message.fromAES() ?? "")
        if let type = socketMessage?.type {
            
            switch type {
            case TypeSocketMessage.callback:
                guard let socketCallback = SocketCallback.from(json:  message.fromAES() ?? "") else {
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
        self.storeKey = storeKey
        BroadcastDiscovery.shared.update(storeKey: storeKey)
    }
    
    
    public func update(port: Int) throws {
        try BSocketHelper.shared.update(port: port)
    }
    
    
    @objc public enum Environment: Int {
        case prod, stage, dev
    }
}
