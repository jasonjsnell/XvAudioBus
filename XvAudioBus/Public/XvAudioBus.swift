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
    fileprivate var _midiSendPort:ABMIDISenderPort?
    fileprivate var _midiReceivePort:ABMIDIReceiverPort?
    fileprivate var _playToggleTrigger:ABTrigger?
    
    
    fileprivate let debug:Bool = true
    
    //singleton code
    public static let sharedInstance = XvAudioBus()
    fileprivate init() {}
    
    
    //MARK: - PUBLIC API - 
    //MARK: SETUP
    
    //called by app delegate app launch  > AB helper
    public func setup(withAppKey:String) {
        
        //only init once
        //audio bus setup occurs right after audio system init
        
        if (_audiobusController == nil){
            
            if (debug) { print("AUDIOBUS: Init") }
            
            _audiobusController = ABAudiobusController(apiKey: withAppKey)
            
            //location of notifcation panel
            _audiobusController?.connectionPanelPosition = ABConnectionPanelPositionRight
            
            //play / pause toggle button on AB control panel
            _playToggleTrigger = ABTrigger(systemType: ABTriggerTypePlayToggle, block: _playToggleBlock)
            _audiobusController?.add(_playToggleTrigger!)
            
        }
    }
    
    
    
    //called by app delegate app launch  > AB helper
    public func addAudioPort(name:String, title:String, subtype:String, remoteIoUnit:AudioUnit) {
        
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
                    _startObservingConnections()
                    
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
    
    //called by app delegate app launch > AB helper
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
            print("AUDIOBUS: Error: _audiobusController is nil during initMidiSendPort")
        }
        
    }
    
    public func initMidiReceivePort(name:String, title:String){
        
        _midiReceivePort = ABMIDIReceiverPort(
            name: name,
            title: title,
            receiverBlock: {
                (receiverPort:ABPort,
                packetList: UnsafePointer<MIDIPacketList>) in
                
                Utils.postNotification(
                    name: XvAudioBusConstants.kXvAudioBusMidiPacketListReceived,
                    userInfo: ["packetList" : packetList]
                )
                
        })
        
        if (_audiobusController != nil){
            
            _audiobusController!.addMIDIReceiverPort(_midiReceivePort)
            
            //mandatory
            //I'm using my bypass variable on ABConnected / ABDisconnected instead
            _audiobusController?.enableReceivingCoreMIDIBlock = {
                (receivingEnabled: Bool) -> Void in
                
                if (receivingEnabled){
                    print("AUDIOBUS: Receiving is now enabled")
                    
                } else {
                    print("AUDIOBUS: Receiving is now disabled")
                }
            }
            
        } else {
            print("AUDIOBUS: Error: _audiobusController is nil during initMidiReceivePort")
        }
        
    }
    
    //MARK: UI UPDATES
    public func updatePlaybackTriggerStateToNormal(){
        
        if (_playToggleTrigger != nil){
            
            _playToggleTrigger!.state = ABTriggerStateNormal
            
        } else {
            print("AUDIOBUS: Error: _playToggleTrigger is nil during updatePlaybackTriggerStateToNormal")
        }
    }
    
    public func updatePlaybackTriggerStateToSelected(){
        
        if (_playToggleTrigger != nil){
            
            _playToggleTrigger!.state = ABTriggerStateSelected
            
        } else {
            print("AUDIOBUS: Error: _playToggleTrigger is nil during updatePlaybackTriggerStateToSelected")
        }
    }
    
    //MARK: MIDI
    //called by midi system > midi helper > audiobus
    public func midiSend(packetList: UnsafeMutablePointer<MIDIPacketList>){
        
        if (_midiSendPort != nil){
        
            ABMIDIPortSendPacketList(_midiSendPort!, packetList)
            
        } else {
            
            print("AUDIOBUS: Error: midiSendPort is nil during midiSend")
        }
    }
    
    //MARK: SHUTDOWN
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
    fileprivate func _startObservingConnections() {
        
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
    
    fileprivate func _stopObservingConnections() {
        
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
         TODO: Future: move to audiobus wrapper and pass in instance
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
    
    fileprivate func _playToggleBlock(trigger:Optional<ABTrigger>, ports:Optional<Set<AnyHashable>>) -> () {
        
        //is trigger valid
        if (trigger != nil){
            
            //if state is normal (paused, showing a play button)
            if (trigger!.state == ABTriggerStateNormal) {
                
                //then change back to normal
                trigger!.state = ABTriggerStateSelected
                
                Utils.postNotification(
                    name: XvAudioBusConstants.kXvAudioBusPlayButtonPressed,
                    userInfo: nil
                )
                
            } else if (trigger!.state == ABTriggerStateSelected){
                
                //else if state is selected (playing, showing a pause button)
                //then change back to normal
                
                trigger!.state = ABTriggerStateNormal
                
                Utils.postNotification(
                    name: XvAudioBusConstants.kXvAudioBusPauseButtonPressed,
                    userInfo: nil
                )
                
            } else {
                
                print("AUDIOBUS: Error: trigger state is unknown")
            }
            
        } else {
            print("AUDIOBUS: Error, trigger is nil on playToggleBlock")
        }
        
        
    }
    
    deinit {
        _stopObservingConnections()
        _audiobusController = nil
        _midiSendPort = nil
    }
    
}
