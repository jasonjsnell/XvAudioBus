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
    
    class func getAudiobusDescription(withSubtype: String) -> AudioComponentDescription? {
        
        if (withSubtype.characters.count == 4){
            
            let kSubType:OSType = fourCharCodeFrom(string: withSubtype)
            let kAudioUnitManufacturer_JasonJSnell:OSType = fourCharCodeFrom(string: "jjsn")
            
            return AudioComponentDescription(
                componentType: kAudioUnitType_RemoteGenerator,
                componentSubType: kSubType,
                componentManufacturer: kAudioUnitManufacturer_JasonJSnell,
                componentFlags: 0,
                componentFlagsMask: 0)
            
        } else {
            
            print("AUDIOBUS UTILS: Error: Incoming subtype string is not the required 4 characters long")
            return nil
        }
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
