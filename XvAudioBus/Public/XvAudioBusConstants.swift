//
//  XvAudioBusConstants.swift
//  XvAudioBus
//
//  Created by Jason Snell on 3/8/17.
//  Copyright © 2017 Jason J. Snell. All rights reserved.
//

import Foundation

public class XvAudioBusConstants {
    
    public static let MIDI_OMNI:String = "Omni"
    
    //states
    public static let kXvAudioBusConnected:String = "kXvAudioBusConnected"
    public static let kXvAudioBusDisconnected:String = "kXvAudioBusDisconnected"
    public static let kXvAudioBusMidiSendPortConnected:String = "kXvAudioBusMidiSendPortConnected"
    public static let kXvAudioBusMidiFilterPortConnected:String = "kXvAudioBusMidiFilterPortConnected"
    public static let kXvAudioBusMidiPortsDisconnected:String = "kXvAudioBusMidiPortsDisconnected"
    
    //button events
    public static let kXvAudioBusPlayButtonPressed:String = "kXvAudioBusPlayButtonPressed"
    public static let kXvAudioBusPauseButtonPressed:String = "kXvAudioBusPauseButtonPressed"
    
    //midi events
    public static let kXvAudioBusMidiPacketListReceived:String = "kXvAudioBusMidiPacketListReceived"
    
    
    
    public static let kXvAudioBusFadeOutComplete:String = "kXvAudioBusFadeOutComplete"
}
