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

    fileprivate var audiobusController:ABAudiobusController? = nil
    fileprivate var remoteIoUnit:AudioUnit? = nil
    
    
    
    fileprivate let debug:Bool = false
    
    //singleton code
    public static let sharedInstance = XvAudioBus()
    fileprivate init() {}
    
    
    //MARK: - PUBLIC API - 
    
    public func setup(withAppKey:String) {
        
        //only init once
        //audio bus setup occurs right after audio system init
        
        if (audiobusController == nil){
            
            if (debug) { print("AUDIOBUS: Init") }
            
            audiobusController = ABAudiobusController(apiKey: withAppKey)
            
            //location of notifcation panel
            audiobusController?.connectionPanelPosition = ABConnectionPanelPositionRight
            
        }
        
    }
    
    public func addPort(name:String, title:String, remoteIoUnit:AudioUnit) {
        
        self.remoteIoUnit = remoteIoUnit
        
        //main sender port, out the remoteIO
        if let audioBusMainPort:ABSenderPort = ABSenderPort(
            name: name,
            title: title,
            audioComponentDescription: Utils.getAudiobusDescription(),
            audioUnit: remoteIoUnit
            )
            
        {
            
            //then add sender port to controller
            audiobusController!.addSenderPort(audioBusMainPort)
            
            if (debug) {
                print("AUDIOBUS: Send port", audioBusMainPort)
            }
            
            //not currently used
            startObservingConnections()
            
        }
        

    }

    //called by delegate
    public func isAudioBusConnected() -> Bool {
        if ((getAudioBusController()) != nil){
            return audiobusController!.connected && audiobusController!.memberOfActiveAudiobusSession
        } else {
            return false
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
    
    //MARK: - PRIVATE API -
    //MARK: LISTENERS
    private func startObservingConnections() {
        
        //has both IAA and Audiobus change notifications
        //https://github.com/audiokit/AudioKit/blob/master/AudioKit/iOS/Audiobus/Audiobus.swift
        
        let _ = NotificationCenter.default.addObserver(forName: NSNotification.Name.ABConnectionsChanged, object: nil, queue: nil, using: { _ in
            
            if (self.debug){
                print("AUDIOBUS: ABConnectionsChanged")
            }
            
        })
        
    }
    
    private func stopObservingConnections() {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.ABConnectionsChanged, object: nil)
    }
    
    
    
    //MARK: UTILS
    
    
    fileprivate func getAudioBusController() -> ABAudiobusController? {
        return audiobusController
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
        audiobusController = nil
    }
    
}
