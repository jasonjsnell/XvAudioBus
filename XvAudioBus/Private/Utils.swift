//
//  AudioBusUtils.swift
//  XvAudioBus
//
//  Created by Jason Snell on 3/8/17.
//  Copyright © 2017 Jason J. Snell. All rights reserved.
//

import Foundation

class Utils {
    
    //singleton code
    static let sharedInstance = Utils()
    fileprivate init() {}
    
    //MARK: NOTIFICATIONS
    class func postNotification(name:String, userInfo:[AnyHashable : Any]?){
        
        let notification:Notification.Name = Notification.Name(rawValue: name)
        NotificationCenter.default.post(
            name: notification,
            object: nil,
            userInfo: userInfo)
    }
    
    class func getAudiobusDescription() -> AudioComponentDescription {
        
        let kRefraktionsSubType_MainPort:OSType = fourCharCodeFrom(string: "rfmn")
        let kAudioUnitManufacturer_JasonJSnell:OSType = fourCharCodeFrom(string: "jjsn")
        
        return AudioComponentDescription(
            componentType: kAudioUnitType_RemoteGenerator,
            componentSubType: kRefraktionsSubType_MainPort,
            componentManufacturer: kAudioUnitManufacturer_JasonJSnell,
            componentFlags: 0,
            componentFlagsMask: 0)
        
    }
    
    //MARK: CHAR CONVERSION
    class func fourCharCodeFrom(string : String) -> FourCharCode {
        assert(string.characters.count == 4, "String length must be 4")
        var result : FourCharCode = 0
        for char in string.utf16 {
            result = (result << 8) + FourCharCode(char)
        }
        return result
    }
    
    
    
    
}
