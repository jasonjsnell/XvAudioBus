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
    
    //MARK: - NOTIFICATIONS
    class func postNotification(name:String, userInfo:[AnyHashable : Any]?){
        
        let notification:Notification.Name = Notification.Name(rawValue: name)
        NotificationCenter.default.post(
            name: notification,
            object: nil,
            userInfo: userInfo)
    }
    
    class func getAudiobusDescription(withSubtype: String) -> AudioComponentDescription? {
        
        if (withSubtype.count == 4){
            
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
    
    //MARK: - CHAR CONVERSION
    class func fourCharCodeFrom(string : String) -> FourCharCode {
        assert(string.count == 4, "String length must be 4")
        var result : FourCharCode = 0
        for char in string.utf16 {
            result = (result << 8) + FourCharCode(char)
        }
        return result
    }
    
    //MARK: - MIDI UTILS -
    
    //MARK: get note data
    class func getNoteData(fromPacketList: UnsafePointer<MIDIPacketList>) -> [UInt8]? {
        
        //set up vars
        let packetList:MIDIPacketList = fromPacketList.pointee
        let packet:MIDIPacket = packetList.packet
        
        var ap = UnsafeMutablePointer<MIDIPacket>.allocate(capacity: 1)
        ap.initialize(to: packet)
        
        //loop through packets. Sometimes a note on / off is in the same packet as timeclock
        for _ in 0 ..< packetList.numPackets {
            
            //print packet
            print("")
            
            //extract data
            let status:UInt8 = packet.data.0
            let rawStatus:UInt8 = status & 0xF0 // without channel
            let d1:UInt8 = packet.data.1
            let d2:UInt8 = packet.data.2
            
            //if status is note on or off
            if (rawStatus == XvAudioBusConstants.MIDI_NOTE_ON || rawStatus == XvAudioBusConstants.MIDI_NOTE_OFF){
                return [status, d1, d2]
            }
            
            //prep next round
            ap = MIDIPacketNext(ap)
            
        }
        
        return nil
    }
    
    //MARK: Repackage with new channel
    class func repackage(
        packetList: UnsafePointer<MIDIPacketList>,
        withChannel:UInt8) -> UnsafeMutablePointer<MIDIPacketList> {
        
        //set up vars
        let inPacketList:MIDIPacketList = packetList.pointee
        let inPacket:MIDIPacket = inPacketList.packet
        
        var outPacket:UnsafeMutablePointer<MIDIPacket> = UnsafeMutablePointer<MIDIPacket>.allocate(capacity: 1)
        let outPacketList = UnsafeMutablePointer<MIDIPacketList>.allocate(capacity: 1)
        
        var ap = UnsafeMutablePointer<MIDIPacket>.allocate(capacity: 1)
        ap.initialize(to: inPacket)
        
        //loop through packets. Sometimes a note on / off is in the same packet as timeclock
        for _ in 0 ..< inPacketList.numPackets {
            
            //extract data
            let timeStamp:MIDITimeStamp = inPacket.timeStamp
            let status:UInt8 = inPacket.data.0
            let rawStatus:UInt8 = status & 0xF0 // without channel
            let d1:UInt8 = inPacket.data.1
            let d2:UInt8 = inPacket.data.2
            
            var outData:[UInt8]
            
            //if status is note on or off
            if (rawStatus == XvAudioBusConstants.MIDI_NOTE_ON || rawStatus == XvAudioBusConstants.MIDI_NOTE_OFF){
                
                //convert it to a hex
                let midiChannelHex:String = getHexString(fromUInt8: withChannel)
                var noteByte:UInt8 = 0
                
                if (rawStatus == XvAudioBusConstants.MIDI_NOTE_ON){
                    
                    if (d2 == 0x0) {
                        
                        print("note off")
                        //some midi controllers request a note off by putting the velocity to 0
                        noteByte = getByte(fromStr: XvAudioBusConstants.MIDI_NOTE_OFF_PREFIX + midiChannelHex)
                        
                    } else {
                        print("note on")
                        //else normal note on
                        noteByte = getByte(fromStr: XvAudioBusConstants.MIDI_NOTE_ON_PREFIX + midiChannelHex)
                    }
                    
                } else if (rawStatus == XvAudioBusConstants.MIDI_NOTE_OFF){
                   
                    //note off
                    noteByte = getByte(fromStr: XvAudioBusConstants.MIDI_NOTE_OFF_PREFIX + midiChannelHex)
                    
                } else {
                    
                    //catch all
                    noteByte = status
                }
                
                //input incoming data into UInt8 array
                outData = [noteByte, d1, d2]
                
            } else {
                
                //duplicate the same data
                outData = [status, d1, d2]
            }
            
            outPacket = MIDIPacketListInit(outPacketList)
            let outLength:Int = outData.count
            let outPacketByteSize:Int = 1024
            
            //add packet data to the packet list
            outPacket = MIDIPacketListAdd(outPacketList, outPacketByteSize, outPacket, timeStamp, outLength, outData)
            
            //prep next round
            ap = MIDIPacketNext(ap)
            
        }
        
        return outPacketList
    }
    
    
    
    
    //MARK: Hex - byte conversions
    //called by internal and by MidiSend
    class func getHexString(fromUInt8:UInt8) -> String {
        return String(fromUInt8, radix: 16, uppercase: true)
    }
    
    //http://stackoverflow.com/questions/24229505/how-to-convert-an-int-to-hex-string-in-swift
    //called by MidiSend
    class func getByte(fromUInt8:UInt8) -> UInt8 {
        return getByte(fromStr: getHexString(fromUInt8: fromUInt8))
    }
    
    //called by internal and by MidiSend
    class func getByte(fromStr:String) -> UInt8 {
        
        //http://stackoverflow.com/questions/30197819/given-a-hexadecimal-string-in-swift-convert-to-hex-value
        var byteArray = [UInt8]()
        
        let charCount:Int = fromStr.count
        
        if (charCount > 1){
            var from = fromStr.startIndex
            while from != fromStr.endIndex {
                let to = fromStr.index(from, offsetBy:2, limitedBy: fromStr.endIndex)
                if (to == nil){
                    break
                } else {
                    byteArray.append(UInt8(fromStr[from ..< to!], radix: 16) ?? 0)
                    from = to!
                }
            }
        } else {
            byteArray.append(UInt8(fromStr, radix: 16) ?? 0)
        }
        
        return byteArray[0]
    }

    
    
    
}
