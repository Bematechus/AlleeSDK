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
    private var lastTargetDevice: String?
    
    public var ordersBumpStatusDelegate: OrdersBumpStatusDelegate?
    
    @objc open func start(withStoreKey storeKey: String, andPort port: Int=1111, env:Environment=Environment.prod) {
        self.storeKey = storeKey
        
        BSocketHelper.shared.start(onPort: port,
                                   withDeviceSerial: self.deviceSerial,
                                   andDeviceHostOrder: nil,
                                   andStoreKey: storeKey,
                                   andDBVersion: nil,
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
        
        BSocketHelper.shared.send(msg: request.json, toDeviceSerial: request.deviceSerial, crypt: true) { (error) in
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
            
            guard let currenSendIndex = self.currentSend.firstIndex(where: { (c2) -> Bool in
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
        
        guard let toDeviceSerial = device.serial else {
            DispatchQueue.main.async {
                callback("Invalid serial")
            }
            return nil
        }
        
        guard let request = SocketSendOrder(guid: currentGuid, storeKey: self.storeKey ?? "", deviceKey: "",
                                            order: order, orderXML: orderXML,
                                            deviceSerial: self.deviceSerial).toJson() else {
                                                
            DispatchQueue.main.async {
                callback("Failed to create request")
            }
            
            return nil
        }
        
        self.currentSend.append(CurrentSend(guid: currentGuid, deviceSerial: toDeviceSerial, callback: callback))
        
        return (currentGuid, toDeviceSerial, request)
    }
    
    
    public func received(message: String) {
        let socketMessage = BaseSocketMessage.fromBase(json: message)
        if let type = socketMessage?.type {
            
            switch type {
            case TypeSocketMessage.callback:
                self.workOnCallback(message: message)
                
            case TypeSocketMessage.notifyBump:
                self.workOnNotifyBump(message: message)
                
            case TypeSocketMessage.ordersBumpResponse:
                self.workOnOrderStatusResponse(message: message)
                
            default: break
            }
        }
    }
    
    
    private func workOnCallback(message: String) {
        guard let socketCallback = SocketCallback.from(json:  message) else {
            return
        }
        
        guard let currenSendIndex = self.currentSend.firstIndex(where: { (c2) -> Bool in
            return c2.guid == socketCallback.guid
            
        }) else {
            return
        }
        
        let currentSend = self.currentSend.remove(at: currenSendIndex)
        
        DispatchQueue.main.async {
            currentSend.callback(socketCallback.error)
        }
    }
    
    
    private func workOnNotifyBump(message: String) {
        if self.ordersBumpStatusDelegate == nil {
            return
        }
        
        guard let notify = SocketNotifyBump.from(json:  message),
            let toDeviceSerial = self.getTargetDevice()?.serial else { return }
        
        self.requestOrdersStatus(guid: notify.guid, toDeviceSerial: toDeviceSerial)
    }
    
    
    private func workOnOrderStatusResponse(message: String) {
        guard let response = SocketOrdersBumpResponse.from(json:  message) else {
            return
        }
        
        guard let ordersStatus = response.ordersBumpStatus, let lastUpdateTime = response.lastUpdateTime else { return }
        
        self.save(lastUpdateTimeForOrdersStatus: lastUpdateTime)
        
        self.ordersBumpStatusDelegate?.updated(ordersBumpStatus: ordersStatus)
    }
    
    
    public func requestOrdersStatus(callback: @escaping Callback) {
        guard let device = self.getTargetDevice() else {
            callback("No Allees available")
            return
        }
        
        guard let toDeviceSerial = device.serial else {
            callback("Invalid serial")
            return
        }
        
        self.requestOrdersStatus(guid: UUID().uuidString, toDeviceSerial: toDeviceSerial)
    }
    
    
    private func requestOrdersStatus(guid: String, toDeviceSerial: String) {
        let request = SocketOrdersBumpRequest(guid: guid, storeKey: self.storeKey ?? "", deviceKey: "",
                                              lastUpdateTime: self.lastUpdateTimeForOrdersStatus(), deviceSerial: self.deviceSerial)
        
        guard let requestJson = request.toJson() else { return }
        
        BSocketHelper.shared.send(msg: requestJson, toDeviceSerial: toDeviceSerial, deviceTypes: [.kds], crypt: true)
    }
    
    
    private func getTargetDevice() -> BroadcastDevice? {
        return BroadcastDiscovery.shared.allLanDevices().min { (d1, d2) -> Bool in
            return d1.hostOrder ?? 999 < d2.hostOrder ?? 999
        }
    }
    
    
    public func update(storeKey: String) {
        self.storeKey = storeKey
        BroadcastDiscovery.shared.update(storeKey: storeKey)
    }
    
    
    public func update(port: Int) throws {
        try BSocketHelper.shared.update(port: port)
    }
    
    
    private func save(lastUpdateTimeForOrdersStatus: Double) {
        if lastUpdateTimeForOrdersStatus > 0 {
            UserDefaults.standard.set(lastUpdateTimeForOrdersStatus, forKey: "lastUpdateTimeForOrdersStatus")
        }
    }
    
    
    private func lastUpdateTimeForOrdersStatus() -> Double? {
        return UserDefaults.standard.double(forKey: "lastUpdateTimeForOrdersStatus")
    }
    
    public func updated(devices: [BroadcastDevice]) {
        let targetDevice = self.getTargetDevice()
        
        if self.lastTargetDevice == targetDevice?.serial {
            return
        }
        
        self.lastTargetDevice = targetDevice?.serial
        
        self.requestOrdersStatus { (error) in
            if let error = error {
                print("Failed on get orders status: \(error)")
            }
        }
    }
    
    
    @objc public enum Environment: Int {
        case prod, stage, dev
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
}
