//
//  AudioBusManager.swift
//  Refraktions
//
//  Created by Jason Snell on 2/26/17.
//  Copyright © 2017 Jason J. Snell. All rights reserved.
//

import Foundation

public class XvAudioBus {
    
    //MARK: VARS -

    fileprivate var _audiobusController:ABAudiobusController? = nil
    fileprivate var remoteIoUnit:AudioUnit? = nil
    fileprivate var _midiSendPort:ABMIDISenderPort?
    
    
    fileprivate let debug:Bool = true
    
    //singleton code
    public static let sharedInstance = XvAudioBus()
    fileprivate init() {}
    
    
    //MARK: - PUBLIC API - 
    //MARK: SETUP
    
    public func setup(withAppKey:String) {
        
        //only init once
        //audio bus setup occurs right after audio system init
        
        if (_audiobusController == nil){
            
            if (debug) { print("AUDIOBUS: Init") }
            
            _audiobusController = ABAudiobusController(apiKey: withAppKey)
            print("_audiobusController", _audiobusController!)
            
            //location of notifcation panel
            _audiobusController?.connectionPanelPosition = ABConnectionPanelPositionRight
            
        }
    }
    
    public func addAudioPort(name:String, title:String, subtype:String, remoteIoUnit:AudioUnit) {
        
        self.remoteIoUnit = remoteIoUnit
        
        if let desc:AudioComponentDescription = Utils.getAudiobusDescription(withSubtype: subtype) {
            
            //main sender port, out the remoteIO
            if let audioPort:ABAudioSenderPort = ABAudioSenderPort(
                name: name,
                title: title,
                audioComponentDescription: desc,
                audioUnit: remoteIoUnit
                )
                
            {
                
                if (_audiobusController != nil){
                    
                    //then add sender port to controller
                    _audiobusController!.addAudioSenderPort(audioPort)
                    
                    if (debug) {
                        print("AUDIOBUS: Audio send port", audioPort)
                    }
                    
                    //not currently used
                    startObservingConnections()
                    
                } else {
                    print("AUDIOBUS: Error: _audiobusController is nil during addAudioPort")
                }
                
            } else {
                print("AUDIOBUS: Unable to init audio port with name", name)
            }
            
        } else {
            
            print("AUDIOBUS: Error creating Audio Component Description during addAudioPort")
        }
        
        
    }
    
    
    public func initMidiSendPort(name:String, title:String){
        
        _midiSendPort = ABMIDISenderPort(name: name, title: title)
        
        if (_audiobusController != nil){
            
            _audiobusController!.addMIDISenderPort(_midiSendPort)
            
            //mandatory
            //I'm using my bypass variable on ABConnected / ABDisconnected instead
            _audiobusController?.enableSendingCoreMIDIBlock = {
                (sendingEnabled: Bool) -> Void in
                
                if (sendingEnabled){
                    print("AUDIOBUS: Sending is now enabled")
                
                } else {
                    print("AUDIOBUS: Sending is now disabled")
                }
            }
            
        } else {
            print("AUDIOBUS: Error: _audiobusController is nil during addMidiPort")
        }
        
    }
    
    //MARK: UTILS
    
    public func midiSend(packetList: UnsafeMutablePointer<MIDIPacketList>){
        
        if (_midiSendPort != nil){
            
            ABMIDIPortSendPacketList(_midiSendPort!, packetList)
            
        } else {
            
            print("AUDIOBUS: Error: midiSendPort is nil during midiSend")
        }
    }
    
    //called by helper when shuttind down system
    public func fadeOut(remoteIoUnit:AudioUnit){
        
        
         ABAudioUnitFader.fadeOutAudioUnit(remoteIoUnit, completionBlock: {
            
            if (self.debug){ print("AUDIOBUS: Remote IO unit fadeout complete") }
            
            Utils.postNotification(
                name: XvAudioBusConstants.kXvAudioBusFadeOutComplete,
                userInfo: nil)
         })
    }
    
    //MARK: ACCESSORS
    
    //called by delegate
    public func isAudioBusConnected() -> Bool {
        if ((getAudioBusController()) != nil){
            return _audiobusController!.connected && _audiobusController!.memberOfActiveAudiobusSession
        } else {
            return false
        }
    }
    
    //MARK: - PRIVATE API -
    //MARK: LISTENERS
    private func startObservingConnections() {
        
        //detects when audiobus starts or stops a connection
        //use this to notifiy the midi system to turn on / off its bypass
        
        let _ = NotificationCenter.default.addObserver(
            forName: NSNotification.Name.ABConnected,
            object: nil,
            queue: nil,
            using: { _ in
                
                if (self.debug){ print("AUDIOBUS: Connected") }
                
                Utils.postNotification(
                    name: XvAudioBusConstants.kXvAudioBusConnected,
                    userInfo: nil
                )
        })
        
        let _ = NotificationCenter.default.addObserver(
            forName: NSNotification.Name.ABDisconnected,
            object: nil,
            queue: nil,
            using: { _ in
                
                if (self.debug){ print("AUDIOBUS: Disconnected") }
                
                Utils.postNotification(
                    name: XvAudioBusConstants.kXvAudioBusDisconnected,
                    userInfo: nil
                )
        })
    }
    
    private func stopObservingConnections() {
        
        NotificationCenter.default.removeObserver(
            self,
            name: NSNotification.Name.ABConnected,
            object: nil
        )
        
        NotificationCenter.default.removeObserver(
            self,
            name: NSNotification.Name.ABDisconnected,
            object: nil
        )
        
    }
    
    
    
    //MARK: UTILS
    
    
    fileprivate func getAudioBusController() -> ABAudiobusController? {
        return _audiobusController
    }
    
    //not used currently
    fileprivate func isConnectedToInterAppAudio() -> Bool {
        
        //var isConnectedToIAA:Bool = false
        //var isConnectedToIAASize:UInt32 = UInt32(MemoryLayout.size(ofValue: isConnectedToIAA))
        
        /*
         TODO: move to audiobus wrapper and pass in instance
        if let remoteIoUnit:AudioUnit = XvAudioSystem.sharedInstance.getRemoteIOAudioUnit() {
            
            let result:OSStatus = AudioUnitGetProperty(
                remoteIoUnit,
                kAudioUnitProperty_IsInterAppConnected,
                kAudioUnitScope_Global,
                0,
                &isConnectedToIAA,
                &isConnectedToIAASize
            )
            
            guard result == noErr else {
                AudioUtils.print("AUDIO ENGINE: Error getting unit format", result)
                return false
            }
            
            return isConnectedToIAA
            
        } else {
            return false
        }
 
        */
        
        return false 
        
    }
    
    deinit {
        stopObservingConnections()
        _audiobusController = nil
        _midiSendPort = nil
    }
    
}
