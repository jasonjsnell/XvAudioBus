//
//  XvAudioBusConstants.swift
//  XvAudioBus
//
//  Created by Jason Snell on 3/8/17.
//  Copyright © 2017 Jason J. Snell. All rights reserved.
//

import Foundation

public class XvAudioBusConstants {
    
    //midi constants
    public static let MIDI_OMNI:String = "Omni"
    public static let MIDI_NOTE_ON_PREFIX:String = "9"
    public static let MIDI_NOTE_OFF_PREFIX:String = "8"
    public static let MIDI_NOTE_ON:UInt8 = 144
    public static let MIDI_NOTE_OFF:UInt8 = 128
    
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
    public static let kXvAudioBusMidiFilterNoteOn:String = "kXvAudioBusMidiFilterNoteOn"
    public static let kXvAudioBusMidiFilterNoteOff:String = "kXvAudioBusMidiFilterNoteOff"
    //public static let kXvAudioBusMidiPacketListReceived:String = "kXvAudioBusMidiPacketListReceived"
    
    
    
    public static let kXvAudioBusFadeOutComplete:String = "kXvAudioBusFadeOutComplete"
}
