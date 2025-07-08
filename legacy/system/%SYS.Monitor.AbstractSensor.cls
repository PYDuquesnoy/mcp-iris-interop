/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %syMonitor

/// Abstract class for a Sensor<p>
/// User classes inherit from this class to become a Sensor for System Monitor.
Class %SYS.Monitor.AbstractSensor Extends %RegisteredObject [ Abstract, System = 3 ]
{

/// logfile
Property Logfile As %String [ InitialExpression = {$zu(12)_"SystemMonitor.log"}, Internal ];

/// Array of sensor name / value pairs
Property SensorReading [ Internal, MultiDimensional ];

/// Array of sensor name / high water mark value pairs [deprecated]
Property SensorMaxValue [ Deprecated, Internal, MultiDimensional ];

/// Runtime state
Property State As %String [ InitialExpression = " " ];

Property Notifications [ MultiDimensional ];

/// USER MAY IMPLEMENT THIS METHOD<p>
/// The System Monitor Controller calls this method once when it starts.
/// The user may initialize the properties, counters, etc.<p>
/// A return code of $$$OK indicates there were no errors.
/// A return code of 0 indicates a failure.
Method Start() As %Status
{
	Q $$$OK
}

/// USER MUST IMPLEMENT THIS METHOD<p>
/// The System Monitor Controller calls this method to get sensor readings. It is called every 10 seconds by default.<p>
/// Users may return readings for multiple sensors (but only one reading per sensor on each call).
/// User calls SetSensor(sensorname, value[,type]) for every sensor reading. The sensors are kept in the property SensorReading(sensor)=value,
/// and SensorType(sensor)=type.
/// The controller picks up the sensors and their values after the return from GetSensors().<p>
/// A return code of $$$OK indicates there were no errors.
/// A return code of 0 indicates a failure.
Method GetSensors() As %Status [ Abstract ]
{
	Quit $$$OK
}

/// USER DOES NOT IMPLEMENT THIS METHOD
/// The user must call this method to set a sensor reading. Readings are picked up by the controller after GetSensors() returns.<p>
Method SetSensor(Sensor As %String, Value As %String, Qualifier As %String = "") As %Integer
{
	s $zt="SetErr"
	i Qualifier="" {
		s ..SensorReading(Sensor) = Value
	} else {
		s ..SensorReading(Sensor,Qualifier) = Value
	}
	Q $$$OK
SetErr
	Q 0
}

/// USER DOES NOT IMPLEMENT THIS METHOD
/// The controller calls this to initialize the SensorReadings array.
Method ClearSensors() As %Integer [ Final ]
{
	k ..SensorReading
	Q $$$OK
}

/// USER DOES NOT IMPLEMENT THIS METHOD
/// This method is called to clear notifications for the SYS.Monitor Controller
Method ClearNotifications() As %Integer [ Final ]
{
	k ..Notifications
	Q $$$OK
}

/// USER DOES NOT IMPLEMENT THIS METHOD
/// This method is called to post a notification
Method Notify(Sensor As %String, Severity As %Integer, Msg As %String) As %Integer [ Final ]
{
	s ..Notifications(Sensor,$$$NOTIFYSEV) = Severity
	s ..Notifications(Sensor,$$$NOTIFYMSG) = Msg
	Q $$$OK
}

/// USER DOES NOT IMPLEMENT THIS METHOD<p>
Method OpenLog() As %Status [ Final ]
{
	s $zt="OpenLogErr"
	s filesize=$zu(140,1,..Logfile)
	i filesize>2097152 {
		s oldlog=..Logfile_".old"
		#; delete the old log if exists
		o oldlog:"AW":0
		c oldlog:"D"
		#; rename the current log to oldlog
		o ..Logfile:"AW":0
		c ..Logfile:("R":oldlog)
	}
	o ..Logfile:"AW":0
	q $$$OK
OpenLogErr
	;ignore errors.  If can't log, nothing we can do
	s $zt=""
	c ..Logfile
	q 0
}

/// USER DOES NOT IMPLEMENT THIS METHOD<p>
/// User may call this method to log information to the SystemMonitor.log file in the mgr directory.
Method LogMsg(msg As %String = "") As %Status [ Final ]
{
	s $zt="LogMsgErr"
	d ..OpenLog()

	s dt = $H
	s time = $ZDate(dt,1,,2)_"-"_$ZTime($p(dt,",",2))
	U ..Logfile w time," ",msg,!
	c ..Logfile
	q $$$OK
LogMsgErr
	;ignore errors.  If can't log, nothing we can do
	s $zt=""
	c ..Logfile
	q 0
}

/// USER DOES NOT IMPLEMENT THIS METHOD<p>
/// User may call this method to post alerts directly to the messages.log file.
Method LogCon(Msg As %String = "", Severity As %Integer = 0) As %Status [ Final ]
{
	s Msg = "[SYSTEM MONITOR] "_Msg
	d $zu(9,"",Msg,0,Severity)
	d ..LogMsg(Msg)
	q $$$OK
}

}
