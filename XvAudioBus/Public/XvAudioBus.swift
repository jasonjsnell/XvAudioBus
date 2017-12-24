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

    //controller
    fileprivate var _audiobusController:ABAudiobusController? = nil
    
    //ports
    fileprivate var _audioSendPort:ABAudioSenderPort?
    fileprivate var _midiSendPorts:[ABMIDISenderPort] = []
    fileprivate var _midiFilterPorts:[ABMIDIFilterPort] = []
    
    fileprivate var _playToggleTrigger:ABTrigger?
    
    fileprivate var _midiSendPortEnabled:Bool = false
    public var midiSendPortEnabled:Bool {
        get { return _midiSendPortEnabled }
        set {
            _midiSendPortEnabled = newValue
            
            //send port overrides filter port, deactivating it
            if (_midiSendPortEnabled) {
                midiFilterPortEnabled = false
            }
            
        }
    }
    
    fileprivate var _midiFilterPortEnabled:Bool = false
    public var midiFilterPortEnabled:Bool {
        get { return _midiFilterPortEnabled }
        set { _midiFilterPortEnabled = newValue }
    }
    
    
    fileprivate let debug:Bool = false
    
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
            
            _audioSendPort = nil
            
            //main sender port, out the remoteIO
            _audioSendPort = ABAudioSenderPort(
                name: name,
                title: title,
                audioComponentDescription: desc,
                audioUnit: remoteIoUnit
                )
            
                if (_audiobusController != nil){
                    
                    //then add sender port to controller
                    _audiobusController!.addAudioSenderPort(_audioSendPort)
                    
                    if (debug) {
                        print("AUDIOBUS: Audio send port", _audioSendPort as Any)
                    }
                    
                    //not currently used
                    _startObservingConnections()
                    
                } else {
                    print("AUDIOBUS: Error: _audiobusController is nil during addAudioPort")
                }
                
            
            
        } else {
            
            print("AUDIOBUS: Error creating Audio Component Description during addAudioPort")
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
    
    //MARK: - MIDI -
    //MARK: Add ports
    
    //ABMIDIPortSendPacketList(_MIDISenderPort, packetList);
    
    //called by app delegate app launch > AB helper
    public func addMidiSendPort(name:String, title:String) -> Bool{
        
        if (_audiobusController != nil){
            
            if let midiSendPort:ABMIDISenderPort = ABMIDISenderPort(name: name, title: title) {
                
                if (debug) { print("AUDIOBUS: Add", name, " | ", title) }
                _midiSendPorts.append(midiSendPort)
                _audiobusController!.addMIDISenderPort(midiSendPort)
                return true
                
            } else {
                
                print("AUDIOBUS: Unable to create ABMIDISenderPort during addMidiSendPort")
                return false
            }
            
        } else {
            print("AUDIOBUS: Error: _audiobusController is nil during initMidiSendPort")
            return false
        }
        
    }
    
   
    public func addMidiFilterPort(name:String, title:String) -> Bool{
        
        if (_audiobusController != nil){
            
            if let midiFilterPort:ABMIDIFilterPort = ABMIDIFilterPort(
                name: name,
                title: title,
                receiverBlock: {
                    (receiverPort:ABPort,
                    packetList: UnsafePointer<MIDIPacketList>) in
                    
                    //pass to func to process filter port packetlists
                    self.filterPortReceive(name: name, filterPort: receiverPort, packetList: packetList)
                    
            }) {
                
                if (debug) { print("AUDIOBUS: Add", name, " | ", title) }
                _midiFilterPorts.append(midiFilterPort)
                _audiobusController!.addMIDIFilterPort(midiFilterPort)
                return true
                
            } else {
                
                print("AUDIOBUS: Unable to create ABMIDIFilterPort during addMidiFilterPort")
                return false
            }

            
        } else {
            
            print("AUDIOBUS: Error: _audiobusController is nil during initMidiFilterPort")
            return false
        }
        
    }
    
    //MARK: Port accessors
    
    public func getAllMidiSendPorts() -> [ABMIDIPort] {
        
        return _midiSendPorts
    }
    
    public func getMIDISendPorts(forChannel:UInt8) -> [ABMIDIPort]? {
        
        //confirm channel is within range of audiobus channels
        //(need to block commands from midi channels numbered higher than the number of AB midi ports)
        
        let channel:Int = Int(forChannel)
        if (channel < _midiSendPorts.count-1) {
            
            //returns an array because it always includes port 0, the omni port
            var midiPorts:[ABMIDIPort] = [_midiSendPorts[0]]
            
            //and add on the port corresponding to the track (1-8 in RF)
            midiPorts.append(_midiSendPorts[(channel + 1)])
            
            return midiPorts
            
        } else {
            
             print("AUDIOBUS: Error: Incoming channel is beyond the range of the midiSendPorts array during getMIDISendPorts")
            return nil
        }
        
        
    }
    
    public func getMIDIFilterPort(forChannel:UInt8) -> ABMIDIPort? {
        
        let channel:Int = Int(forChannel)
        
        //check to see if port exists in array
        if (channel < _midiFilterPorts.count){
            
            //if so, return port
            return _midiFilterPorts[channel]
            
        } else {
            
            print("AUDIOBUS: Error: Incoming channel is beyond the range of the midiFilterPorts array during getMIDIFilterPort")
            
            return nil
        }
        
    }
    
    //MARK: Port send
    //called by midi system > midi helper > audiobus (MIDI send port)
    
    public func midiSend(packetList: UnsafeMutablePointer<MIDIPacketList>, toPorts:[ABMIDIPort]){
        
        for port:ABMIDIPort in toPorts {
            
            if (debug){
                print("AUDIOBUS: Send midi packet to", port.name)
            }
            
            ABMIDIPortSendPacketList(port, packetList)
        }
    }
    
    //MARK: Filter port
    fileprivate func filterPortReceive(name:String, filterPort:ABPort, packetList: UnsafePointer<MIDIPacketList>) {
        
        if self.debug { print("AUDIOBUS: Filter port", filterPort.name) }
        
        //grab last character in string (example "JasonJSnell: Refraktions: MIDI Filter 3")
        let lastDigit:String = String(name.suffix(1))
        
        //this digit is the port number
        if let portNum:UInt8 = UInt8(lastDigit) {
            
            //convert port number to a midi channel (substract 1)
            let midiChannel:UInt8 = portNum-1
            
            //repackage the MIDI packet so the MIDI channel reflects the port, rathern than the default of channel 0
            let repackagedPacketList = Utils.repackage(
                packetList: packetList,
                withChannel: midiChannel
            )
            
            //send out the incoming note immediately, like a MIDI thru
            
            if let midiPort:ABMIDIPort = filterPort as? ABMIDIPort {
                
                self.midiSend(packetList: repackagedPacketList, toPorts: [midiPort])
                
            } else {
                
                print("AUDIOBUS: Error converting filter port into midi port during filterPortReceive")
            }
            
            //get note data from packet list
            
            if let noteData:[UInt8] = Utils.getNoteData(fromPacketList: repackagedPacketList) {
                
                let status:UInt8 = noteData[0]
                let rawStatus:UInt8 = status & 0xF0 // without channel
                let note:UInt8 = noteData[1]
                let velocity:UInt8 = noteData[2]
                
                //post notications based on whether it is note on or note off
                //if status is note on
                if (rawStatus == XvAudioBusConstants.MIDI_NOTE_ON) {
                    
                    //if volume is above zero
                    if (velocity > 0) {
                        
                        Utils.postNotification(
                            name: XvAudioBusConstants.kXvAudioBusMidiFilterNoteOn,
                            userInfo: [
                                "channel" : midiChannel,
                                "note" : note,
                                "velocity" : velocity
                            ]
                        )
                        
                    } else {
                        
                        //else volume is zero, note off
        
                        Utils.postNotification(
                            name: XvAudioBusConstants.kXvAudioBusMidiFilterNoteOff,
                            userInfo: [
                                "channel" : midiChannel,
                                "note" : note
                            ]
                        )
                    }
                    
                } else if (rawStatus == XvAudioBusConstants.MIDI_NOTE_OFF){
                    
                    //else status is note off
                    Utils.postNotification(
                        name: XvAudioBusConstants.kXvAudioBusMidiFilterNoteOff,
                        userInfo: [
                            "channel" : midiChannel,
                            "note" : note
                        ]
                    )
                }
                
                
            } else {
                
                print("AUDIOBUS: Error getting noteData UInt8 array from packetList during filterPortReceive")
            }
            
        } else {
            print("AUDIOBUS: Error: Unable to convert port name into port number during filterPortReceive")
        }
        
    }
    
    
    
    //MARK: - SHUTDOWN
    //called by helper when shuttind down system
    public func fadeOut(remoteIoUnit:AudioUnit){
        
         ABAudioUnitFader.fadeOutAudioUnit(remoteIoUnit, completionBlock: {
            
            if (self.debug){ print("AUDIOBUS: Remote IO unit fadeout complete") }
            
            Utils.postNotification(
                name: XvAudioBusConstants.kXvAudioBusFadeOutComplete,
                userInfo: nil)
         })
    }
    
    //MARK: - ACCESSORS
    
    //called by delegate
    public func isAudioBusConnected() -> Bool {
        if ((getAudioBusController()) != nil){
            return _audiobusController!.connected && _audiobusController!.memberOfActiveAudiobusSession
        } else {
            return false
        }
    }
    
    //MARK: - REFRESH STATE
    
    internal func startRefreshStateDelayTimer(){
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1.0) {

            self.refreshState()
        }
    }
    
    internal func refreshState(){
        
        //set filter first, since sender overrides it
        //loop through filter ports, true if any are connected
        midiFilterPortEnabled = false
        
        for midiFilterPort in _midiFilterPorts {
            
            if (midiFilterPort.connected){
                midiFilterPortEnabled = true
            }
        }
        
        //loop through send ports, true if any are connected
        midiSendPortEnabled = false
        for midiSendPort in _midiSendPorts {
            
            if (midiSendPort.connected){
                midiSendPortEnabled = true
            }
            
            
        }
        
        if (debug){
            print("AUDIOBUS: Refresh: MIDI Send", midiSendPortEnabled, "| MIDI Filter", midiFilterPortEnabled)
        }
        
        /*
        if (midiSendPortEnabled) {
            
            Utils.postNotification(
                name: XvAudioBusConstants.kXvAudioBusMidiSendPortConnected,
                userInfo: nil
            )
            
        } else if (midiFilterPortEnabled){
            
            Utils.postNotification(
                name: XvAudioBusConstants.kXvAudioBusMidiFilterPortConnected,
                userInfo: nil
            )
            
        } else {
            
            Utils.postNotification(
                name: XvAudioBusConstants.kXvAudioBusMidiPortsDisconnected,
                userInfo: nil
            )
        }
        */
        
    }
    

    //MARK: - LISTENERS
    
    public func addMidiSendListener(){
        
        //mandatory
        //I'm using my bypass variable on ABConnected / ABDisconnected instead
        _audiobusController?.enableSendingCoreMIDIBlock = {
            (sendingEnabled: Bool) -> Void in
            
            //not used
            /*
             if (sendingEnabled){
             //fires when app is removed as a MIDI Sender
             print("AUDIOBUS: AB MIDI Sending is now off")
             
             } else {
             //fires when app is selected as a Midi Sender
             print("AUDIOBUS: AB MIDI Sending is now on")
             
             }
             */
            
        }
    }
    
    public func addMidiReceiveListener(){
        
        //mandatory
        //I'm using my bypass variable on ABConnected / ABDisconnected instead
        _audiobusController?.enableReceivingCoreMIDIBlock = {
            (receivingEnabled: Bool) -> Void in
            
            if (receivingEnabled){
                //fires when app is removed as a MIDI Sender
                //fires when app is removed as a MIDI Filter
                print("AUDIOBUS: AB MIDI Receiving is now off")
                
            } else {
                //fires when app is selected as a MIDI Sender
                //fires when app is selected as a MIDI Filter
                print("AUDIOBUS: AB MIDI Receiving is now on")
            }
            
            self.startRefreshStateDelayTimer()
            
        }
        
    }
    
    fileprivate func _startObservingConnections() {
        
        //detects when audiobus starts or stops a connection
        //use this to notifiy the midi system to turn on / off its bypass
        
        let _ = NotificationCenter.default.addObserver(
            forName: NSNotification.Name.ABConnected,
            object: nil,
            queue: nil,
            using: { _ in
                
                //this fires when app is added, any port
                //this does not fire when additional ports are added
                if (self.debug){
                    print("")
                    print("AUDIOBUS: Connected")
                }
                
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
                
                //this fires when all ports are removed
                //this does not fire when when an individual port is removed, unless it is the last port
                if (self.debug){
                    print("")
                    print("AUDIOBUS: Disconnected")
                }
                
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
    
    
    
    
    
    
    
    //MARK: - UTILS
    
    
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
        _midiSendPorts = []
        _midiFilterPorts = []
    }
    
}

