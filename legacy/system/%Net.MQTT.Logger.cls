/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This is the base class for instances of %Net.MQTT.Logger. Users wishing to perform their own
/// custom logging should subclass this class, and attach an instance of that class to the Logger
/// property an instance of %Net.MQTT.Tracer
Class %Net.MQTT.Logger Extends %RegisteredObject [ Abstract ]
{

/// Override this method to perform your custom logging. This method must complete
/// quickly else performance of the library will be negatively affected.
Method Log(level As %Integer, message As %String)
{
	// Subclass Responsibility
}

}
